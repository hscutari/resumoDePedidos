-- ============================================================
-- Migração: tabela GCODE_ARQUIVOS (bulk import de gcodes/3mf SEM vínculo)
-- Guarda arquivos importados em lote; o vínculo com um produto é feito
-- em um passo posterior (coluna `produto` fica nula até lá).
-- Rode no Supabase: SQL Editor -> New query -> Run
-- ============================================================

create table if not exists gcode_arquivos (
  id             bigint generated always as identity primary key,
  arquivo        text,
  modelo         text,
  tempo_segundos integer,
  pecas          integer,
  linhas         integer,
  tamanho_bytes  bigint,
  produto        text references produtos(codigo) on delete set null,  -- vinculado depois
  criado_em      timestamptz not null default now()
);

create index if not exists idx_gcode_arquivos_produto on gcode_arquivos(produto);

alter table gcode_arquivos enable row level security;
drop policy if exists "anon_all_gcode_arquivos" on gcode_arquivos;
create policy "anon_all_gcode_arquivos" on gcode_arquivos for all to anon using (true) with check (true);
