<script setup>
import { ref, computed, onMounted } from 'vue'
import RecordatorioWizard from './RecordatorioWizard.vue'

const props = defineProps({
  api: { type: Object, required: true },
  usuario: { type: Object, required: true },
})

const recordatorios = ref([])
const carregando = ref(true)
const erro = ref('')
const recordatorioAbertoId = ref(null)

// Limite de recordatórios é por entrevistador (não mais por entrevistado),
// gerado/validado no backend — ver NcRecordatorioController::criar.
const totalCriados = ref(0)
const limite = ref(30)
const LIMIAR_AVISO = 25
const atingiuLimite = computed(() => totalCriados.value >= limite.value)
const proximoDoLimite = computed(() => !atingiuLimite.value && totalCriados.value >= LIMIAR_AVISO)

const entrevistados = ref([])
const carregandoEntrevistados = ref(true)
// Etapa obrigatória antes de criar um recordatório: primeiro escolhe QUEM foi
// entrevistado (entre os já cadastrados na aba "Entrevistados"), só depois
// aparece o formulário do recordatório em si — evita digitar o código à mão
// e reduz erro de digitação.
const entrevistadoSelecionado = ref(null)

const mapaEntrevistadosPorCodigo = computed(() => {
  const mapa = {}
  for (const e of entrevistados.value) mapa[e.codigo] = e
  return mapa
})

// entrevistador_codigo não é digitável — vem sempre do próprio usuário
// logado (t_nc_users.id), o backend recalcula e ignora qualquer valor
// enviado aqui; isso só existe pra exibir o valor já travado na tela.
const form = ref({
  entrevistado_codigo: '',
  data_entrevista: '',
})
const criando = ref(false)

const ETAPAS_LABEL = {
  lista_rapida: 'Lista rápida',
  revisao_lista: 'Revisão da lista',
  detalhamento: 'Detalhamento',
  revisao_final: 'Revisão final',
  finalizado: 'Finalizado',
}

async function carregar() {
  carregando.value = true
  erro.value = ''

  try {
    const dados = await props.api.get('/nc/recordatorios')
    recordatorios.value = dados.itens
    totalCriados.value = dados.total_criados
    limite.value = dados.limite
  } catch (e) {
    erro.value = e.message
  } finally {
    carregando.value = false
  }
}

async function carregarEntrevistados() {
  carregandoEntrevistados.value = true
  try {
    const dados = await props.api.get('/nc/entrevistados')
    entrevistados.value = dados.itens
  } catch (e) {
    erro.value = e.message
  } finally {
    carregandoEntrevistados.value = false
  }
}

function selecionarEntrevistado(entrevistado) {
  entrevistadoSelecionado.value = entrevistado
  form.value.entrevistado_codigo = entrevistado.codigo
}

function trocarEntrevistado() {
  entrevistadoSelecionado.value = null
  form.value.entrevistado_codigo = ''
}

async function criarRecordatorio() {
  criando.value = true
  erro.value = ''

  try {
    const dados = await props.api.post('/nc/recordatorios', form.value)
    form.value.data_entrevista = ''
    await carregar()
    recordatorioAbertoId.value = dados.recordatorio.id
  } catch (e) {
    erro.value = e.dados?.errors ? Object.values(e.dados.errors).flat().join(' ') : e.message
  } finally {
    criando.value = false
  }
}

async function excluirRecordatorio(id) {
  if (!confirm('Excluir este recordatório e tudo que já foi registrado nele?')) return

  try {
    await props.api.delete(`/nc/recordatorios/${id}`)
    await carregar()
  } catch (e) {
    erro.value = e.message
  }
}

function abrirRecordatorio(id) {
  recordatorioAbertoId.value = id
}

function fecharRecordatorio() {
  recordatorioAbertoId.value = null
  carregar()
}

onMounted(() => {
  carregar()
  carregarEntrevistados()
})
</script>

<template>
  <div>
    <RecordatorioWizard
      v-if="recordatorioAbertoId"
      :api="api"
      :recordatorio-id="recordatorioAbertoId"
      @voltar="fecharRecordatorio"
    />

    <template v-else>
      <div class="alert alert-danger" v-if="atingiuLimite">
        Limite de {{ limite }} recordatórios atingido para o seu cadastro de entrevistador. Não é possível criar novos
        recordatórios — exclua algum já existente para liberar espaço, se necessário.
      </div>
      <div class="alert alert-warning" v-else-if="proximoDoLimite">
        Atenção: você já criou {{ totalCriados }} de {{ limite }} recordatórios permitidos. Restam
        {{ limite - totalCriados }}.
      </div>

      <template v-if="!atingiuLimite">
        <div class="card shadow-sm mb-4" v-if="!entrevistadoSelecionado">
          <div class="card-body">
            <h5 class="card-title">Selecione o entrevistado para iniciar um novo recordatório</h5>

            <p v-if="carregandoEntrevistados" class="text-muted small mb-0">Carregando entrevistados...</p>
            <template v-else-if="!entrevistados.length">
              <p class="text-muted small mb-0">
                Nenhum entrevistado cadastrado ainda. Cadastre um na aba "Entrevistados" antes de iniciar um recordatório.
              </p>
            </template>
            <div class="list-group" v-else>
              <div
                v-for="entrevistado in entrevistados"
                :key="entrevistado.id"
                class="list-group-item d-flex justify-content-between align-items-center"
              >
                <div>
                  <span class="badge bg-secondary me-2">{{ entrevistado.codigo }}</span>
                  <strong>{{ entrevistado.nome }}</strong>
                </div>
                <button class="btn btn-sm btn-outline-success" @click="selecionarEntrevistado(entrevistado)">Selecionar</button>
              </div>
            </div>
          </div>
        </div>

        <div class="card shadow-sm mb-4" v-else>
          <div class="card-body">
            <div class="d-flex justify-content-between align-items-center mb-2">
              <h5 class="card-title mb-0">Novo recordatório alimentar</h5>
              <button class="btn btn-sm btn-outline-secondary" @click="trocarEntrevistado">Trocar entrevistado</button>
            </div>
            <form class="row g-2" @submit.prevent="criarRecordatorio">
              <div class="col-md-3">
                <label class="form-label small">Código do entrevistador</label>
                <input type="text" class="form-control" :value="usuario.codigo_entrevistador" disabled readonly title="Gerado automaticamente a partir do seu usuário" />
              </div>
              <div class="col-md-4">
                <label class="form-label small">Entrevistado</label>
                <input type="text" class="form-control" :value="`${entrevistadoSelecionado.codigo} — ${entrevistadoSelecionado.nome}`" disabled readonly />
              </div>
              <div class="col-md-3">
                <label class="form-label small">Data da entrevista</label>
                <input type="date" class="form-control" v-model="form.data_entrevista" required />
              </div>
              <div class="col-md-2 d-flex align-items-end">
                <button type="submit" class="btn btn-success w-100" :disabled="criando">Criar</button>
              </div>
            </form>
          </div>
        </div>
      </template>

      <p v-if="erro" class="text-danger">{{ erro }}</p>
      <p v-if="carregando">Carregando recordatórios...</p>

      <div v-else class="list-group">
        <div
          v-for="r in recordatorios"
          :key="r.id"
          class="list-group-item d-flex justify-content-between align-items-center"
        >
          <a href="javascript:void(0)" class="text-decoration-none flex-grow-1" @click="abrirRecordatorio(r.id)">
            <strong>Entrevistado {{ r.entrevistado_codigo }}</strong>
            <span class="text-muted small ms-1" v-if="mapaEntrevistadosPorCodigo[r.entrevistado_codigo]">
              ({{ mapaEntrevistadosPorCodigo[r.entrevistado_codigo].nome }})
            </span>
            <span class="text-muted small ms-2">recordatório nº {{ r.numero_recordatorio }} — {{ r.data_entrevista }}</span>
            <span class="badge bg-light text-dark ms-2">{{ r.total_itens }} item(ns)</span>
            <span class="badge bg-info text-dark ms-2">{{ ETAPAS_LABEL[r.etapa] }}</span>
          </a>
          <button class="btn btn-sm btn-outline-danger" @click="excluirRecordatorio(r.id)">Excluir</button>
        </div>
        <p v-if="!recordatorios.length" class="text-muted">Nenhum recordatório criado ainda.</p>
      </div>
    </template>
  </div>
</template>
