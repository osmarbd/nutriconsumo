<script setup>
import { ref } from 'vue'

const props = defineProps({
  api: { type: Object, required: true },
})

// Vinculado via JS (não src literal) — vite.config.js deste projeto usa
// publicDir:false, então um src="/assets/..." literal no template seria
// transformado em import de módulo pelo @vitejs/plugin-vue e quebraria o
// build (mesmo gotcha já documentado em area_restrita_tbca/Shell.vue).
const logoUrl = '/assets/img/NutriConsumo_transparente.png'

const emit = defineEmits(['logado'])

const email = ref('')
const password = ref('')
const erro = ref('')
const enviando = ref(false)

async function enviar() {
  erro.value = ''
  enviando.value = true

  try {
    const dados = await props.api.post('/nc/auth/login', { email: email.value, password: password.value })
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
        <img :src="logoUrl" alt="NutriConsumo" style="max-width: 260px; width: 100%;" />
      </div>
      <div class="card shadow-sm">
        <div class="card-body p-4">
          <h4 class="card-title mb-3">Entrar</h4>

          <form @submit.prevent="enviar">
            <div class="mb-3">
              <label class="form-label">E-mail</label>
              <input type="email" class="form-control" v-model="email" required />
            </div>

            <div class="mb-3">
              <label class="form-label">Senha</label>
              <input type="password" class="form-control" v-model="password" required />
            </div>

            <p v-if="erro" class="text-danger small">{{ erro }}</p>

            <button type="submit" class="btn btn-success w-100" :disabled="enviando">
              {{ enviando ? 'Aguarde...' : 'Entrar' }}
            </button>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>
