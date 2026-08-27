<script setup>
import { ref } from 'vue'

const props = defineProps({
  api: { type: Object, required: true },
})

const emit = defineEmits(['logado'])

const modo = ref('login')
const nome = ref('')
const email = ref('')
const password = ref('')
const instituicao = ref('')
const erro = ref('')
const enviando = ref(false)

function alternarModo() {
  modo.value = modo.value === 'login' ? 'register' : 'login'
  erro.value = ''
}

async function enviar() {
  erro.value = ''
  enviando.value = true

  try {
    const payload = modo.value === 'login'
      ? { email: email.value, password: password.value }
      : { nome: nome.value, email: email.value, password: password.value, instituicao: instituicao.value || null }

    const dados = await props.api.post(`/nc/auth/${modo.value === 'login' ? 'login' : 'register'}`, payload)
    emit('logado', dados)
  } catch (e) {
    erro.value = e.dados?.errors
      ? Object.values(e.dados.errors).flat().join(' ')
      : e.message
  } finally {
    enviando.value = false
  }
}
</script>

<template>
  <div class="d-flex align-items-center justify-content-center" style="min-height: 100%;">
    <div style="width: 100%; max-width: 420px;">
      <div class="text-center mb-3">
        <i class="bi bi-basket2-fill" style="font-size: 2.5rem; color: #198754;"></i>
        <h4 class="fw-semibold mt-1">NutriConsumo</h4>
      </div>
      <div class="card shadow-sm">
        <div class="card-body p-4">
          <h4 class="card-title mb-3">{{ modo === 'login' ? 'Entrar' : 'Criar conta' }}</h4>

          <form @submit.prevent="enviar">
            <div class="mb-3" v-if="modo === 'register'">
              <label class="form-label">Nome</label>
              <input type="text" class="form-control" v-model="nome" required />
            </div>

            <div class="mb-3">
              <label class="form-label">E-mail</label>
              <input type="email" class="form-control" v-model="email" required />
            </div>

            <div class="mb-3">
              <label class="form-label">Senha</label>
              <input type="password" class="form-control" v-model="password" required minlength="6" />
            </div>

            <div class="mb-3" v-if="modo === 'register'">
              <label class="form-label">Instituição (opcional)</label>
              <input type="text" class="form-control" v-model="instituicao" />
            </div>

            <p v-if="erro" class="text-danger small">{{ erro }}</p>

            <button type="submit" class="btn btn-success w-100" :disabled="enviando">
              {{ enviando ? 'Aguarde...' : (modo === 'login' ? 'Entrar' : 'Cadastrar') }}
            </button>
          </form>

          <div class="text-center mt-3">
            <a href="javascript:void(0)" @click="alternarModo">
              {{ modo === 'login' ? 'Não tem conta? Cadastre-se' : 'Já tem conta? Entrar' }}
            </a>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
