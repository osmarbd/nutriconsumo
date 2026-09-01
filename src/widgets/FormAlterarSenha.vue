<script setup>
import { ref } from 'vue'

const props = defineProps({
  api: { type: Object, required: true },
  textoBotao: { type: String, default: 'Salvar nova senha' },
})

const emit = defineEmits(['alterada'])

const REGRA_SENHA = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,12}$/

const senhaAtual = ref('')
const senhaNova = ref('')
const senhaNovaConfirmacao = ref('')
const erro = ref('')
const sucesso = ref('')
const enviando = ref(false)

function validarLocalmente() {
  if (!REGRA_SENHA.test(senhaNova.value)) {
    return 'A nova senha deve ter de 8 a 12 caracteres, com ao menos uma letra maiúscula, uma minúscula, um número e um caractere especial.'
  }
  if (senhaNova.value !== senhaNovaConfirmacao.value) {
    return 'A confirmação não confere com a nova senha.'
  }
  return ''
}

async function enviar() {
  erro.value = ''
  sucesso.value = ''

  const erroLocal = validarLocalmente()
  if (erroLocal) {
    erro.value = erroLocal
    return
  }

  enviando.value = true
  try {
    const dados = await props.api.put('/nc/auth/senha', {
      senha_atual: senhaAtual.value,
      senha_nova: senhaNova.value,
      senha_nova_confirmacao: senhaNovaConfirmacao.value,
    })

    sucesso.value = 'Senha alterada com sucesso.'
    senhaAtual.value = ''
    senhaNova.value = ''
    senhaNovaConfirmacao.value = ''
    emit('alterada', dados.user)
  } catch (e) {
    erro.value = e.dados?.errors ? Object.values(e.dados.errors).flat().join(' ') : e.message
  } finally {
    enviando.value = false
  }
}
</script>

<template>
  <form @submit.prevent="enviar">
    <div class="mb-3">
      <label class="form-label">Senha atual</label>
      <input type="password" class="form-control" v-model="senhaAtual" required autocomplete="current-password" />
    </div>

    <div class="mb-3">
      <label class="form-label">Nova senha</label>
      <input type="password" class="form-control" v-model="senhaNova" required minlength="8" maxlength="12" autocomplete="new-password" />
      <div class="form-text">8 a 12 caracteres, com maiúscula, minúscula, número e caractere especial.</div>
    </div>

    <div class="mb-3">
      <label class="form-label">Confirmação da nova senha</label>
      <input type="password" class="form-control" v-model="senhaNovaConfirmacao" required minlength="8" maxlength="12" autocomplete="new-password" />
    </div>

    <p v-if="erro" class="text-danger small">{{ erro }}</p>
    <p v-if="sucesso" class="text-success small">{{ sucesso }}</p>

    <button type="submit" class="btn btn-success" :disabled="enviando">
      {{ enviando ? 'Aguarde...' : textoBotao }}
    </button>
  </form>
</template>
