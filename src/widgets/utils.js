// Iniciais pro avatar do usuário (sem foto): "Osmar Betazzi Dordal" -> "OD"
// (primeira letra do primeiro nome + primeira letra do último, ignora nomes
// do meio); nome de uma palavra só -> primeiras 2 letras.
export function iniciais(nome) {
  const partes = (nome || '').trim().split(/\s+/).filter(Boolean)

  if (partes.length === 0) return '?'
  if (partes.length === 1) return partes[0].slice(0, 2).toUpperCase()

  return (partes[0][0] + partes[partes.length - 1][0]).toUpperCase()
}
