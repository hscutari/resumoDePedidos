-- ============================================================
-- Migração: coluna DEADLINE em pedidos (data limite de envio)
-- Extraída da etiqueta no padrão "Deadline:DD/MM/YYYY".
-- Rode no Supabase: SQL Editor -> New query -> Run
-- ============================================================

alter table pedidos add column if not exists deadline date;

create index if not exists idx_pedidos_deadline on pedidos(deadline);
