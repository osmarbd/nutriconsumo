<script setup>
import { ref, watch } from 'vue'

const props = defineProps({
  api: { type: Object, required: true },
  usuario: { type: Object, default: null }, // null = criando; objeto = editando
})

const emit = defineEmits(['salvo', 'cancelar'])

const REGRA_SENHA = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,12}$/

function vazio() {
  return { nome: '', email: '', instituicao: '', tipo: 'user', ativo: true, senha: '', senhaConfirmacao: '' }
}

function apartirDe(usuario) {
  return {
    nome: usuario.nome,
    email: usuario.email,
    instituicao: usuario.instituicao || '',
    tipo: usuario.tipo,
    ativo: !!usuario.ativo,
    senha: '',
    senhaConfirmacao: '',
  }
}

const form = ref(props.usuario ? apartirDe(props.usuario) : vazio())
const erro = ref('')
const enviando = ref(false)

watch(
  () => props.usuario,
  (usuario) => {
    form.value = usuario ? apartirDe(usuario) : vazio()
    erro.value = ''
  }
)

const editando = () => props.usuario !== null

async function enviar() {
  erro.value = ''

  if (form.value.senha || !editando()) {
    if (!REGRA_SENHA.test(form.value.senha)) {
      erro.value = 'A senha deve ter de 8 a 12 caracteres, com ao menos uma letra maiúscula, uma minúscula, um número e um caractere especial.'
      return
    }
    if (form.value.senha !== form.value.senhaConfirmacao) {
      erro.value = 'As senhas não conferem.'
      return
    }
  }

  if (editando() && form.value.senha && !confirm('Confirma a troca da senha deste usuário? A senha atual deixará de funcionar imediatamente e ele precisará defini-la novamente no próximo acesso.')) {
    return
  }

  enviando.value = true
  try {
    let dados
    if (editando()) {
      const payload = { tipo: form.value.tipo, ativo: form.value.ativo }
      if (form.value.senha) payload.senha = form.value.senha
      dados = await props.api.put(`/nc/usuarios/${props.usuario.id}`, payload)
    } else {
      dados = await props.api.post('/nc/usuarios', {
        nome: form.value.nome,
        email: form.value.email,
        instituicao: form.value.instituicao || null,
        tipo: form.value.tipo,
        ativo: form.value.ativo,
        senha: form.value.senha,
      })
    }
    emit('salvo', dados.user)
  } catch (e) {
    erro.value = e.dados?.errors ? Object.values(e.dados.errors).flat().join(' ') : e.message
  } finally {
    enviando.value = false
  }
}
</script>

<template>
  <Teleport to="body">
    <div class="modal-backdrop-custom" @click.self="$emit('cancelar')">
      <div class="card shadow modal-card">
        <div class="card-body p-4">
          <h5 class="card-title mb-1">{{ editando() ? 'Editar usuário' : 'Novo usuário' }}</h5>
          <p v-if="editando()" class="text-muted small mb-3">{{ usuario.email }}</p>

          <form @submit.prevent="enviar">
            <template v-if="!editando()">
              <div class="mb-3">
                <label class="form-label">Nome</label>
                <input type="text" class="form-control" v-model="form.nome" required />
              </div>

              <div class="mb-3">
                <label class="form-label">E-mail</label>
                <input type="email" class="form-control" v-model="form.email" required />
              </div>

              <div class="mb-3">
                <label class="form-label">Instituição (opcional)</label>
                <input type="text" class="form-control" v-model="form.instituicao" />
              </div>
            </template>

            <div class="row g-2 mb-3">
              <div class="col-md-6">
                <label class="form-label">Tipo</label>
                <select class="form-select" v-model="form.tipo" required>
                  <option value="admin">Administrador</option>
                  <option value="user">Pesquisador</option>
                </select>
              </div>
              <div class="col-md-6 d-flex align-items-end">
                <div class="form-check">
                  <input type="checkbox" class="form-check-input" id="ativo" v-model="form.ativo" />
                  <label class="form-check-label" for="ativo">Ativo</label>
                </div>
              </div>
            </div>

            <div class="row g-2 mb-3">
              <div class="col-md-6">
                <label class="form-label">{{ editando() ? 'Nova senha (opcional)' : 'Senha' }}</label>
                <input type="password" class="form-control" v-model="form.senha" :required="!editando()" minlength="8" maxlength="12" autocomplete="new-password" />
              </div>
              <div class="col-md-6">
                <label class="form-label">Confirmação da senha</label>
                <input type="password" class="form-control" v-model="form.senhaConfirmacao" :required="!editando() || !!form.senha" minlength="8" maxlength="12" autocomplete="new-password" />
              </div>
            </div>
            <p class="form-text mt-n2 mb-3">8 a 12 caracteres, com maiúscula, minúscula, número e caractere especial. {{ editando() ? 'Ao definir uma senha, o usuário será obrigado a trocá-la no próximo acesso.' : 'O usuário será obrigado a trocá-la no primeiro acesso.' }}</p>

            <p v-if="erro" class="text-danger small">{{ erro }}</p>

            <div class="d-flex gap-2">
              <button type="submit" class="btn btn-success" :disabled="enviando">
                {{ enviando ? 'Aguarde...' : 'Salvar' }}
              </button>
              <button type="button" class="btn btn-outline-secondary" @click="$emit('cancelar')">Cancelar</button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.modal-backdrop-custom {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding: 3rem 1rem;
  overflow-y: auto;
  z-index: 1050;
}
.modal-card {
  width: 100%;
  max-width: 520px;
}
</style>
