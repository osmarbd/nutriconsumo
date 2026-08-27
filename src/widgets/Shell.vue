<script setup>
import { computed } from 'vue'
import { iniciais } from './utils.js'

const props = defineProps({
  usuario: { type: Object, required: true },
  secaoAtiva: { type: String, required: true },
})

const emit = defineEmits(['navegar', 'sair'])

const MENU = [
  { chave: 'inicio', label: 'Início', icone: 'bi-house-door' },
  { chave: 'recordatorios', label: 'Recordatórios alimentares', icone: 'bi-clipboard2-pulse' },
  { chave: 'entrevistados', label: 'Entrevistados', icone: 'bi-people' },
]

const tituloSecao = computed(() => MENU.find((item) => item.chave === props.secaoAtiva)?.label ?? '')

// Vinculado via JS (não src literal) — vite.config.js deste projeto usa
// publicDir:false, então um src="/assets/..." literal no template seria
// transformado em import de módulo pelo @vitejs/plugin-vue e quebraria o
// build (mesmo gotcha já documentado em area_restrita_tbca/Dashboard.vue).
const logoUrl = '/assets/img/NutriConsumo_sidebar.png'
</script>

<template>
  <div class="nc-shell d-flex">
    <aside class="nc-sidebar d-flex flex-column">
      <div class="nc-brand">
        <img :src="logoUrl" alt="NutriConsumo" class="nc-brand-logo" />
      </div>

      <div class="nc-user-panel d-flex align-items-center gap-2">
        <div class="nc-avatar">{{ iniciais(usuario.nome) }}</div>
        <div class="overflow-hidden">
          <div class="text-truncate small fw-semibold">{{ usuario.nome }}</div>
          <div class="text-truncate small text-white-50">{{ usuario.email }}</div>
        </div>
      </div>

      <nav class="nav flex-column nc-nav">
        <a
          v-for="item in MENU"
          :key="item.chave"
          href="javascript:void(0)"
          class="nav-link d-flex align-items-center gap-2"
          :class="{ active: secaoAtiva === item.chave }"
          @click="emit('navegar', item.chave)"
        >
          <i class="bi" :class="item.icone"></i> {{ item.label }}
        </a>
      </nav>
    </aside>

    <div class="nc-main d-flex flex-column">
      <header class="nc-topbar d-flex justify-content-between align-items-center">
        <h5 class="mb-0">{{ tituloSecao }}</h5>

        <div class="dropdown">
          <button class="btn btn-link text-decoration-none text-dark d-flex align-items-center gap-2" type="button" data-bs-toggle="dropdown">
            <div class="nc-avatar nc-avatar-sm">{{ iniciais(usuario.nome) }}</div>
            <span class="d-none d-sm-inline">{{ usuario.nome }}</span>
          </button>
          <ul class="dropdown-menu dropdown-menu-end">
            <li><span class="dropdown-item-text text-muted small">{{ usuario.email }}</span></li>
            <li><hr class="dropdown-divider" /></li>
            <li><a class="dropdown-item" href="javascript:void(0)" @click="emit('sair')">Sair</a></li>
          </ul>
        </div>
      </header>

      <main class="nc-content flex-grow-1">
        <slot />
      </main>
    </div>
  </div>
</template>

<style scoped>
.nc-shell {
  height: 100%;
}

.nc-sidebar {
  width: 250px;
  min-width: 250px;
  background-color: #163b2c;
  color: #fff;
}

.nc-brand {
  padding: 1rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.nc-brand-logo {
  display: block;
  width: 100%;
  height: auto;
}

.nc-user-panel {
  padding: 1rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.nc-nav {
  padding: 0.5rem 0;
  overflow-y: auto;
}

.nc-nav .nav-link {
  color: rgba(255, 255, 255, 0.75);
  padding: 0.65rem 1rem;
  border-left: 3px solid transparent;
}

.nc-nav .nav-link:hover {
  color: #fff;
  background-color: rgba(255, 255, 255, 0.08);
}

.nc-nav .nav-link.active {
  color: #fff;
  background-color: rgba(255, 255, 255, 0.12);
  border-left-color: #7ce38b;
}

.nc-avatar {
  width: 40px;
  height: 40px;
  min-width: 40px;
  border-radius: 50%;
  background-color: #2e7d4f;
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 0.9rem;
}

.nc-avatar-sm {
  width: 32px;
  height: 32px;
  min-width: 32px;
  font-size: 0.8rem;
}

.nc-main {
  flex: 1;
  min-width: 0;
}

.nc-topbar {
  background-color: #fff;
  border-bottom: 1px solid #dee2e6;
  padding: 0.75rem 1.5rem;
}

.nc-content {
  overflow-y: auto;
  padding: 1.5rem;
}
</style>
