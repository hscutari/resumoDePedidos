-- ============================================================
-- Migração: chave do sub-produto passa a INCLUIR a quantidade
-- Agora cada número entre parênteses é um sub-produto distinto:
--   (1,Preto) e (4,Preto)  =>  duas linhas (Preto qtd 1, Preto qtd 4),
--   cada uma com seu próprio valor.
-- Rode no Supabase: SQL Editor -> Run
-- (após supabase_migration_subprodutos.sql, se você já o rodou)
-- ============================================================

-- 1) Troca o índice único de (produto, nome) para (produto, nome, quantidade).
drop index if exists subprodutos_produto_nome_uk;
create unique index if not exists subprodutos_produto_nome_qtd_uk
  on subprodutos(produto, nome, quantidade);

-- 2) (RECOMENDADO) Limpe os sub-produtos atuais antes de re-importar.
--    O backfill anterior preencheu TODOS com quantidade = 1, o que pode estar
--    errado (ex.: itens vendidos só como "×4"). Como ainda não há valores
--    cadastrados, limpar é seguro — a re-importação recria tudo com a
--    quantidade correta a partir do dado cru da etiqueta.
--    Descomente a linha abaixo para limpar:
-- truncate table subprodutos restart identity;
