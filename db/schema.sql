-- ============================================================
-- Schema do banco (Supabase / Postgres) - Resumo de Pedidos
-- Rode este SQL no painel do Supabase: SQL Editor -> New query -> Run
-- ============================================================

-- 1) Catálogo de produtos -------------------------------------
create table if not exists produtos (
  codigo      text primary key,            -- ex.: "BABA", "228797852786"
  nome        text,                        -- nome amigável (opcional)
  categoria   text,                        -- opcional (ex.: Chaveiros)
  gasto_ads   numeric(10,2),               -- gasto em anúncios/ADS (R$), por produto
  criado_em   timestamptz not null default now()
);

-- 2) Estoque PARCIAL DIÁRIO por ENVIO (produto + variação + origem + dia)
--    Gravado por dia e por envio (Shopee/Rápida/TikTok); cada dia começa zerado.
create table if not exists estoque (
  produto       text not null,             -- = produtos.codigo
  variacao      text not null,
  origem        text not null,             -- SHOPEE / RAPIDA / TIKTOK / OUTROS
  dia           date not null default current_date,
  quantidade    integer not null default 0,
  atualizado_em timestamptz not null default now(),
  primary key (produto, variacao, origem, dia)
);

-- 3) Relatórios (cada lote de PDFs processado) ----------------
create table if not exists relatorios (
  id           uuid primary key default gen_random_uuid(),
  criado_em    timestamptz not null default now(),
  arquivos     text,                        -- nomes dos PDFs processados
  etiquetas    integer,
  total_geral  integer,
  total_shopee integer,
  total_rapida integer,
  total_tiktok integer
);

-- 4) Pedidos individuais --------------------------------------
create table if not exists pedidos (
  id           bigint generated always as identity primary key,
  relatorio_id uuid references relatorios(id) on delete cascade,
  pedido       text,                        -- nº do pedido (ex.: 260606D4ESHJD2)
  origem       text,                        -- SHOPEE / RAPIDA / TIKTOK / OUTROS
  produto      text,
  variacao     text,
  quantidade   integer,
  deadline     date,                        -- data limite de envio (da etiqueta)
  criado_em    timestamptz not null default now()
);

create index if not exists idx_pedidos_relatorio on pedidos(relatorio_id);
create index if not exists idx_pedidos_produto   on pedidos(produto, variacao);
create index if not exists idx_pedidos_pedido    on pedidos(pedido);

-- 5) Usuários do painel (login + senha em hash SHA-256) -------
create table if not exists usuarios (
  login       text primary key,
  nome        text,
  senha_hash  text not null,
  criado_em   timestamptz not null default now()
);

-- 6) Gcodes (tabela ÚNICA) — import individual E em lote (bulk) ----
--    `produto` nulo = arquivo avulso (a vincular); preenchido = vinculado.
--    1 produto -> 1 arquivo · 1 usuário -> N arquivos (cada arquivo tem 1 dono).
create table if not exists gcode_arquivos (
  id             bigint generated always as identity primary key,
  arquivo        text,
  modelo         text,
  tempo_segundos integer,
  pecas          integer,
  linhas         integer,
  tamanho_bytes  bigint,
  produto        text references produtos(codigo) on delete set null,
  usuario        text references usuarios(login)  on delete set null,  -- dono do arquivo
  criado_em      timestamptz not null default now()
);

create index if not exists idx_gcode_arquivos_produto  on gcode_arquivos(produto);
create index if not exists idx_gcode_arquivos_usuario  on gcode_arquivos(usuario);

-- 7) Sub-produtos (composição de um produto) ------------------
--    Um produto tem N sub-produtos; cada sub-produto pertence a
--    1 produto pai. on delete cascade: some junto com o produto.
create table if not exists subprodutos (
  id          bigint generated always as identity primary key,
  produto     text not null references produtos(codigo) on delete cascade,  -- produto pai
  codigo      text,                                  -- código/SKU do sub-produto (opcional)
  nome        text,                                  -- nome do sub-produto
  quantidade  integer not null default 1,            -- qtd deste sub-produto por produto
  valor_venda    numeric(10,2),                       -- preço de venda (R$)
  custo_producao numeric(10,2),                       -- custo de produção (R$)
  criado_em   timestamptz not null default now()
);

create index if not exists idx_subprodutos_produto on subprodutos(produto);
-- chave natural p/ upsert idempotente na importação. Inclui `quantidade` porque
-- cada número entre parênteses é um sub-produto distinto: (1,Preto) e (4,Preto)
-- viram duas linhas (Preto qtd 1 e Preto qtd 4), cada uma com seu próprio valor.
create unique index if not exists subprodutos_produto_nome_qtd_uk on subprodutos(produto, nome, quantidade);

-- 8) Configurações do usuário --------------------------------
--    config_usuario: valores escalares (Shopee %, IR %) — 1 linha por usuário.
--    filamentos: 1 usuário -> N filamentos (tipo + valor/kg).
create table if not exists config_usuario (
  usuario            text primary key references usuarios(login) on delete cascade,
  shopee_imposto_pct numeric(5,2),     -- % de imposto pago por venda (Shopee)
  shopee_taxa_fixa   numeric(10,2),    -- valor fixo (R$) pago por venda (Shopee)
  ir_imposto_pct     numeric(5,2),     -- % de IR sobre o faturamento
  custo_envio        numeric(10,2),    -- custo de envio (R$) por pedido
  aluguel            numeric(10,2),    -- aluguel (R$)
  atualizado_em      timestamptz not null default now()
);

create table if not exists filamentos (
  id        bigint generated always as identity primary key,
  usuario   text not null references usuarios(login) on delete cascade,
  tipo      text not null,            -- ex.: PLA, PETG, ABS, TPU…
  valor_kg  numeric(10,2),            -- R$ por kg
  criado_em timestamptz not null default now()
);
create index if not exists idx_filamentos_usuario on filamentos(usuario);

-- Faixas de taxa da Shopee por preço (1 usuário -> N faixas); preco_max nulo = sem teto.
create table if not exists shopee_faixas (
  id           bigint generated always as identity primary key,
  usuario      text not null references usuarios(login) on delete cascade,
  preco_min    numeric(10,2) not null default 0,
  preco_max    numeric(10,2),            -- null = sem teto
  comissao_pct numeric(5,2),             -- % de comissão da faixa
  taxa_fixa    numeric(10,2),            -- valor fixo (R$) por item na faixa
  criado_em    timestamptz not null default now()
);
create index if not exists idx_shopee_faixas_usuario on shopee_faixas(usuario);

-- Funcionários do usuário (1 usuário -> N funcionários: nome + salário).
create table if not exists funcionarios (
  id        bigint generated always as identity primary key,
  usuario   text not null references usuarios(login) on delete cascade,
  nome      text not null,
  salario   numeric(10,2),            -- salário (R$)
  criado_em timestamptz not null default now()
);
create index if not exists idx_funcionarios_usuario on funcionarios(usuario);

-- ============================================================
-- Segurança (RLS)
-- Para uma ferramenta interna simples, liberamos acesso via a
-- chave pública "anon". A anon key é feita para ficar exposta no
-- frontend; quem tiver a URL do site pode ler/gravar.
-- Se precisar restringir, troque por políticas com auth depois.
-- ============================================================
alter table produtos       enable row level security;
alter table estoque        enable row level security;
alter table relatorios     enable row level security;
alter table pedidos        enable row level security;
alter table gcode_arquivos enable row level security;
alter table usuarios       enable row level security;
alter table subprodutos    enable row level security;
alter table config_usuario enable row level security;
alter table filamentos     enable row level security;
alter table shopee_faixas  enable row level security;
alter table funcionarios   enable row level security;

-- Políticas permissivas para o papel anon (acesso total)
create policy "anon_all_produtos"   on produtos   for all to anon using (true) with check (true);
create policy "anon_all_estoque"    on estoque    for all to anon using (true) with check (true);
create policy "anon_all_relatorios" on relatorios for all to anon using (true) with check (true);
create policy "anon_all_pedidos"    on pedidos    for all to anon using (true) with check (true);
create policy "anon_all_gcode_arquivos" on gcode_arquivos for all to anon using (true) with check (true);
create policy "anon_all_usuarios"   on usuarios   for all to anon using (true) with check (true);
create policy "anon_all_subprodutos" on subprodutos for all to anon using (true) with check (true);
create policy "anon_all_config_usuario" on config_usuario for all to anon using (true) with check (true);
create policy "anon_all_filamentos" on filamentos for all to anon using (true) with check (true);
create policy "anon_all_shopee_faixas" on shopee_faixas for all to anon using (true) with check (true);
create policy "anon_all_funcionarios" on funcionarios for all to anon using (true) with check (true);
