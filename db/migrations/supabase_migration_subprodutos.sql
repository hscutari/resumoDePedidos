-- ============================================================
-- Migração: SUB-PRODUTOS (composição de um produto)
-- Um produto pode ter N sub-produtos; cada sub-produto pertence
-- a exatamente um produto (produto pai). on delete cascade: ao
-- excluir o produto, seus sub-produtos somem junto.
-- Rode no Supabase: SQL Editor -> New query -> Run
-- ============================================================

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

-- Idempotente: garante as colunas caso a tabela já tenha sido criada antes.
alter table subprodutos add column if not exists valor_venda    numeric(10,2);
alter table subprodutos add column if not exists custo_producao numeric(10,2);

create index if not exists idx_subprodutos_produto on subprodutos(produto);

-- Chave natural (produto + nome + quantidade): permite upsert idempotente na
-- importação. Inclui `quantidade` porque cada número entre parênteses é um
-- sub-produto distinto: (1,Preto) e (4,Preto) => duas linhas (qtd 1 e qtd 4).
create unique index if not exists subprodutos_produto_nome_qtd_uk on subprodutos(produto, nome, quantidade);

-- Segurança (RLS) — mesmo padrão das demais tabelas: acesso via anon key.
-- (drop antes de create p/ a migração ser re-executável; create policy não
--  aceita "if not exists".)
alter table subprodutos enable row level security;
drop policy if exists "anon_all_subprodutos" on subprodutos;
create policy "anon_all_subprodutos" on subprodutos for all to anon using (true) with check (true);
