import { createApp } from 'vue'
import App from './App.vue'

const el = document.getElementById('nc-app')

if (el) {
  createApp(App, {
    apiBase: el.dataset.apiBase,
  }).mount(el)
}
