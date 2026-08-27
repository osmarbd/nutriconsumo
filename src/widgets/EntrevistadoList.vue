<script setup>
import { ref, onMounted } from 'vue'

const props = defineProps({
  api: { type: Object, required: true },
})

const entrevistados = ref([])
const carregando = ref(true)
const erro = ref('')

const novoNome = ref('')
const novaDataNascimento = ref('')
const criando = ref(false)

async function carregar() {
  carregando.value = true
  erro.value = ''
  try {
    const dados = await props.api.get('/nc/entrevistados')
    entrevistados.value = dados.itens
  } catch (e) {
    erro.value = e.message
  } finally {
    carregando.value = false
  }
}

async function cadastrar() {
  erro.value = ''
  criando.value = true
  try {
    await props.api.post('/nc/entrevistados', {
      nome: novoNome.value,
      data_nascimento: novaDataNascimento.value,
    })
    novoNome.value = ''
    novaDataNascimento.value = ''
    await carregar()
  } catch (e) {
    erro.value = e.dados?.errors ? Object.values(e.dados.errors).flat().join(' ') : e.message
  } finally {
    criando.value = false
  }
}

function formatarData(data) {
  if (!data) return ''
  const [ano, mes, dia] = data.split('-')
  return `${dia}/${mes}/${ano}`
}

onMounted(carregar)
</script>

<template>
  <div>
    <div class="card shadow-sm mb-4">
      <div class="card-body">
        <h5 class="card-title">Novo entrevistado</h5>
        <form class="row g-2" @submit.prevent="cadastrar">
          <div class="col-md-5">
            <label class="form-label small">Nome</label>
            <input type="text" class="form-control" v-model="novoNome" required />
          </div>
          <div class="col-md-4">
            <label class="form-label small">Data de nascimento</label>
            <input type="date" class="form-control" v-model="novaDataNascimento" required />
          </div>
          <div class="col-md-3 d-flex align-items-end">
            <button type="submit" class="btn btn-success w-100" :disabled="criando">
              {{ criando ? 'Aguarde...' : 'Cadastrar' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <p v-if="erro" class="text-danger small">{{ erro }}</p>
    <p v-if="carregando" class="text-muted">Carregando entrevistados...</p>

    <div v-else class="list-group">
      <div v-for="entrevistado in entrevistados" :key="entrevistado.id" class="list-group-item">
        <span class="badge bg-secondary me-2">{{ entrevistado.codigo }}</span>
        <strong>{{ entrevistado.nome }}</strong>
        <span class="text-muted small ms-2">nascido(a) em {{ formatarData(entrevistado.data_nascimento) }}</span>
      </div>
      <p v-if="!entrevistados.length" class="text-muted">Nenhum entrevistado cadastrado ainda.</p>
    </div>
  </div>
</template>
