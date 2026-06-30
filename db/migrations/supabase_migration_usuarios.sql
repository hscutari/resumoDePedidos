-- ============================================================
-- Migração: tabela USUARIOS (login do painel)
-- Senha guardada como hash SHA-256 (nunca em texto puro).
-- Rode no Supabase: SQL Editor -> New query -> Run
-- ============================================================

create table if not exists usuarios (
  login       text primary key,
  nome        text,
  senha_hash  text not null,
  criado_em   timestamptz not null default now()
);

alter table usuarios enable row level security;
drop policy if exists "anon_all_usuarios" on usuarios;
create policy "anon_all_usuarios" on usuarios for all to anon using (true) with check (true);

-- Usuário inicial: admin / admin  (TROQUE a senha depois na tela de Usuários!)
insert into usuarios (login, nome, senha_hash)
values ('admin', 'Administrador', '8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918')
on conflict (login) do nothing;
