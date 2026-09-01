<script setup>
import FormAlterarSenha from './FormAlterarSenha.vue'

// Vinculado via JS (não src literal) — vite.config.js deste projeto usa
// publicDir:false, mesmo gotcha documentado em Login.vue/Shell.vue.
const logoUrl = '/assets/img/NutriConsumo_transparente.png'

defineProps({
  api: { type: Object, required: true },
})

const emit = defineEmits(['alterada', 'sair'])
</script>

<template>
  <div class="d-flex align-items-center justify-content-center" style="min-height: 100%;">
    <div style="width: 100%; max-width: 480px;">
      <div class="text-center mb-3">
        <img :src="logoUrl" alt="NutriConsumo" style="max-width: 260px; width: 100%;" />
      </div>
      <div class="card shadow-sm">
        <div class="card-body p-4">
          <h4 class="card-title mb-3">Troca de senha obrigatória</h4>
          <p class="text-muted small">
            Você está usando uma senha padrão/temporária. Por segurança, defina uma nova senha para continuar.
          </p>

          <FormAlterarSenha :api="api" texto-botao="Definir nova senha" @alterada="emit('alterada', $event)" />

          <div class="text-center mt-3">
            <a href="javascript:void(0)" class="small text-muted" @click="emit('sair')">Sair</a>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
