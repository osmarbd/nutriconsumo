# NutriConsumo

Ferramenta para pesquisadores aplicarem recordatórios alimentares de 24 horas
(R24H) — até 3 dias por entrevistado, num fluxo guiado em 5 passos (lista
rápida → revisão da lista → detalhamento → matching → revisão final), com
cadastro de alimentos personalizados quando o alimento citado não existe na
base TBCA. Mesma arquitetura de `portal_tbca`/`portal_latinfoods`: front PHP
MVC sem framework (`public/index.php`) + widgets Vue 3 (Vite), consumindo a
API central `apitbca`.

## Rodando em desenvolvimento

```bash
# 1. apitbca (se ainda não estiver rodando)
cd ../apitbca
composer install
php -S 127.0.0.1:8000 -t public

# 2. nutriconsumo
cd nutriconsumo
npm install
npm run build      # gera public/dist/app.js (rode de novo a cada mudança nos .vue/.js)
php -S 127.0.0.1:8092 -t public public/router.php
```

Acesse `http://127.0.0.1:8092`. O `.env` de `apitbca` já inclui
`http://localhost:8092`/`http://127.0.0.1:8092` em `CORS_ALLOWED_ORIGIN`.

Para desenvolvimento do front com hot-reload dos componentes Vue, `npm run dev`
também funciona (Vite sobe em outra porta só para os assets), mas o fluxo mais
simples aqui é `npm run build` + recarregar a página, igual ao `portal_latinfoods`.

## Autenticação

Login próprio do NutriConsumo, tabela `t_nc_users` (JWT via
`POST /api/nc/auth/login` / `/api/nc/auth/register` em `apitbca`) — não usa a
tabela `users` genérica nem qualquer login da TBCA. O token fica em
`localStorage` (`nc_token`) e é reaproveitado enquanto for válido
(`JWT_TTL` do `apitbca`, hoje 1h).

## Modelo de dados (tabelas `t_nc_*`, ver `database/nc_schema.sql`)

Todas criadas na mesma base MySQL usada por `apitbca`, para poder referenciar
por FK as tabelas compartilhadas `grupos`, `tipo_alimentos`, `br_t_nut_conf` e
`br_t_alimentos` sem duplicá-las. Os dados da própria TBCA
(`br_t_alimentos`/`br_t_nutrientes`) não são alterados por este projeto.

- **`t_nc_users`** — pesquisadores (nome, e-mail, senha com hash, instituição opcional).
- **`t_nc_entrevistados`** — cadastro próprio de entrevistados por pesquisador (nome,
  data de nascimento, `codigo` gerado no formato `ENTV` + id).
- **`t_nc_alimentos`** — alimentos personalizados cadastrados por um pesquisador
  (fica associado ao `user_id` que criou — não é um catálogo global). Referencia
  `grupos`/`tipo_alimentos` para manter a mesma classificação da TBCA. Cada um
  recebe um `codigo` próprio gerado pelo sistema (`PZ` + id, ex. `PZ000007`) —
  só aparece em endpoints já filtrados por `user_id`, então nunca é visível a
  outro pesquisador.
- **`t_nc_nutrientes`** — valores nutricionais (por 100 g, mesma convenção da
  TBCA) de um alimento personalizado, um por `br_t_nut_conf` (nutriente). Aceita
  os códigos-sentinela do Nutrireceitas (`tr`/`NA`/`-`/`ND`/`N/A`/`SI`/`DA` →
  `-1`..`-7`, ver `tbca2/CLAUDE.md`) em vez de um valor numérico real.
- **`t_nc_recordatorios`** — cabeçalho de um recordatório (um dia): entrevistado,
  data, número sequencial (1..30, automático por entrevistador — ver abaixo) e
  a etapa atual do wizard.
- **`t_nc_ocasioes`** — ocasiões de consumo dentro de um recordatório (horário,
  descrição livre, local).
- **`t_nc_itens_consumidos`** — alimentos/bebidas citados numa ocasião. Nasce
  "rápido" (só nome livre) e é "detalhado" no passo de Matching: liga na TBCA
  ou num alimento personalizado, define quantidade (g/ml, digitada ou via
  medida padrão de `br_t_medidas_padrao`) e exige origem + referência fotográfica.

O número do recordatório (`numero_recordatorio`) é gerado automaticamente pelo
backend — não é escolhido pelo pesquisador — como uma sequência 1..30 por
entrevistador (soma todos os entrevistados dele), com aviso na UI a partir do
25º e bloqueio no 30º (`NcRecordatorioController::criar`,
`NcRecordatorio::LIMITE_POR_ENTREVISTADOR`).

O total nutricional de cada recordatório **não é armazenado** — é recalculado
a cada consulta (`GET /api/nc/recordatorios/{id}`) somando, por nutriente, o
valor de cada item já detalhado, escalado pela quantidade real informada (sem
normalizar para 100g). Quando um ou mais itens têm um código-sentinela em vez
de valor numérico para aquele nutriente, o total segue a regra de precedência
do Nutrireceitas: número (soma normalmente, ignora os demais) > `tr` (se não
houver número) > demais símbolos (se todos forem o mesmo, repete; se
misturados, vira `-`). Ver `apitbca/src/Models/NcRecordatorio.php::totalNutricional()`.

## Endpoints (`apitbca`, prefixo `/api/nc`)

Todos atrás de `AuthMiddleware` (JWT), exceto `auth/register` e `auth/login`.

- `POST /auth/register`, `POST /auth/login`, `GET /auth/me`, `POST /auth/logout`
- `GET /referencias` — grupos, tipos de alimento, nutrientes e medidas padrão (para popular selects)
- `GET /alimentos/tbca?q=&grupo_id=&tipo_alimento_id=&pagina=&por_pagina=` — busca na base TBCA
- `GET /alimentos/tbca/{cod}/nutrientes` — composição de um alimento da TBCA
- `GET /alimentos/personalizados` / `POST /alimentos/personalizados` / `GET|PUT|DELETE /alimentos/personalizados/{id}` — CRUD dos alimentos próprios do usuário logado
- `GET /entrevistados` / `POST /entrevistados` — cadastro de entrevistados do pesquisador
- `GET /recordatorios` / `POST /recordatorios` / `GET|DELETE /recordatorios/{id}` — recordatórios do usuário logado
- `PUT /recordatorios/{id}/etapa` — avança/retrocede o wizard
- `POST /recordatorios/{id}/ocasioes` / `DELETE /recordatorios/{id}/ocasioes/{ocasiaoId}` — ocasiões
- `POST /recordatorios/{id}/ocasioes/{ocasiaoId}/itens` / `PUT|DELETE /recordatorios/{id}/itens/{itemId}` — itens (lista rápida)
- `PUT /recordatorios/{id}/itens/{itemId}/detalhar` — matching (liga o item a um alimento + quantidade)

## Próximos passos (não implementados ainda)

- Edição de um alimento personalizado já cadastrado direto da tela de Matching
  (o endpoint `PUT /alimentos/personalizados/{id}` já existe, só falta o form no front).
- Excel export (PDF já existe na Revisão Final).
- Paginação da busca na base TBCA (hoje só traz os 20 primeiros resultados).
