const TOKEN_KEY = 'nc_token'

function tokenAtual() {
  return localStorage.getItem(TOKEN_KEY)
}

async function request(apiBase, path, options = {}) {
  const headers = { 'Content-Type': 'application/json', ...(options.headers || {}) }
  const token = tokenAtual()
  if (token) headers['Authorization'] = `Bearer ${token}`

  const resposta = await fetch(`${apiBase}${path}`, { ...options, headers })
  const dados = await resposta.json().catch(() => ({}))

  if (!resposta.ok) {
    const erro = new Error(dados.message || 'Erro na requisição.')
    erro.status = resposta.status
    erro.dados = dados
    throw erro
  }

  return dados
}

export function criarApi(apiBase) {
  return {
    get: (path) => request(apiBase, path),
    post: (path, body) => request(apiBase, path, { method: 'POST', body: JSON.stringify(body) }),
    put: (path, body) => request(apiBase, path, { method: 'PUT', body: JSON.stringify(body) }),
    delete: (path) => request(apiBase, path, { method: 'DELETE' }),
  }
}

export function salvarToken(token) {
  localStorage.setItem(TOKEN_KEY, token)
}

export function limparToken() {
  localStorage.removeItem(TOKEN_KEY)
}

export function temToken() {
  return !!tokenAtual()
}
