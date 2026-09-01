<script setup>
import { ref } from 'vue'
import Shell from './Shell.vue'
import RecordatorioList from './RecordatorioList.vue'
import EntrevistadoList from './EntrevistadoList.vue'
import Configuracoes from './Configuracoes.vue'
import AdminUsuarios from './AdminUsuarios.vue'

const props = defineProps({
  api: { type: Object, required: true },
  usuario: { type: Object, required: true },
})

defineEmits(['sair'])

const secaoAtiva = ref('inicio') // 'inicio' | 'recordatorios' | 'entrevistados' | 'configuracoes' | 'usuarios'

// Vinculado via JS (não como src literal no template) porque o vite.config.js
// deste projeto usa publicDir:false — um src="/assets/..." literal seria
// transformado em import de módulo pelo @vitejs/plugin-vue em tempo de
// build, e o Rollup não consegue resolver esse caminho (mesmo gotcha já
// documentado em area_restrita_tbca).
const logoUrl = '/assets/img/NutriConsumo.png'
</script>

<template>
  <Shell :usuario="usuario" :secao-ativa="secaoAtiva" @navegar="secaoAtiva = $event" @sair="$emit('sair')">
    <div class="card shadow-sm" v-if="secaoAtiva === 'inicio'">
      <div class="card-body text-center py-5">
        <img :src="logoUrl" alt="NutriConsumo" style="max-width: 420px; width: 100%;" class="mb-4" />
        <p class="text-muted mb-0">Olá, {{ usuario.nome }}! Use o menu à esquerda para registrar recordatórios alimentares ou gerenciar entrevistados.</p>
      </div>
    </div>

    <RecordatorioList v-else-if="secaoAtiva === 'recordatorios'" :api="api" :usuario="usuario" />

    <EntrevistadoList v-else-if="secaoAtiva === 'entrevistados'" :api="api" />

    <Configuracoes v-else-if="secaoAtiva === 'configuracoes'" :api="api" :usuario="usuario" />

    <AdminUsuarios v-else-if="secaoAtiva === 'usuarios'" :api="api" />
  </Shell>
</template>
