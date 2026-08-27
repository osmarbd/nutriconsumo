<script setup>
import { ref, computed, onMounted } from 'vue'
import { formatarHorario } from './locais.js'
import AlimentoPersonalizadoForm from './AlimentoPersonalizadoForm.vue'

const props = defineProps({
  api: { type: Object, required: true },
  recordatorioId: { type: [Number, String], required: true },
  ocasioes: { type: Array, required: true },
})

const emit = defineEmits(['atualizado', 'avancar'])

const erro = ref('')
const personalizados = ref([])

async function carregarPersonalizados() {
  try {
    const dados = await props.api.get('/nc/alimentos/personalizados')
    personalizados.value = dados.itens
  } catch (e) {
    erro.value = e.message
  }
}

onMounted(carregarPersonalizados)

// Só uma ocasião expandida por vez, e dentro dela só um item em edição —
// mantém a busca/formulário sempre focados num único alimento por vez.
const ocasiaoAberta = ref(null)
function alternarOcasiao(ocasiaoId) {
  ocasiaoAberta.value = ocasiaoAberta.value === ocasiaoId ? null : ocasiaoId
  itemEmEdicao.value = null
}

const itemEmEdicao = ref(null)
const abaBusca = ref('tbca')
const busca = ref('')
const resultadosTbca = ref([])
const buscandoTbca = ref(false)
const mostrarFormPersonalizado = ref(false)

// Medida padrão do alimento atualmente selecionado no form (no máximo 1 por
// alimento da TBCA — confirmado ao vivo; alimento personalizado nunca tem,
// a tabela só referencia br_t_alimentos). null = não tem/não disponível.
const medidaFoodEspecifica = ref(null)
const buscandoMedida = ref(false)

const form = ref({
  origem: null, // 'tbca' | 'personalizado'
  alimentoCod: null,
  alimentoId: null,
  nomeAlimento: '',
  quantidadePersonalizada: '',
  unidadePersonalizada: 'g',
  opcaoQuantidade: 'nao_utilizada', // 'padrao' | 'nao_utilizada'
  origemAlimento: '',
  referenciaFotografica: '',
  observacao: '',
})

function formVazio() {
  return {
    origem: null,
    alimentoCod: null,
    alimentoId: null,
    nomeAlimento: '',
    quantidadePersonalizada: '',
    unidadePersonalizada: 'g',
    opcaoQuantidade: 'nao_utilizada',
    origemAlimento: '',
    referenciaFotografica: '',
    observacao: '',
  }
}

async function buscarMedidaDoAlimento(codAlimento) {
  buscandoMedida.value = true
  try {
    const dados = await props.api.get(`/nc/alimentos/tbca/${codAlimento}/medida-padrao`)
    medidaFoodEspecifica.value = dados.medida_padrao
  } catch (e) {
    medidaFoodEspecifica.value = null
  } finally {
    buscandoMedida.value = false
  }
}

async function abrirEdicaoItem(item) {
  itemEmEdicao.value = item.id
  abaBusca.value = 'tbca'
  busca.value = ''
  mostrarFormPersonalizado.value = false
  medidaFoodEspecifica.value = null

  if (item.detalhado) {
    // Reabre já preenchido pra permitir corrigir um matching feito antes.
    if (item.origem === 'tbca') {
      await buscarMedidaDoAlimento(item.alimento_cod)
    }

    const bateComPadrao =
      medidaFoodEspecifica.value &&
      medidaFoodEspecifica.value.valor === item.quantidade &&
      medidaFoodEspecifica.value.unidade.toLowerCase() === (item.unidade || '').toLowerCase()

    form.value = {
      origem: item.origem,
      alimentoCod: item.alimento_cod,
      alimentoId: item.alimento_id,
      nomeAlimento: item.nome_alimento,
      quantidadePersonalizada: bateComPadrao ? '' : item.quantidade,
      unidadePersonalizada: item.unidade || 'g',
      opcaoQuantidade: bateComPadrao ? 'padrao' : 'nao_utilizada',
      origemAlimento: item.origem_alimento || '',
      referenciaFotografica: item.referencia_fotografica || '',
      observacao: item.observacao || '',
    }
  } else {
    form.value = formVazio()
  }

  buscarTbca()
}

function fecharEdicaoItem() {
  itemEmEdicao.value = null
}

let debounceTimer = null
function onBuscaInput() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(buscarTbca, 300)
}

let buscaSequencia = 0
async function buscarTbca() {
  const sequenciaAtual = ++buscaSequencia
  buscandoTbca.value = true
  try {
    const params = new URLSearchParams({ q: busca.value.trim(), por_pagina: 20 })
    const dados = await props.api.get(`/nc/alimentos/tbca?${params.toString()}`)
    if (sequenciaAtual === buscaSequencia) {
      resultadosTbca.value = dados.itens
    }
  } catch (e) {
    if (sequenciaAtual === buscaSequencia) erro.value = e.message
  } finally {
    if (sequenciaAtual === buscaSequencia) buscandoTbca.value = false
  }
}

async function selecionarTbca(alimento) {
  form.value.origem = 'tbca'
  form.value.alimentoCod = alimento.cod_alimento
  form.value.alimentoId = null
  form.value.nomeAlimento = alimento.nome
  form.value.quantidadePersonalizada = ''
  medidaFoodEspecifica.value = null

  await buscarMedidaDoAlimento(alimento.cod_alimento)
  // Auto-seleciona a medida padrão do alimento quando existe; senão cai em
  // "Não utilizada" e a quantidade personalizada passa a valer.
  form.value.opcaoQuantidade = medidaFoodEspecifica.value ? 'padrao' : 'nao_utilizada'
}

function selecionarPersonalizado(alimento) {
  form.value.origem = 'personalizado'
  form.value.alimentoId = alimento.id
  form.value.alimentoCod = null
  form.value.nomeAlimento = alimento.nome
  form.value.quantidadePersonalizada = ''
  // Alimento personalizado nunca tem medida padrão (a tabela só referencia
  // br_t_alimentos, o catálogo da própria TBCA).
  medidaFoodEspecifica.value = null
  form.value.opcaoQuantidade = 'nao_utilizada'
}

function aoCriarPersonalizado(alimento) {
  mostrarFormPersonalizado.value = false
  carregarPersonalizados()
  selecionarPersonalizado(alimento)
}

function trocarAlimento() {
  form.value.origem = null
  form.value.alimentoCod = null
  form.value.alimentoId = null
  form.value.nomeAlimento = ''
  form.value.quantidadePersonalizada = ''
  form.value.opcaoQuantidade = 'nao_utilizada'
  medidaFoodEspecifica.value = null
}

// A medida padrão tem precedência: enquanto "opcaoQuantidade" for 'padrao',
// a quantidade personalizada digitada ao lado fica desabilitada e é
// ignorada — só prevalece quando "Não utilizada" está selecionada.
const quantidadeResolvida = computed(() => {
  if (form.value.opcaoQuantidade === 'padrao' && medidaFoodEspecifica.value) {
    return {
      quantidade: medidaFoodEspecifica.value.valor,
      unidade: medidaFoodEspecifica.value.unidade.toLowerCase(),
    }
  }

  const q = Number(form.value.quantidadePersonalizada)
  return {
    quantidade: Number.isFinite(q) && q > 0 ? q : null,
    unidade: form.value.unidadePersonalizada,
  }
})

const podeSalvar = computed(() =>
  form.value.origem !== null &&
  quantidadeResolvida.value.quantidade !== null &&
  form.value.origemAlimento.trim() !== '' &&
  form.value.referenciaFotografica.trim() !== ''
)

const salvando = ref(false)

async function salvarMatching(itemId) {
  if (!podeSalvar.value) return

  salvando.value = true
  erro.value = ''
  try {
    const dados = await props.api.put(`/nc/recordatorios/${props.recordatorioId}/itens/${itemId}/detalhar`, {
      origem: form.value.origem,
      alimento_cod: form.value.alimentoCod,
      alimento_id: form.value.alimentoId,
      quantidade: quantidadeResolvida.value.quantidade,
      unidade: quantidadeResolvida.value.unidade,
      origem_alimento: form.value.origemAlimento,
      referencia_fotografica: form.value.referenciaFotografica,
      observacao: form.value.observacao || null,
    })
    emit('atualizado', dados.ocasioes)
    itemEmEdicao.value = null
  } catch (e) {
    erro.value = e.dados?.errors ? Object.values(e.dados.errors).flat().join(' ') : e.message
  } finally {
    salvando.value = false
  }
}

const totalItens = computed(() => props.ocasioes.reduce((soma, o) => soma + o.itens.length, 0))
const totalDetalhados = computed(() =>
  props.ocasioes.reduce((soma, o) => soma + o.itens.filter((i) => i.detalhado).length, 0)
)
</script>

<template>
  <div>
    <p class="text-muted small">
      Para cada ocasião, faça o matching de cada alimento/bebida citado: busque o correspondente na base TBCA ou
      cadastre um alimento personalizado, e informe a quantidade consumida.
    </p>

    <p v-if="erro" class="text-danger small">{{ erro }}</p>

    <p class="small text-muted" v-if="totalItens">{{ totalDetalhados }} de {{ totalItens }} item(ns) já com matching.</p>

    <div class="card shadow-sm mb-3" v-for="ocasiao in ocasioes" :key="ocasiao.id">
      <div class="card-body">
        <div class="d-flex justify-content-between align-items-center mb-2">
          <h6 class="card-title mb-0">{{ formatarHorario(ocasiao.horario) }} — {{ ocasiao.descricao }}</h6>
          <button class="btn btn-sm btn-outline-success" @click="alternarOcasiao(ocasiao.id)">
            {{ ocasiaoAberta === ocasiao.id ? 'Fechar' : 'Fazer matching desta ocasião' }}
          </button>
        </div>

        <ul class="list-group list-group-flush mb-0" v-if="ocasiaoAberta !== ocasiao.id">
          <li class="list-group-item px-0 d-flex justify-content-between align-items-center" v-for="item in ocasiao.itens" :key="item.id">
            <span>{{ item.nome_alimento || item.nome_livre }}</span>
            <span class="badge bg-success" v-if="item.detalhado">✓ {{ item.quantidade }}{{ item.unidade }}</span>
            <span class="badge bg-warning text-dark" v-else>Pendente</span>
          </li>
          <li class="list-group-item px-0 text-muted small" v-if="!ocasiao.itens.length">Nenhum alimento registrado nesta ocasião.</li>
        </ul>

        <div v-else>
          <div class="border rounded p-2 mb-2" v-for="item in ocasiao.itens" :key="item.id">
            <div class="d-flex justify-content-between align-items-center">
              <div>
                <strong>{{ item.nome_livre }}</strong>
                <template v-if="item.detalhado">
                  <span class="text-muted small ms-2">
                    vinculado a <strong>{{ item.nome_alimento }}</strong> — {{ item.quantidade }}{{ item.unidade }}
                  </span>
                </template>
              </div>
              <button
                class="btn btn-sm"
                :class="item.detalhado ? 'btn-outline-secondary' : 'btn-outline-success'"
                @click="itemEmEdicao === item.id ? fecharEdicaoItem() : abrirEdicaoItem(item)"
              >
                {{ itemEmEdicao === item.id ? 'Fechar' : (item.detalhado ? 'Editar matching' : 'Buscar alimento') }}
              </button>
            </div>

            <div class="mt-2" v-if="itemEmEdicao === item.id">
              <div class="row g-3">
                <div class="col-md-6">
                  <template v-if="form.origem">
                    <div class="alert alert-light border py-2 px-3 d-flex justify-content-between align-items-center mb-2">
                      <span>
                        <span class="badge me-1" :class="form.origem === 'tbca' ? 'bg-secondary' : 'bg-primary'">
                          {{ form.origem === 'tbca' ? form.alimentoCod : 'personalizado' }}
                        </span>
                        {{ form.nomeAlimento }}
                      </span>
                      <button class="btn btn-sm btn-link" @click="trocarAlimento">trocar</button>
                    </div>
                  </template>
                  <template v-else>
                    <ul class="nav nav-tabs nav-tabs-sm mb-2">
                      <li class="nav-item">
                        <a class="nav-link py-1" :class="{ active: abaBusca === 'tbca' }" href="javascript:void(0)" @click="abaBusca = 'tbca'">Base TBCA</a>
                      </li>
                      <li class="nav-item">
                        <a class="nav-link py-1" :class="{ active: abaBusca === 'personalizados' }" href="javascript:void(0)" @click="abaBusca = 'personalizados'">Meus alimentos</a>
                      </li>
                    </ul>

                    <div v-if="abaBusca === 'tbca'">
                      <input type="text" class="form-control form-control-sm mb-2" placeholder="Buscar por nome ou código..." v-model="busca" @input="onBuscaInput" />
                      <p v-if="buscandoTbca" class="small text-muted">Buscando...</p>
                      <div class="list-group" style="max-height: 220px; overflow-y: auto;">
                        <button
                          v-for="alimento in resultadosTbca"
                          :key="alimento.cod_alimento"
                          type="button"
                          class="list-group-item list-group-item-action small"
                          @click="selecionarTbca(alimento)"
                        >
                          <span class="badge bg-secondary me-1">{{ alimento.cod_alimento }}</span>{{ alimento.nome }}
                        </button>
                        <p v-if="!resultadosTbca.length && !buscandoTbca" class="text-muted small mb-0">Nenhum alimento encontrado.</p>
                      </div>
                      <p class="small text-muted mt-2 mb-0">
                        Não encontrou? Cadastre um
                        <a href="javascript:void(0)" @click="abaBusca = 'personalizados'; mostrarFormPersonalizado = true">alimento personalizado</a>.
                      </p>
                    </div>

                    <div v-else>
                      <button class="btn btn-sm btn-outline-success mb-2" @click="mostrarFormPersonalizado = !mostrarFormPersonalizado">
                        {{ mostrarFormPersonalizado ? 'Fechar formulário' : '+ Novo alimento personalizado' }}
                      </button>
                      <AlimentoPersonalizadoForm v-if="mostrarFormPersonalizado" :api="api" @criado="aoCriarPersonalizado" @cancelar="mostrarFormPersonalizado = false" />
                      <div class="list-group" style="max-height: 220px; overflow-y: auto;">
                        <button
                          v-for="alimento in personalizados"
                          :key="alimento.id"
                          type="button"
                          class="list-group-item list-group-item-action small"
                          @click="selecionarPersonalizado(alimento)"
                        >
                          <span class="badge bg-primary me-1">{{ alimento.codigo }}</span>{{ alimento.nome }}
                        </button>
                        <p v-if="!personalizados.length" class="text-muted small mb-0">Nenhum alimento personalizado cadastrado ainda.</p>
                      </div>
                    </div>
                  </template>
                </div>

                <div class="col-md-6">
                  <label class="form-label small fw-semibold">Medida</label>
                  <p class="small text-muted mb-1" v-if="buscandoMedida">Verificando medida padrão deste alimento...</p>
                  <select class="form-select form-select-sm mb-2" v-model="form.opcaoQuantidade" v-else>
                    <option value="padrao" :disabled="!medidaFoodEspecifica">
                      <template v-if="medidaFoodEspecifica">{{ medidaFoodEspecifica.medida }} — {{ medidaFoodEspecifica.valor }}{{ medidaFoodEspecifica.unidade }}</template>
                      <template v-else>Medida padrão (não disponível para este alimento)</template>
                    </option>
                    <option value="nao_utilizada">Não utilizada</option>
                  </select>

                  <label class="form-label small fw-semibold">Quantidade personalizada <span class="text-muted fw-normal">(só quando "Não utilizada" estiver selecionado)</span></label>
                  <div class="input-group input-group-sm mb-2">
                    <input
                      type="number" min="0" step="any" class="form-control"
                      v-model="form.quantidadePersonalizada"
                      :disabled="form.opcaoQuantidade === 'padrao'"
                      placeholder="Quantidade"
                    />
                    <select class="form-select" style="max-width: 80px;" v-model="form.unidadePersonalizada" :disabled="form.opcaoQuantidade === 'padrao'">
                      <option value="g">g</option>
                      <option value="ml">ml</option>
                    </select>
                  </div>

                  <label class="form-label small fw-semibold">Origem do alimento <span class="text-danger">*</span></label>
                  <input type="text" class="form-control form-control-sm mb-2" v-model="form.origemAlimento" placeholder="Ex.: marca, padaria, feito em casa..." />

                  <label class="form-label small fw-semibold">Referência fotográfica <span class="text-danger">*</span></label>
                  <input type="text" class="form-control form-control-sm mb-2" v-model="form.referenciaFotografica" placeholder="Ex.: nome do arquivo/foto" />

                  <label class="form-label small fw-semibold">Observação</label>
                  <textarea class="form-control form-control-sm mb-2" rows="2" v-model="form.observacao"></textarea>

                  <button class="btn btn-success btn-sm w-100" :disabled="!podeSalvar || salvando" @click="salvarMatching(item.id)">
                    {{ salvando ? 'Salvando...' : 'Salvar matching' }}
                  </button>
                </div>
              </div>
            </div>
          </div>
          <p class="text-muted small mb-0" v-if="!ocasiao.itens.length">Nenhum alimento registrado nesta ocasião.</p>
        </div>
      </div>
    </div>

    <div class="d-flex justify-content-end mt-3">
      <button class="btn btn-primary" :disabled="!ocasioes.length" @click="$emit('avancar')">
        Avançar para revisão final →
      </button>
    </div>
  </div>
</template>
