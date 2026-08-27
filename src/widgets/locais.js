// Lista fixa de locais de refeição (alinhada com a nutricionista) + "outro"
// como válvula de escape — mesmos valores do ENUM `t_nc_ocasioes.local`.
export const LOCAIS = [
  { value: 'casa', label: 'Casa' },
  { value: 'casa_de_outra_pessoa', label: 'Casa de outra pessoa' },
  { value: 'trabalho', label: 'Trabalho' },
  { value: 'escola', label: 'Escola' },
  { value: 'creche', label: 'Creche' },
  { value: 'restaurante', label: 'Restaurante/lanchonete' },
  { value: 'rua_ambulante', label: 'Rua/ambulante' },
  { value: 'outro', label: 'Outro' },
]

// Opções sugeridas pro campo "Ocasião" (em ordem alfabética) — a coluna
// `t_nc_ocasioes.descricao` continua um VARCHAR livre no banco (a
// nutricionista foi explícita que isso não deve ser uma categoria fixa),
// esta lista é só uma ajuda na tela; "Outro" libera texto livre pra
// qualquer ocasião fora dessas.
export const OCASIOES = ['Almoço', 'Bebida', 'Café da Manhã', 'Jantar', 'Lanche', 'Outro']

export function rotuloLocal(ocasiao) {
  if (ocasiao.local === 'outro' && ocasiao.local_outro) return ocasiao.local_outro
  return LOCAIS.find((l) => l.value === ocasiao.local)?.label ?? ocasiao.local
}

// MySQL devolve TIME como "HH:MM:SS" — a tela só precisa de "HH:MM".
export function formatarHorario(horario) {
  return (horario || '').slice(0, 5)
}
