<script setup>
import { ref, computed, onMounted } from 'vue'
import { criarApi, salvarToken, limparToken, temToken } from './api.js'
import Login from './Login.vue'
import Dashboard from './Dashboard.vue'

const props = defineProps({
  apiBase: { type: String, required: true },
})

const api = computed(() => criarApi(props.apiBase))

const usuario = ref(null)
const carregando = ref(true)

async function carregarUsuario() {
  if (!temToken()) {
    carregando.value = false
    return
  }

  try {
    const dados = await api.value.get('/nc/auth/me')
    usuario.value = dados.user
  } catch (e) {
    limparToken()
  } finally {
    carregando.value = false
  }
}

function aoLogar({ token, user }) {
  salvarToken(token)
  usuario.value = user
}

function sair() {
  limparToken()
  usuario.value = null
}

onMounted(carregarUsuario)
</script>

<template>
  <div v-if="carregando" class="text-center text-muted py-5">Carregando...</div>
  <Login v-else-if="!usuario" :api="api" @logado="aoLogar" />
  <Dashboard v-else :api="api" :usuario="usuario" @sair="sair" />
</template>
