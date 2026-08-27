<script setup>
import { ref } from 'vue'
import { rotuloLocal, formatarHorario } from './locais.js'

const props = defineProps({
  api: { type: Object, required: true },
  recordatorioId: { type: [Number, String], required: true },
  recordatorio: { type: Object, required: true },
  ocasioes: { type: Array, required: true },
  nutrientes: { type: Array, required: true },
  finalizado: { type: Boolean, default: false },
  totalItens: { type: Number, required: true },
})

defineEmits(['finalizar'])

// Número em pt-BR (2 casas, Energia sem decimais), símbolo especial
// (tr/NA/-/ND/N/A/SI/DA) fica como está.
function formatarValor(valor, unidade) {
  if (typeof valor !== 'number') return valor
  const ehEnergia = ['kj', 'kcal'].includes((unidade || '').toLowerCase())
  return valor.toLocaleString('pt-BR', { maximumFractionDigits: ehEnergia ? 0 : 2 })
}

// Gerado 100% no navegador (jsPDF), sem ida ao servidor — os dados já estão
// todos carregados nesta tela. Segue a mesma regra do resto do recordatório:
// quantidades exatas informadas, total só deste dia, nunca somado com os
// outros recordatórios do mesmo entrevistado.
// jsPDF arrasta html2canvas/dompurify (~400 kB) mesmo sem usar suporte a
// HTML/imagem — import dinâmico pra não inchar o bundle inicial da SPA só
// por causa de um botão que a maioria das sessões nunca clica.
const exportando = ref(false)

async function exportarPdf() {
  exportando.value = true
  try {
    await gerarPdf()
  } finally {
    exportando.value = false
  }
}

async function gerarPdf() {
  const [{ default: jsPDF }, { default: autoTable }] = await Promise.all([
    import('jspdf'),
    import('jspdf-autotable'),
  ])

  const doc = new jsPDF()
  const r = props.recordatorio
  const margem = 14
  let y = 16

  doc.setFontSize(14)
  doc.text('Recordatório alimentar (R24H)', margem, y)
  y += 8

  doc.setFontSize(10)
  doc.text(
    `Entrevistador: ${r.entrevistador_codigo}    Entrevistado: ${r.entrevistado_codigo}    ` +
      `Data: ${r.data_entrevista}    Recordatório nº: ${r.numero_recordatorio}`,
    margem,
    y
  )
  y += 8

  for (const ocasiao of props.ocasioes) {
    doc.setFontSize(11)
    doc.text(
      `${formatarHorario(ocasiao.horario)} — ${ocasiao.descricao} (${rotuloLocal(ocasiao)})`,
      margem,
      y
    )

    autoTable(doc, {
      startY: y + 3,
      margin: { left: margem, right: margem },
      styles: { fontSize: 8 },
      headStyles: { fillColor: [25, 135, 84] },
      head: [['Alimento', 'Quantidade', 'Origem', 'Referência', 'Observação']],
      body: ocasiao.itens.map((item) => [
        item.nome_alimento || item.nome_livre,
        item.quantidade != null ? `${item.quantidade}${item.unidade}` : '—',
        item.origem_alimento || '—',
        item.referencia_fotografica || '—',
        item.observacao || '',
      ]),
    })

    y = doc.lastAutoTable.finalY + 8
  }

  doc.setFontSize(11)
  doc.text('Total nutricional do dia', margem, y)

  autoTable(doc, {
    startY: y + 3,
    margin: { left: margem, right: margem },
    styles: { fontSize: 8 },
    headStyles: { fillColor: [25, 135, 84] },
    head: [['Nutriente', 'Total']],
    body: props.nutrientes.map((linha) => [
      `${linha.nutriente} (${linha.unidade})`,
      String(formatarValor(linha.total, linha.unidade)),
    ]),
  })

  doc.save(`recordatorio_${r.entrevistado_codigo}_${r.numero_recordatorio}_${r.data_entrevista}.pdf`)
}
</script>

<template>
  <div>
    <p class="text-muted small">
      Quantidades exibidas são exatamente as informadas (g/ml), sem normalizar para 100g. Este total é só deste
      recordatório (um dia) — nunca somado com os outros dias do mesmo entrevistado.
    </p>

    <div class="alert alert-warning small" v-if="!totalItens">
      Nenhum alimento registrado ainda — volte aos passos anteriores antes de finalizar.
    </div>

    <div class="card shadow-sm mb-3" v-for="ocasiao in ocasioes" :key="ocasiao.id">
      <div class="card-body">
        <h6 class="card-title">{{ formatarHorario(ocasiao.horario) }} — {{ ocasiao.descricao }} <span class="badge bg-light text-dark">{{ rotuloLocal(ocasiao) }}</span></h6>
        <table class="table table-sm mb-0">
          <thead>
            <tr class="small text-muted">
              <th>Alimento</th>
              <th>Quantidade</th>
              <th>Origem</th>
              <th>Referência</th>
              <th>Observação</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in ocasiao.itens" :key="item.id">
              <td>
                {{ item.nome_alimento || item.nome_livre }}
                <span class="badge bg-secondary ms-1" v-if="item.alimento_cod">{{ item.alimento_cod }}</span>
              </td>
              <td>{{ item.quantidade }}{{ item.unidade }}</td>
              <td>{{ item.origem_alimento }}</td>
              <td>{{ item.referencia_fotografica }}</td>
              <td class="text-muted">{{ item.observacao }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <div class="card shadow-sm mb-3">
      <div class="card-body">
        <h6 class="card-title">Total nutricional do dia</h6>
        <div class="table-responsive">
          <table class="table table-sm table-bordered mb-0">
            <thead class="table-light">
              <tr>
                <th>Nutriente</th>
                <th>Total</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="linha in nutrientes" :key="linha.nutri_conf_id">
                <td>{{ linha.nutriente }} <span class="text-muted small">({{ linha.unidade }})</span></td>
                <td class="fw-semibold">{{ formatarValor(linha.total, linha.unidade) }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <div class="d-flex justify-content-end gap-2 mt-3">
      <button class="btn btn-outline-secondary" :disabled="exportando" @click="exportarPdf">
        {{ exportando ? 'Gerando PDF...' : 'Exportar PDF' }}
      </button>
      <span v-if="finalizado" class="badge bg-success align-self-center fs-6">Recordatório finalizado</span>
      <button v-else class="btn btn-success" :disabled="!totalItens" @click="$emit('finalizar')">
        Finalizar recordatório
      </button>
    </div>
  </div>
</template>
