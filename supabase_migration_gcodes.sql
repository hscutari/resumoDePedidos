-- ============================================================
-- Migração: tabela GCODES (tempo estimado + nº de peças por produto)
-- Rode no Supabase: SQL Editor -> New query -> Run
-- ============================================================

create table if not exists gcodes (
  produto        text primary key references produtos(codigo) on delete cascade,
  arquivo        text,
  tempo_segundos integer,
  pecas          integer,
  linhas         integer,
  tamanho_bytes  bigint,
  atualizado_em  timestamptz not null default now()
);

-- coluna do modelo da máquina (idempotente — pode rodar se a tabela já existir)
alter table gcodes add column if not exists modelo text;

alter table gcodes enable row level security;
drop policy if exists "anon_all_gcodes" on gcodes;
create policy "anon_all_gcodes" on gcodes for all to anon using (true) with check (true);
