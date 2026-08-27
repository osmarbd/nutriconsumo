<script setup>
import { ref, computed, onMounted } from 'vue'
import PassoListaRapida from './PassoListaRapida.vue'
import PassoDetalhamento from './PassoDetalhamento.vue'
import PassoMatching from './PassoMatching.vue'
import PassoRevisaoFinal from './PassoRevisaoFinal.vue'

const props = defineProps({
  api: { type: Object, required: true },
  recordatorioId: { type: [Number, String], required: true },
})

const emit = defineEmits(['voltar'])

const PASSOS = [
  { chave: 'lista_rapida', numero: 1, titulo: 'Lista rápida' },
  { chave: 'revisao_lista', numero: 2, titulo: 'Revisão da lista' },
  { chave: 'detalhamento', numero: 3, titulo: 'Detalhamento' },
  { chave: 'matching', numero: 4, titulo: 'Matching' },
  { chave: 'revisao_final', numero: 5, titulo: 'Revisão final' },
]

const recordatorio = ref(null)
const ocasioes = ref([])
const nutrientes = ref([])
const carregando = ref(true)
const erro = ref('')
const passoAtivo = ref('lista_rapida')

async function buscarDados() {
  const dados = await props.api.get(`/nc/recordatorios/${props.recordatorioId}`)
  recordatorio.value = dados.recordatorio
  ocasioes.value = dados.ocasioes
  nutrientes.value = dados.nutrientes
  return dados
}

async function carregar() {
  carregando.value = true
  erro.value = ''

  try {
    const dados = await buscarDados()
    // etapa 'finalizado' ainda mostra a tela de revisão final, só travada.
    passoAtivo.value = dados.recordatorio.etapa === 'finalizado' ? 'revisao_final' : dados.recordatorio.etapa
  } catch (e) {
    erro.value = e.message
  } finally {
    carregando.value = false
  }
}

// Passos intermediários fazem atualização otimista (via @atualizado) só pra
// resposta visual imediata — mas nunca é garantia de chegar aqui: se o
// pesquisador clicar "Avançar" antes do POST/PUT em voo resolver, o passo de
// origem já pode estar desmontado quando a resposta chega, e o `emit` de um
// componente desmontado não atualiza mais nada aqui (perdido em silêncio).
// Por isso toda troca de passo pra frente sempre busca o estado real do
// servidor de novo antes de trocar — garante que o passo seguinte nunca
// mostra dados desatualizados, independente de timing.
function aoAtualizarOcasioes(novasOcasioes) {
  ocasioes.value = novasOcasioes
}

async function irPara(chave) {
  const indiceAtual = PASSOS.findIndex((p) => p.chave === passoAtivo.value)
  const indiceAlvo = PASSOS.findIndex((p) => p.chave === chave)
  const avancando = indiceAlvo > indiceAtual && recordatorio.value.etapa !== 'finalizado'

  erro.value = ''
  try {
    if (avancando) {
      await props.api.put(`/nc/recordatorios/${props.recordatorioId}/etapa`, { etapa: chave })
    }
    await buscarDados()
    passoAtivo.value = chave
  } catch (e) {
    erro.value = e.message
  }
}

async function finalizar() {
  try {
    const dados = await props.api.put(`/nc/recordatorios/${props.recordatorioId}/etapa`, { etapa: 'finalizado' })
    recordatorio.value = dados.recordatorio
  } catch (e) {
    erro.value = e.message
  }
}

const totalItens = computed(() => ocasioes.value.reduce((soma, o) => soma + o.itens.length, 0))

onMounted(carregar)
</script>

<template>
  <div>
    <button class="btn btn-sm btn-outline-secondary mb-3" @click="$emit('voltar')">&larr; Voltar aos recordatórios</button>

    <p v-if="erro" class="text-danger">{{ erro }}</p>
    <p v-if="carregando">Carregando recordatório...</p>

    <template v-else-if="recordatorio">
      <div class="card shadow-sm mb-3">
        <div class="card-body py-2">
          <div class="d-flex flex-wrap gap-3 align-items-center small">
            <span><strong>Entrevistador:</strong> {{ recordatorio.entrevistador_codigo }}</span>
            <span><strong>Entrevistado:</strong> {{ recordatorio.entrevistado_codigo }}</span>
            <span><strong>Data:</strong> {{ recordatorio.data_entrevista }}</span>
            <span><strong>Recordatório nº:</strong> {{ recordatorio.numero_recordatorio }}</span>
            <span v-if="recordatorio.etapa === 'finalizado'" class="badge bg-success">Finalizado</span>
          </div>
        </div>
      </div>

      <ul class="nav nav-pills mb-4 gap-1">
        <li class="nav-item" v-for="passo in PASSOS" :key="passo.chave">
          <a
            href="javascript:void(0)"
            class="nav-link"
            :class="{ active: passoAtivo === passo.chave }"
            @click="irPara(passo.chave)"
          >
            {{ passo.numero }}. {{ passo.titulo }}
          </a>
        </li>
      </ul>

      <PassoListaRapida
        v-if="passoAtivo === 'lista_rapida'"
        :api="api"
        :recordatorio-id="recordatorioId"
        :ocasioes="ocasioes"
        @atualizado="aoAtualizarOcasioes"
        @avancar="irPara('revisao_lista')"
      />

      <PassoListaRapida
        v-else-if="passoAtivo === 'revisao_lista'"
        :api="api"
        :recordatorio-id="recordatorioId"
        :ocasioes="ocasioes"
        modo="revisao"
        @atualizado="aoAtualizarOcasioes"
        @avancar="irPara('detalhamento')"
      />

      <PassoDetalhamento
        v-else-if="passoAtivo === 'detalhamento'"
        :api="api"
        :recordatorio-id="recordatorioId"
        :ocasioes="ocasioes"
        @atualizado="aoAtualizarOcasioes"
        @avancar="irPara('matching')"
      />

      <PassoMatching
        v-else-if="passoAtivo === 'matching'"
        :api="api"
        :recordatorio-id="recordatorioId"
        :ocasioes="ocasioes"
        @atualizado="aoAtualizarOcasioes"
        @avancar="irPara('revisao_final')"
      />

      <PassoRevisaoFinal
        v-else-if="passoAtivo === 'revisao_final'"
        :api="api"
        :recordatorio-id="recordatorioId"
        :recordatorio="recordatorio"
        :ocasioes="ocasioes"
        :nutrientes="nutrientes"
        :finalizado="recordatorio.etapa === 'finalizado'"
        :total-itens="totalItens"
        @finalizar="finalizar"
      />
    </template>
  </div>
</template>
