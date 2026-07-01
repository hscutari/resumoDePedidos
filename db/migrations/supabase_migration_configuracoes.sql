-- ============================================================
-- Migração: CONFIGURAÇÕES do usuário
--   * config_usuario — valores escalares por usuário (Shopee %, IR %)
--   * filamentos     — 1 usuário -> N filamentos (tipo + valor/kg)
-- Rode no Supabase: SQL Editor -> New query -> Run
-- (após supabase_migration_usuarios.sql)
-- ============================================================

-- Config escalar (1 linha por usuário)
create table if not exists config_usuario (
  usuario            text primary key references usuarios(login) on delete cascade,
  shopee_imposto_pct numeric(5,2),     -- % de imposto pago por venda (Shopee)
  shopee_taxa_fixa   numeric(10,2),    -- valor fixo (R$) pago por venda (Shopee)
  ir_imposto_pct     numeric(5,2),     -- % de IR sobre o faturamento
  custo_envio        numeric(10,2),    -- custo de envio (R$) por pedido
  aluguel            numeric(10,2),    -- aluguel (R$)
  atualizado_em      timestamptz not null default now()
);

-- Idempotente: garante as colunas caso a tabela já tenha sido criada antes.
alter table config_usuario add column if not exists shopee_taxa_fixa numeric(10,2);
alter table config_usuario add column if not exists custo_envio      numeric(10,2);
alter table config_usuario add column if not exists aluguel          numeric(10,2);

-- Filamentos do usuário (vários por usuário)
create table if not exists filamentos (
  id        bigint generated always as identity primary key,
  usuario   text not null references usuarios(login) on delete cascade,
  tipo      text not null,            -- ex.: PLA, PETG, ABS, TPU…
  valor_kg  numeric(10,2),            -- R$ por kg
  criado_em timestamptz not null default now()
);

create index if not exists idx_filamentos_usuario on filamentos(usuario);

-- Funcionários do usuário (1 usuário -> N funcionários: nome + salário).
create table if not exists funcionarios (
  id        bigint generated always as identity primary key,
  usuario   text not null references usuarios(login) on delete cascade,
  nome      text not null,
  salario   numeric(10,2),            -- salário (R$)
  criado_em timestamptz not null default now()
);

create index if not exists idx_funcionarios_usuario on funcionarios(usuario);

-- Faixas de taxa da Shopee por preço (1 usuário -> N faixas).
-- preco_max nulo = faixa "sem teto" (ex.: R$ 200+).
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

-- Segurança (RLS) — mesmo padrão das demais tabelas: acesso via anon key.
alter table config_usuario enable row level security;
alter table filamentos     enable row level security;
alter table shopee_faixas  enable row level security;
alter table funcionarios   enable row level security;
drop policy if exists "anon_all_config_usuario" on config_usuario;
create policy "anon_all_config_usuario" on config_usuario for all to anon using (true) with check (true);
drop policy if exists "anon_all_filamentos" on filamentos;
create policy "anon_all_filamentos" on filamentos for all to anon using (true) with check (true);
drop policy if exists "anon_all_shopee_faixas" on shopee_faixas;
create policy "anon_all_shopee_faixas" on shopee_faixas for all to anon using (true) with check (true);
drop policy if exists "anon_all_funcionarios" on funcionarios;
create policy "anon_all_funcionarios" on funcionarios for all to anon using (true) with check (true);
