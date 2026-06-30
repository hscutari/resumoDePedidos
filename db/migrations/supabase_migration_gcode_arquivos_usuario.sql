-- ============================================================
-- Migração: vínculo ARQUIVO -> USUÁRIO (dono)
-- Um usuário possui vários arquivos; cada arquivo tem um único dono.
-- Rode no Supabase: SQL Editor -> New query -> Run
-- (rode DEPOIS de supabase_migration_usuarios.sql)
-- ============================================================

alter table gcode_arquivos
  add column if not exists usuario text references usuarios(login) on delete set null;

create index if not exists idx_gcode_arquivos_usuario on gcode_arquivos(usuario);
