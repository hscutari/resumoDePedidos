-- ============================================================
-- Migração: estoque por ENVIO (origem)
-- Rode no Supabase: SQL Editor -> New query -> Run
-- (aplica-se DEPOIS da migração de estoque diário)
-- ============================================================

-- 1) Adiciona a coluna de origem (envio)
alter table estoque
  add column if not exists origem text not null default 'SHOPEE';
alter table estoque alter column origem drop default;

-- 2) Inclui a origem na chave primária
alter table estoque drop constraint if exists estoque_pkey;
alter table estoque add primary key (produto, variacao, origem, dia);

-- Agora o estoque é único por (produto, variação, envio, dia).
-- Ex.: "BABA / Branco / RAPIDA" tem estoque separado de "BABA / Branco / SHOPEE".
