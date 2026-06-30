-- ============================================================
-- Migração: tornar o ESTOQUE parcial DIÁRIO
-- Rode no Supabase: SQL Editor -> New query -> Run
-- (a tabela 'estoque' precisa já existir do schema inicial)
-- ============================================================

-- 1) Adiciona a coluna de dia (default = hoje)
alter table estoque
  add column if not exists dia date not null default current_date;

-- 2) Troca a chave primária para incluir o dia
alter table estoque drop constraint if exists estoque_pkey;
alter table estoque add primary key (produto, variacao, dia);

-- Pronto. A partir de agora cada (produto, variação) tem um registro por dia.
-- O dia anterior fica armazenado como histórico; o app carrega apenas o dia atual,
-- então o estoque "zera" sozinho no dia seguinte.
