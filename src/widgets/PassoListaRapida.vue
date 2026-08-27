<script setup>
import { ref } from 'vue'
import { LOCAIS, OCASIOES, rotuloLocal, formatarHorario } from './locais.js'

const props = defineProps({
  api: { type: Object, required: true },
  recordatorioId: { type: [Number, String], required: true },
  ocasioes: { type: Array, required: true },
  modo: { type: String, default: 'rapida' }, // 'rapida' | 'revisao'
})

const emit = defineEmits(['atualizado', 'avancar'])

const erro = ref('')

const novaOcasiao = ref({ horario: '', descricao: '', descricao_outro: '', local: 'casa', local_outro: '' })
const criandoOcasiao = ref(false)

const novoItem = ref({}) // { [ocasiaoId]: { nome_livre } }
function itemForm(ocasiaoId) {
  if (!novoItem.value[ocasiaoId]) {
    novoItem.value[ocasiaoId] = { nome_livre: '' }
  }
  return novoItem.value[ocasiaoId]
}

async function criarOcasiao() {
  erro.value = ''
  criandoOcasiao.value = true

  try {
    const payload = {
      ...novaOcasiao.value,
      descricao: novaOcasiao.value.descricao === 'Outro' ? novaOcasiao.value.descricao_outro : novaOcasiao.value.descricao,
    }
    const dados = await props.api.post(`/nc/recordatorios/${props.recordatorioId}/ocasioes`, payload)
    emit('atualizado', dados.ocasioes)
    novaOcasiao.value = { horario: '', descricao: '', descricao_outro: '', local: 'casa', local_outro: '' }
  } catch (e) {
    erro.value = e.dados?.errors ? Object.values(e.dados.errors).flat().join(' ') : e.message
  } finally {
    criandoOcasiao.value = false
  }
}

async function excluirOcasiao(ocasiaoId) {
  if (!confirm('Excluir esta ocasião e os alimentos registrados nela?')) return

  try {
    const dados = await props.api.delete(`/nc/recordatorios/${props.recordatorioId}/ocasioes/${ocasiaoId}`)
    emit('atualizado', dados.ocasioes)
  } catch (e) {
    erro.value = e.message
  }
}

async function adicionarItem(ocasiaoId) {
  const form = itemForm(ocasiaoId)
  if (!form.nome_livre.trim()) return

  erro.value = ''
  try {
    const dados = await props.api.post(`/nc/recordatorios/${props.recordatorioId}/ocasioes/${ocasiaoId}/itens`, form)
    emit('atualizado', dados.ocasioes)
    novoItem.value[ocasiaoId] = { nome_livre: '' }
  } catch (e) {
    erro.value = e.dados?.errors ? Object.values(e.dados.errors).flat().join(' ') : e.message
  }
}

async function atualizarItem(item) {
  erro.value = ''
  try {
    const dados = await props.api.put(`/nc/recordatorios/${props.recordatorioId}/itens/${item.id}`, {
      nome_livre: item.nome_livre,
    })
    emit('atualizado', dados.ocasioes)
  } catch (e) {
    erro.value = e.message
  }
}

async function excluirItem(itemId) {
  erro.value = ''
  try {
    const dados = await props.api.delete(`/nc/recordatorios/${props.recordatorioId}/itens/${itemId}`)
    emit('atualizado', dados.ocasioes)
  } catch (e) {
    erro.value = e.message
  }
}
</script>

<template>
  <div>
    <p class="text-muted small" v-if="modo === 'rapida'">
      Registre horário, ocasião e os alimentos citados, sem se preocupar com gramatura ainda — isso vem no passo de detalhamento.
    </p>
    <p class="text-muted small" v-else>
      Confirme com o entrevistado se não falta nenhum alimento antes de seguir para o detalhamento.
    </p>

    <p v-if="erro" class="text-danger small">{{ erro }}</p>

    <div class="card shadow-sm mb-3">
      <div class="card-body">
        <h6 class="card-title">Nova ocasião</h6>
        <form class="row g-2 align-items-end" @submit.prevent="criarOcasiao">
          <div class="col-md-2">
            <label class="form-label small">Horário</label>
            <input type="time" class="form-control form-control-sm" v-model="novaOcasiao.horario" required />
          </div>
          <div class="col-md-3">
            <label class="form-label small">Ocasião</label>
            <select class="form-select form-select-sm" v-model="novaOcasiao.descricao" required>
              <option value="" disabled>Selecione...</option>
              <option v-for="o in OCASIOES" :key="o" :value="o">{{ o }}</option>
            </select>
          </div>
          <div class="col-md-3" v-if="novaOcasiao.descricao === 'Outro'">
            <label class="form-label small">Qual ocasião?</label>
            <input type="text" class="form-control form-control-sm" v-model="novaOcasiao.descricao_outro" required />
          </div>
          <div class="col-md-3">
            <label class="form-label small">Local</label>
            <select class="form-select form-select-sm" v-model="novaOcasiao.local">
              <option v-for="l in LOCAIS" :key="l.value" :value="l.value">{{ l.label }}</option>
            </select>
          </div>
          <div class="col-md-3" v-if="novaOcasiao.local === 'outro'">
            <label class="form-label small">Qual local?</label>
            <input type="text" class="form-control form-control-sm" v-model="novaOcasiao.local_outro" required />
          </div>
          <div class="col-md-1">
            <button type="submit" class="btn btn-success btn-sm w-100" :disabled="criandoOcasiao">+</button>
          </div>
        </form>
      </div>
    </div>

    <div v-if="!ocasioes.length" class="text-muted">Nenhuma ocasião registrada ainda.</div>

    <div class="card shadow-sm mb-3" v-for="ocasiao in ocasioes" :key="ocasiao.id">
      <div class="card-body">
        <div class="d-flex justify-content-between align-items-start mb-2">
          <div>
            <strong>{{ formatarHorario(ocasiao.horario) }}</strong> — {{ ocasiao.descricao }}
            <span class="badge bg-light text-dark ms-2">{{ rotuloLocal(ocasiao) }}</span>
          </div>
          <button class="btn-close btn-sm" title="Excluir ocasião" @click="excluirOcasiao(ocasiao.id)"></button>
        </div>

        <ul class="list-group list-group-flush mb-2">
          <li class="list-group-item d-flex align-items-center gap-2 px-0" v-for="item in ocasiao.itens" :key="item.id">
            <input type="text" class="form-control form-control-sm" v-model="item.nome_livre" @change="atualizarItem(item)" />
            <button class="btn-close btn-sm" title="Remover item" @click="excluirItem(item.id)"></button>
          </li>
          <li class="list-group-item text-muted small px-0" v-if="!ocasiao.itens.length">Nenhum alimento registrado nesta ocasião.</li>
        </ul>

        <form class="row g-2 align-items-end" @submit.prevent="adicionarItem(ocasiao.id)">
          <div class="col-md-10">
            <input type="text" class="form-control form-control-sm" placeholder="nome do alimento/bebida" v-model="itemForm(ocasiao.id).nome_livre" />
          </div>
          <div class="col-md-2">
            <button type="submit" class="btn btn-outline-success btn-sm w-100">+ Item</button>
          </div>
        </form>
      </div>
    </div>

    <div class="d-flex justify-content-end mt-3">
      <button class="btn btn-primary" :disabled="!ocasioes.length" @click="$emit('avancar')">
        {{ modo === 'rapida' ? 'Avançar para revisão da lista →' : 'Confirmar e avançar para detalhamento →' }}
      </button>
    </div>
  </div>
</template>
