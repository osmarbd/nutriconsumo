<script setup>
import { ref, watch, onMounted } from 'vue'

const props = defineProps({
  api: { type: Object, required: true },
})

const emit = defineEmits(['criado', 'cancelar'])

const nome = ref('')
const observacoes = ref('')
const grupoId = ref('')
const tipoAlimentoId = ref('')
const grupos = ref([])
const tiposAlimento = ref([])
const nutrientesDisponiveis = ref([])
const valores = ref({})
const salvando = ref(false)
const erro = ref('')

// O alerta de erro fica sempre no topo do modal — se o usuário já tiver
// rolado até os nutrientes (lá embaixo) quando um erro aparecer (ex.: falha
// ao salvar), rola de volta pro topo pra garantir que ele seja visto.
const modalBox = ref(null)
watch(erro, (valor) => {
  if (valor) modalBox.value?.scrollTo({ top: 0, behavior: 'smooth' })
})

// Mesma convenção de códigos-sentinela usada no Nutrireceitas (tbca2) para
// valores de nutriente que não são uma quantidade real — digitando um desses
// (em vez de um número), o valor salvo é o código negativo correspondente.
const CODIGOS_ESPECIAIS = ['tr', 'NA', '-', 'ND', 'N/A', 'SI', 'DA']
const CODIGOS_ESPECIAIS_VALORES = { TR: -1, NA: -2, '-': -3, ND: -4, 'N/A': -5, SI: -6, DA: -7 }

async function carregarReferencias() {
  try {
    const dados = await props.api.get('/nc/referencias')
    grupos.value = dados.grupos
    tiposAlimento.value = dados.tipos_alimento
    nutrientesDisponiveis.value = dados.nutrientes
  } catch (e) {
    // Sem isso, uma falha aqui (ex.: token expirado) deixava os listbox de
    // grupo/tipo silenciosamente vazios, sem nenhuma pista pro usuário.
    erro.value = 'Não foi possível carregar grupos/tipos de alimento: ' + e.message
  }
}

function ehEnergia(n) {
  return ['kj', 'kcal'].includes((n.unidade || '').toLowerCase())
}

function ehInicioDeCodigoEspecial(texto) {
  if (!texto) return false
  const alvo = texto.toUpperCase()
  return CODIGOS_ESPECIAIS.some((codigo) => codigo.toUpperCase().startsWith(alvo))
}

// Máscara aplicada enquanto o usuário digita: se o texto pode vir a formar um
// dos códigos especiais (tr/NA/-/ND/N/A/SI/DA), deixa passar sem mexer; caso
// contrário trata como número — só dígitos e um separador decimal, limitado a
// 2 casas (Energia não aceita decimais, é sempre inteiro).
function onInputNutriente(nutriConfId, energia, event) {
  let texto = event.target.value

  if (texto === '' || ehInicioDeCodigoEspecial(texto)) {
    valores.value[nutriConfId] = texto
    return
  }

  texto = texto.replace(',', '.').replace(/[^\d.]/g, '')

  if (energia) {
    texto = texto.replace(/\./g, '')
  } else {
    const partes = texto.split('.')
    if (partes.length > 2) {
      texto = partes[0] + '.' + partes.slice(1).join('')
    }
    const [inteiro, decimal] = texto.split('.')
    if (decimal !== undefined) {
      texto = `${inteiro}.${decimal.slice(0, 2)}`
    }
  }

  valores.value[nutriConfId] = texto
  event.target.value = texto
}

function valorFinal(bruto) {
  const texto = String(bruto ?? '').trim()
  if (texto === '') return null

  const especial = CODIGOS_ESPECIAIS_VALORES[texto.toUpperCase()]
  if (especial !== undefined) return especial

  const numero = Number(texto)
  return Number.isFinite(numero) ? numero : null
}

async function salvar() {
  if (!nome.value.trim()) return

  erro.value = ''
  salvando.value = true

  const nutrientes = Object.entries(valores.value)
    .map(([nutriConfId, bruto]) => ({ nutri_conf_id: Number(nutriConfId), valor: valorFinal(bruto) }))
    .filter((n) => n.valor !== null)

  try {
    const dados = await props.api.post('/nc/alimentos/personalizados', {
      nome: nome.value,
      observacoes: observacoes.value || null,
      grupo_id: grupoId.value || null,
      tipo_alimento_id: tipoAlimentoId.value || null,
      nutrientes,
    })
    emit('criado', dados.alimento)
  } catch (e) {
    erro.value = e.dados?.errors ? Object.values(e.dados.errors).flat().join(' ') : e.message
  } finally {
    salvando.value = false
  }
}

onMounted(carregarReferencias)
</script>

<template>
  <Teleport to="body">
    <div class="nc-modal-backdrop" @click.self="$emit('cancelar')">
      <div class="nc-modal-box" ref="modalBox">
        <div class="d-flex justify-content-between align-items-center mb-3">
          <h5 class="mb-0">Cadastrar alimento personalizado</h5>
          <button type="button" class="btn-close" aria-label="Fechar" @click="$emit('cancelar')"></button>
        </div>

        <p class="text-muted small">
          Use quando o alimento não estiver na base TBCA. Os valores de nutrientes são por 100 g,
          mesma convenção da TBCA.
        </p>

        <div class="alert alert-danger d-flex align-items-center gap-2 py-2" v-if="erro">
          <i class="bi bi-exclamation-triangle-fill"></i>
          <span>{{ erro }}</span>
        </div>

        <div class="row g-2 mb-2">
          <div class="col-md-6">
            <label class="form-label small">Nome</label>
            <input type="text" class="form-control" v-model="nome" required />
          </div>
          <div class="col-md-3">
            <label class="form-label small">Grupo</label>
            <select class="form-select" v-model="grupoId">
              <option value="">-</option>
              <option v-for="g in grupos" :key="g.id" :value="g.id">{{ g.nome }}</option>
            </select>
          </div>
          <div class="col-md-3">
            <label class="form-label small">Tipo de alimento</label>
            <select class="form-select" v-model="tipoAlimentoId">
              <option value="">-</option>
              <option v-for="t in tiposAlimento" :key="t.id" :value="t.id">{{ t.nome }}</option>
            </select>
          </div>
        </div>

        <div class="mb-3">
          <label class="form-label small">Observações</label>
          <input type="text" class="form-control" v-model="observacoes" />
        </div>

        <label class="form-label small mb-1">Nutrientes (valor por 100 g)</label>
        <p class="text-muted small mb-2">
          Deixe em branco se não souber. Aceita um número (Energia só inteiro, os demais com até 2
          casas decimais) ou um dos códigos <code>tr</code>, <code>NA</code>, <code>-</code>,
          <code>ND</code>, <code>N/A</code>, <code>SI</code>, <code>DA</code>.
        </p>
        <div class="row g-2 mb-3" style="max-height: 45vh; overflow-y: auto;">
          <div class="col-md-4" v-for="n in nutrientesDisponiveis" :key="n.nutri_conf_id">
            <div class="input-group input-group-sm">
              <span class="input-group-text text-truncate" style="max-width: 140px;" :title="n.nutriente">
                {{ n.nutriente }}
              </span>
              <input
                type="text"
                inputmode="decimal"
                class="form-control"
                :value="valores[n.nutri_conf_id]"
                @input="onInputNutriente(n.nutri_conf_id, ehEnergia(n), $event)"
              />
              <span class="input-group-text">{{ n.unidade }}</span>
            </div>
          </div>
        </div>

        <div class="d-flex justify-content-end gap-2">
          <button class="btn btn-outline-secondary" @click="$emit('cancelar')">Cancelar</button>
          <button class="btn btn-success" :disabled="salvando" @click="salvar">
            {{ salvando ? 'Salvando...' : 'Salvar alimento' }}
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.nc-modal-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.55);
  z-index: 1050;
  display: flex;
  justify-content: center;
  align-items: flex-start;
  padding: 32px 16px;
  overflow-y: auto;
}

.nc-modal-box {
  background: #fff;
  border-radius: 8px;
  padding: 24px;
  width: 100%;
  max-width: 960px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 12px 36px rgba(0, 0, 0, 0.25);
}

/* type="text" com inputmode="decimal" já não tem setas — isto aqui só cobre
   caso algum navegador ainda trate o campo como number em algum fallback. */
input[type='number']::-webkit-outer-spin-button,
input[type='number']::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}

input[type='number'] {
  -moz-appearance: textfield;
  appearance: textfield;
}
</style>
