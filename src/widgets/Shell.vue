<script setup>
import { ref, computed } from 'vue'
import { iniciais } from './utils.js'

const props = defineProps({
  usuario: { type: Object, required: true },
  secaoAtiva: { type: String, required: true },
})

const emit = defineEmits(['navegar', 'sair'])

const ehAdmin = computed(() => props.usuario.tipo === 'admin')

const MENU = computed(() => [
  { chave: 'inicio', label: 'Início', icone: 'bi-house-door' },
  { chave: 'recordatorios', label: 'Recordatórios alimentares', icone: 'bi-clipboard2-pulse' },
  { chave: 'entrevistados', label: 'Entrevistados', icone: 'bi-people' },
  ...(ehAdmin.value
    ? [
        {
          label: 'Administração',
          icone: 'bi-gear',
          submenu: [{ chave: 'usuarios', label: 'Usuários' }],
        },
      ]
    : []),
])

function achar(chave, itens = MENU.value) {
  for (const item of itens) {
    if (item.chave === chave) return item
    if (item.submenu) {
      const encontrado = item.submenu.find((sub) => sub.chave === chave)
      if (encontrado) return encontrado
    }
  }
  return null
}

const tituloSecao = computed(() => achar(props.secaoAtiva)?.label ?? '')

// Grupos com submenu abrem sozinhos quando a seção ativa é um dos filhos, e
// também podem ser abertos/fechados manualmente clicando no cabeçalho.
const abertos = ref(new Set())

function grupoAberto(item) {
  return abertos.value.has(item.label) || (item.submenu?.some((sub) => sub.chave === props.secaoAtiva) ?? false)
}

function alternarGrupo(item) {
  const novo = new Set(abertos.value)
  if (grupoAberto(item)) {
    novo.delete(item.label)
  } else {
    novo.add(item.label)
  }
  abertos.value = novo
}

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
        <template v-for="item in MENU" :key="item.chave || item.label">
          <a
            v-if="!item.submenu"
            href="javascript:void(0)"
            class="nav-link d-flex align-items-center gap-2"
            :class="{ active: secaoAtiva === item.chave }"
            @click="emit('navegar', item.chave)"
          >
            <i class="bi" :class="item.icone"></i> {{ item.label }}
          </a>

          <template v-else>
            <a
              href="javascript:void(0)"
              class="nav-link d-flex align-items-center gap-2"
              @click="alternarGrupo(item)"
            >
              <i class="bi" :class="item.icone"></i> {{ item.label }}
              <i class="bi ms-auto small" :class="grupoAberto(item) ? 'bi-chevron-down' : 'bi-chevron-right'"></i>
            </a>
            <div v-show="grupoAberto(item)" class="nc-submenu">
              <a
                v-for="sub in item.submenu"
                :key="sub.chave"
                href="javascript:void(0)"
                class="nav-link d-flex align-items-center gap-2"
                :class="{ active: secaoAtiva === sub.chave }"
                @click="emit('navegar', sub.chave)"
              >
                {{ sub.label }}
              </a>
            </div>
          </template>
        </template>
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
            <li>
              <a
                class="dropdown-item"
                href="javascript:void(0)"
                :class="{ active: secaoAtiva === 'configuracoes' }"
                @click="emit('navegar', 'configuracoes')"
              >
                <i class="bi bi-gear-wide-connected me-2"></i>Configurações
              </a>
            </li>
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

.nc-submenu .nav-link {
  padding-left: 2.75rem;
  font-size: 0.9rem;
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
