<script setup>
import FormAlterarSenha from './FormAlterarSenha.vue'

defineProps({
  api: { type: Object, required: true },
  usuario: { type: Object, required: true },
})

const TIPO_LABEL = {
  admin: 'Administrador',
  user: 'Pesquisador',
}
</script>

<template>
  <div class="row g-3">
    <div class="col-lg-6">
      <div class="card shadow-sm">
        <div class="card-body">
          <h5 class="card-title mb-3">Meus dados</h5>

          <dl class="row mb-0">
            <dt class="col-sm-4 text-muted fw-normal">Nome</dt>
            <dd class="col-sm-8">{{ usuario.nome }}</dd>

            <dt class="col-sm-4 text-muted fw-normal">E-mail</dt>
            <dd class="col-sm-8">{{ usuario.email }}</dd>

            <dt class="col-sm-4 text-muted fw-normal">Tipo</dt>
            <dd class="col-sm-8">{{ TIPO_LABEL[usuario.tipo] || usuario.tipo }}</dd>

            <dt class="col-sm-4 text-muted fw-normal">Status</dt>
            <dd class="col-sm-8">
              <span class="badge" :class="usuario.ativo ? 'bg-success' : 'bg-secondary'">
                {{ usuario.ativo ? 'Ativo' : 'Inativo' }}
              </span>
            </dd>

            <dt class="col-sm-4 text-muted fw-normal">Cadastrado em</dt>
            <dd class="col-sm-8 mb-0">{{ usuario.created_at }}</dd>
          </dl>
        </div>
      </div>
    </div>

    <div class="col-lg-6">
      <div class="card shadow-sm">
        <div class="card-body">
          <h5 class="card-title mb-3">Alterar senha</h5>
          <FormAlterarSenha :api="api" />
        </div>
      </div>
    </div>
  </div>
</template>
