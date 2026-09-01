-- NutriConsumo — tabelas novas (prefixo t_nc_), criadas na mesma base MySQL
-- `tbca2` (127.0.0.1:3307) usada por apitbca/portal_tbca/portal_latinfoods.
-- Ficam na mesma base (em vez de um banco próprio) para poder referenciar via
-- FK as tabelas compartilhadas `grupos`, `tipo_alimentos` e `br_t_nut_conf`,
-- sem duplicar esses cadastros. Os dados da TBCA (br_t_alimentos/br_t_nutrientes)
-- não são alterados por este projeto — apenas lidos.

-- `tipo`/`ativo`/`deve_trocar_senha` adicionados em 2026-09-01 (mesmo padrão
-- de br_t_users/t_lf_users): 'admin' acessa Administração > Usuários
-- (NcUsuariosController, atrás de NcAdminMiddleware) pra ativar/desativar
-- pesquisadores e resetar senha; 'user' é o pesquisador comum (cadastro
-- público via NcAuthController::register continua existindo, só não define
-- tipo/ativo/deve_trocar_senha explicitamente — usa os DEFAULT). Um reset
-- administrativo de senha sempre marca deve_trocar_senha=1 (ver
-- NcUser::atualizarSenha), forçando a troca no próximo login via
-- TrocarSenhaObrigatoria.vue; a troca feita pelo próprio usuário
-- (NcUser::atualizarSenhaPropria) sempre zera a flag de novo.
CREATE TABLE IF NOT EXISTS t_nc_users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nome VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL,
  password VARCHAR(255) NOT NULL,
  tipo ENUM('admin','user') NOT NULL DEFAULT 'user',
  ativo TINYINT(1) NOT NULL DEFAULT 1,
  deve_trocar_senha TINYINT(1) NOT NULL DEFAULT 0,
  instituicao VARCHAR(150) NULL,
  created_at DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_t_nc_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Alimentos personalizados, cadastrados pelo próprio pesquisador quando não
-- encontra o alimento na base TBCA. Reusa `grupos`/`tipo_alimentos` (mesmas
-- tabelas de referência da TBCA) só para manter a classificação consistente
-- entre os dois catálogos — não significa que o alimento "pertence" à TBCA.
-- `codigo` é gerado pela própria aplicação após o INSERT (formato `PZ` +
-- id com zero-padding, ver NcAlimento::criarPersonalizado) — não é digitado
-- pelo pesquisador. Só aparece nas respostas de endpoints já filtrados por
-- `user_id` (o dono), então nunca é visível a outro usuário.
CREATE TABLE IF NOT EXISTS t_nc_alimentos (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  nome VARCHAR(512) NOT NULL,
  codigo VARCHAR(20) NULL,
  grupo_id BIGINT UNSIGNED NULL,
  tipo_alimento_id BIGINT UNSIGNED NULL,
  observacoes TEXT NULL,
  created_at DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_t_nc_alimentos_codigo (codigo),
  KEY idx_t_nc_alimentos_user (user_id),
  KEY idx_t_nc_alimentos_grupo (grupo_id),
  KEY idx_t_nc_alimentos_tipo (tipo_alimento_id),
  CONSTRAINT fk_t_nc_alimentos_user FOREIGN KEY (user_id) REFERENCES t_nc_users (id),
  CONSTRAINT fk_t_nc_alimentos_grupo FOREIGN KEY (grupo_id) REFERENCES grupos (id),
  CONSTRAINT fk_t_nc_alimentos_tipo FOREIGN KEY (tipo_alimento_id) REFERENCES tipo_alimentos (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Valores nutricionais (por 100g, mesma convenção da TBCA) de um alimento
-- personalizado. Reusa `br_t_nut_conf` como cadastro de nutrientes (nome,
-- unidade, ordem de exibição) — não duplica essa configuração.
CREATE TABLE IF NOT EXISTS t_nc_nutrientes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  alimento_id BIGINT UNSIGNED NOT NULL,
  nutri_conf_id INT UNSIGNED NOT NULL,
  valor DOUBLE NOT NULL DEFAULT 0,
  created_at DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_t_nc_nutrientes_alimento_conf (alimento_id, nutri_conf_id),
  KEY idx_t_nc_nutrientes_conf (nutri_conf_id),
  CONSTRAINT fk_t_nc_nutrientes_alimento FOREIGN KEY (alimento_id) REFERENCES t_nc_alimentos (id) ON DELETE CASCADE,
  CONSTRAINT fk_t_nc_nutrientes_conf FOREIGN KEY (nutri_conf_id) REFERENCES br_t_nut_conf (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2026-08-27: `t_nc_cardapios`/`t_nc_cardapio_itens` (o builder de cardápios
-- do bootstrap inicial, 2026-08-25) foram removidas — DROPadas do banco e
-- tiradas do menu/rotas/models. O escopo real do NutriConsumo é o
-- recordatório alimentar (R24H) abaixo; o builder de cardápio era mais
-- adequado ao NutriReceitas (ver decisão da reunião de 2026-08-26).

-- Recordatório alimentar (R24H) — cabeçalho de UM dia de entrevista aplicado
-- pelo pesquisador (t_nc_users) a um entrevistado. Alinhado com a reunião
-- com a nutricionista (2026-08-25/26): dados antropométricos ficam no
-- Nutripersona, aqui só entra o registro alimentar. `entrevistado_codigo` é
-- texto livre (cópia do código já atribuído no Nutripersona) — sem FK entre
-- sistemas, o pesquisador guarda os recordatórios só nestas tabelas do
-- NutriConsumo. `etapa` acompanha em qual dos 5 passos do fluxo o
-- recordatório está, pra poder retomar de onde parou. `detalhamento` ainda
-- NÃO vincula alimento à base TBCA (isso fica pra depois) — só deixa o
-- pesquisador inserir uma lista livre de alimentos por ocasião, igual
-- lista_rapida/revisao_lista.
--
-- 2026-08-27: `numero_recordatorio` deixou de ser escolhido pelo pesquisador
-- (1/2/3 por entrevistado) e passou a ser gerado automaticamente pelo
-- backend como uma sequência 1..30 POR ENTREVISTADOR (NcRecordatorio::
-- contarPorUsuario/LIMITE_POR_ENTREVISTADOR) — soma todos os recordatórios
-- não excluídos do usuário, entre todos os entrevistados dele. O
-- CHECK abaixo é só documentação: MySQL 5.7 (versão real do banco local,
-- 127.0.0.1:3307) não suporta CHECK CONSTRAINT, então nunca foi de fato
-- aplicado — a validação do range 1..30 e do limite de 30 é só em
-- NcRecordatorioController::criar.
CREATE TABLE IF NOT EXISTS t_nc_recordatorios (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  entrevistador_codigo VARCHAR(50) NOT NULL,
  entrevistado_codigo VARCHAR(50) NOT NULL,
  data_entrevista DATE NOT NULL,
  numero_recordatorio TINYINT UNSIGNED NOT NULL,
  -- 2026-08-27: adicionado o passo 'matching' entre 'detalhamento' e
  -- 'revisao_final' (ALTER TABLE ... MODIFY etapa ENUM(...) aplicado
  -- diretamente no banco local, já com dados reais — ver CLAUDE/memória).
  etapa ENUM('lista_rapida','revisao_lista','detalhamento','matching','revisao_final','finalizado') NOT NULL DEFAULT 'lista_rapida',
  created_at DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  KEY idx_t_nc_recordatorios_user (user_id),
  KEY idx_t_nc_recordatorios_entrevistado (entrevistado_codigo),
  CONSTRAINT chk_t_nc_recordatorios_numero CHECK (numero_recordatorio BETWEEN 1 AND 30),
  CONSTRAINT fk_t_nc_recordatorios_user FOREIGN KEY (user_id) REFERENCES t_nc_users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Ocasião de consumo dentro de um recordatório. Deliberadamente NÃO é um
-- enum fixo de 6 categorias (café/almoço/jantar/...) — a nutricionista foi
-- explícita que isso limitaria demais o registro; `descricao` é texto livre
-- e pode se repetir várias vezes no mesmo dia (ex.: duas ocorrências de
-- "lanche"). `local` é fixo (lista validada com a Kristy), com `outro` como
-- válvula de escape.
CREATE TABLE IF NOT EXISTS t_nc_ocasioes (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  recordatorio_id BIGINT UNSIGNED NOT NULL,
  horario TIME NOT NULL,
  descricao VARCHAR(255) NOT NULL,
  local ENUM('casa','casa_de_outra_pessoa','trabalho','escola','creche','restaurante','rua_ambulante','outro') NOT NULL,
  local_outro VARCHAR(255) NULL,
  ordem INT UNSIGNED NOT NULL DEFAULT 0,
  created_at DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_t_nc_ocasioes_recordatorio (recordatorio_id),
  CONSTRAINT fk_t_nc_ocasioes_recordatorio FOREIGN KEY (recordatorio_id) REFERENCES t_nc_recordatorios (id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Um alimento/bebida citado numa ocasião. Nasce "rápido" na etapa 2 (só
-- `categoria` + `nome_livre`, sem gramatura) e é "detalhado" na etapa 4
-- (`detalhado = 1`): liga na TBCA (leitura, `br_t_alimentos`) ou num
-- alimento personalizado do próprio pesquisador (`t_nc_alimentos`), define
-- quantidade em g/ml e passa a exigir `origem_alimento` e
-- `referencia_fotografica` (obrigatórios pela reunião, mesmo pra itens já
-- catalogados na TBCA). `nome_alimento` é uma cópia do nome no momento do
-- detalhamento — não muda de leitura se o alimento de origem for
-- renomeado/excluído depois.
CREATE TABLE IF NOT EXISTS t_nc_itens_consumidos (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  ocasiao_id BIGINT UNSIGNED NOT NULL,
  categoria ENUM('lanche','bebida') NOT NULL DEFAULT 'lanche',
  nome_livre VARCHAR(255) NOT NULL,
  detalhado TINYINT(1) NOT NULL DEFAULT 0,
  origem ENUM('tbca','personalizado') NULL,
  alimento_cod VARCHAR(20) NULL,
  alimento_id BIGINT UNSIGNED NULL,
  nome_alimento VARCHAR(512) NULL,
  quantidade DOUBLE NULL,
  unidade ENUM('g','ml') NULL,
  origem_alimento VARCHAR(255) NULL,
  referencia_fotografica VARCHAR(255) NULL,
  observacao TEXT NULL,
  ordem INT UNSIGNED NOT NULL DEFAULT 0,
  created_at DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_t_nc_itens_consumidos_ocasiao (ocasiao_id),
  KEY idx_t_nc_itens_consumidos_alimento (alimento_id),
  KEY idx_t_nc_itens_consumidos_alimento_cod (alimento_cod),
  CONSTRAINT fk_t_nc_itens_consumidos_ocasiao FOREIGN KEY (ocasiao_id) REFERENCES t_nc_ocasioes (id) ON DELETE CASCADE,
  CONSTRAINT fk_t_nc_itens_consumidos_alimento FOREIGN KEY (alimento_id) REFERENCES t_nc_alimentos (id),
  CONSTRAINT fk_t_nc_itens_consumidos_alimento_tbca FOREIGN KEY (alimento_cod) REFERENCES br_t_alimentos (cod_alimento)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Cadastro próprio de entrevistados por pesquisador (2026-08-26) — cada
-- entrevistador mantém sua própria lista (escopo por `user_id`, mesmo padrão
-- de `t_nc_alimentos` personalizados). `codigo` é gerado pela aplicação após
-- o INSERT (formato `ENTV` + id com zero-padding, mesma convenção de
-- `NcAlimento::criarPersonalizado`/`NcUser::codigoEntrevistador`), nunca
-- digitado. Isso NÃO cria FK com `t_nc_recordatorios.entrevistado_codigo`
-- (que continua um VARCHAR livre, sem vínculo com Nutripersona) — o código
-- gerado aqui só é copiado pro formulário de novo recordatório pra evitar
-- erro de digitação, exatamente como o pesquisador digitaria manualmente.
CREATE TABLE IF NOT EXISTS t_nc_entrevistados (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  codigo VARCHAR(20) NULL,
  nome VARCHAR(150) NOT NULL,
  data_nascimento DATE NOT NULL,
  created_at DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_t_nc_entrevistados_codigo (codigo),
  KEY idx_t_nc_entrevistados_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
