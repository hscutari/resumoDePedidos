-- ============================================================
-- Migração: gastos em ADS por PRODUTO
-- Um valor por produto (não por sub-produto).
-- Idempotente. Rode no Supabase: SQL Editor -> Run
-- ============================================================

alter table produtos add column if not exists gasto_ads numeric(10,2);   -- gasto em anúncios (R$)
