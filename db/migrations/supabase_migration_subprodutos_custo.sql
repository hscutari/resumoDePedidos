-- ============================================================
-- Migração: dois campos de custo no sub-produto
--   valor_venda    — preço de venda (renomeado do antigo `valor`)
--   custo_producao — custo de produção
-- Idempotente. Rode no Supabase: SQL Editor -> Run
-- ============================================================

-- Renomeia `valor` -> `valor_venda` (só se ainda não foi feito).
do $$
begin
  if exists (select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'subprodutos' and column_name = 'valor')
     and not exists (select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'subprodutos' and column_name = 'valor_venda') then
    alter table subprodutos rename column valor to valor_venda;
  end if;
end $$;

-- Garante as duas colunas.
alter table subprodutos add column if not exists valor_venda    numeric(10,2);
alter table subprodutos add column if not exists custo_producao numeric(10,2);
