-- ============================================================
-- Migração: UNIFICAR gcodes em gcode_arquivos (tabela única)
-- Agora há uma só tabela para os dois casos:
--   - import individual  -> linha com produto preenchido
--   - import em lote      -> linha com produto nulo (a vincular)
-- Rode no Supabase: SQL Editor -> New query -> Run
-- ============================================================

-- garante a tabela única (idempotente)
create table if not exists gcode_arquivos (
  id             bigint generated always as identity primary key,
  arquivo        text,
  modelo         text,
  tempo_segundos integer,
  pecas          integer,
  linhas         integer,
  tamanho_bytes  bigint,
  produto        text references produtos(codigo) on delete set null,
  criado_em      timestamptz not null default now()
);
create index if not exists idx_gcode_arquivos_produto on gcode_arquivos(produto);
alter table gcode_arquivos enable row level security;
drop policy if exists "anon_all_gcode_arquivos" on gcode_arquivos;
create policy "anon_all_gcode_arquivos" on gcode_arquivos for all to anon using (true) with check (true);

-- migra os registros da antiga `gcodes` que ainda não existam vinculados
do $$
begin
  if exists (select 1 from information_schema.tables where table_name = 'gcodes') then
    insert into gcode_arquivos (arquivo, modelo, tempo_segundos, pecas, linhas, tamanho_bytes, produto)
    select g.arquivo, g.modelo, g.tempo_segundos, g.pecas, g.linhas, g.tamanho_bytes, g.produto
    from gcodes g
    where not exists (
      select 1 from gcode_arquivos ga where ga.produto = g.produto
    );
    drop table gcodes;
  end if;
end $$;
