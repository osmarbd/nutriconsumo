<script setup>
import { ref } from 'vue'
import { formatarHorario } from './locais.js'

const props = defineProps({
  api: { type: Object, required: true },
  recordatorioId: { type: [Number, String], required: true },
  ocasioes: { type: Array, required: true },
})

const emit = defineEmits(['atualizado', 'avancar'])

const erro = ref('')

// Ainda não vinculamos o item a um alimento da TBCA/personalizado aqui — só
// aprofunda a lista livre por ocasião (mesmo padrão de PassoListaRapida).
// O vínculo com a base TBCA (quantidade, origem, referência fotográfica)
// fica pra uma etapa futura.
const novoItem = ref({}) // { [ocasiaoId]: { nome_livre } }
function itemForm(ocasiaoId) {
  if (!novoItem.value[ocasiaoId]) {
    novoItem.value[ocasiaoId] = { nome_livre: '' }
  }
  return novoItem.value[ocasiaoId]
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
    <p class="text-muted small">
      Aprofunde a entrevista e registre todos os alimentos e bebidas citados em cada ocasião — o vínculo com a base
      TBCA (gramatura, origem, referência fotográfica) vem numa etapa futura.
    </p>

    <p v-if="erro" class="text-danger small">{{ erro }}</p>

    <div class="card shadow-sm mb-3" v-for="ocasiao in ocasioes" :key="ocasiao.id">
      <div class="card-body">
        <h6 class="card-title">{{ formatarHorario(ocasiao.horario) }} — {{ ocasiao.descricao }}</h6>

        <ul class="list-group list-group-flush mb-2">
          <li class="list-group-item d-flex align-items-center gap-2 px-0" v-for="item in ocasiao.itens" :key="item.id">
            <input type="text" class="form-control form-control-sm" v-model="item.nome_livre" @change="atualizarItem(item)" />
            <button class="btn-close btn-sm" title="Remover item" @click="excluirItem(item.id)"></button>
          </li>
          <li class="list-group-item text-muted small px-0" v-if="!ocasiao.itens.length">Nenhum alimento registrado nesta ocasião.</li>
        </ul>

        <form class="row g-2 align-items-end" @submit.prevent="adicionarItem(ocasiao.id)">
          <div class="col-md-10">
            <input type="text" class="form-control form-control-sm" placeholder="adicionar alimento/bebida" v-model="itemForm(ocasiao.id).nome_livre" />
          </div>
          <div class="col-md-2">
            <button type="submit" class="btn btn-outline-success btn-sm w-100">+ Item</button>
          </div>
        </form>
      </div>
    </div>

    <div class="d-flex justify-content-end mt-3">
      <button class="btn btn-primary" :disabled="!ocasioes.length" @click="$emit('avancar')">
        Confirmar e avançar para revisão final →
      </button>
    </div>
  </div>
</template>
