<script setup>
import { ref, onMounted } from 'vue'
import AdminUsuarioForm from './AdminUsuarioForm.vue'

const props = defineProps({
  api: { type: Object, required: true },
})

const TIPO_LABEL = {
  admin: 'Administrador',
  user: 'Pesquisador',
}

const usuarios = ref([])
const carregando = ref(true)
const erro = ref('')

const formAberto = ref(false)
const usuarioEmEdicao = ref(null)

async function carregar() {
  carregando.value = true
  erro.value = ''
  try {
    const dados = await props.api.get('/nc/usuarios')
    usuarios.value = dados.itens
  } catch (e) {
    erro.value = e.message
  } finally {
    carregando.value = false
  }
}

function abrirNovo() {
  usuarioEmEdicao.value = null
  formAberto.value = true
}

function abrirEdicao(usuario) {
  usuarioEmEdicao.value = usuario
  formAberto.value = true
}

function aoSalvar() {
  formAberto.value = false
  carregar()
}

onMounted(carregar)
</script>

<template>
  <div class="d-flex justify-content-between align-items-center mb-3">
    <h5 class="mb-0">Usuários <span class="text-muted small fw-normal">({{ usuarios.length }})</span></h5>
    <button class="btn btn-success btn-sm" @click="abrirNovo">+ Novo usuário</button>
  </div>

  <p v-if="erro" class="text-danger small">{{ erro }}</p>
  <p v-if="carregando" class="text-muted">Carregando...</p>

  <div class="table-responsive" v-else>
    <table class="table table-sm table-hover align-middle">
      <thead>
        <tr class="small text-muted">
          <th>Nome</th>
          <th>E-mail</th>
          <th>Tipo</th>
          <th>Status</th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="usuario in usuarios" :key="usuario.id">
          <td>{{ usuario.nome }}</td>
          <td>{{ usuario.email }}</td>
          <td>{{ TIPO_LABEL[usuario.tipo] || usuario.tipo }}</td>
          <td>
            <span class="badge" :class="usuario.ativo ? 'bg-success' : 'bg-secondary'">
              {{ usuario.ativo ? 'Ativo' : 'Inativo' }}
            </span>
          </td>
          <td class="text-end">
            <button class="btn btn-outline-success btn-sm" @click="abrirEdicao(usuario)">Editar</button>
          </td>
        </tr>
        <tr v-if="!usuarios.length">
          <td colspan="5" class="text-muted text-center">Nenhum usuário encontrado.</td>
        </tr>
      </tbody>
    </table>
  </div>

  <AdminUsuarioForm
    v-if="formAberto"
    :api="api"
    :usuario="usuarioEmEdicao"
    @salvo="aoSalvar"
    @cancelar="formAberto = false"
  />
</template>
