-- ============================================================
-- Schema do banco (Supabase / Postgres) - Resumo de Pedidos
-- Rode este SQL no painel do Supabase: SQL Editor -> New query -> Run
-- ============================================================

-- 1) Catálogo de produtos -------------------------------------
create table if not exists produtos (
  codigo      text primary key,            -- ex.: "BABA", "228797852786"
  nome        text,                        -- nome amigável (opcional)
  categoria   text,                        -- opcional (ex.: Chaveiros)
  criado_em   timestamptz not null default now()
);

-- 2) Estoque PARCIAL DIÁRIO por ENVIO (produto + variação + origem + dia)
--    Gravado por dia e por envio (Shopee/Rápida/TikTok); cada dia começa zerado.
create table if not exists estoque (
  produto       text not null,             -- = produtos.codigo
  variacao      text not null,
  origem        text not null,             -- SHOPEE / RAPIDA / TIKTOK / OUTROS
  dia           date not null default current_date,
  quantidade    integer not null default 0,
  atualizado_em timestamptz not null default now(),
  primary key (produto, variacao, origem, dia)
);

-- 3) Relatórios (cada lote de PDFs processado) ----------------
create table if not exists relatorios (
  id           uuid primary key default gen_random_uuid(),
  criado_em    timestamptz not null default now(),
  arquivos     text,                        -- nomes dos PDFs processados
  etiquetas    integer,
  total_geral  integer,
  total_shopee integer,
  total_rapida integer,
  total_tiktok integer
);

-- 4) Pedidos individuais --------------------------------------
create table if not exists pedidos (
  id           bigint generated always as identity primary key,
  relatorio_id uuid references relatorios(id) on delete cascade,
  pedido       text,                        -- nº do pedido (ex.: 260606D4ESHJD2)
  origem       text,                        -- SHOPEE / RAPIDA / TIKTOK / OUTROS
  produto      text,
  variacao     text,
  quantidade   integer,
  deadline     date,                        -- data limite de envio (da etiqueta)
  criado_em    timestamptz not null default now()
);

create index if not exists idx_pedidos_relatorio on pedidos(relatorio_id);
create index if not exists idx_pedidos_produto   on pedidos(produto, variacao);
create index if not exists idx_pedidos_pedido    on pedidos(pedido);

-- 5) Gcodes (tabela ÚNICA) — import individual E em lote (bulk) ----
--    `produto` nulo = arquivo avulso (a vincular); preenchido = vinculado.
--    1 produto -> 1 arquivo (regra de negócio aplicada no app).
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

-- ============================================================
-- Segurança (RLS)
-- Para uma ferramenta interna simples, liberamos acesso via a
-- chave pública "anon". A anon key é feita para ficar exposta no
-- frontend; quem tiver a URL do site pode ler/gravar.
-- Se precisar restringir, troque por políticas com auth depois.
-- ============================================================
alter table produtos       enable row level security;
alter table estoque        enable row level security;
alter table relatorios     enable row level security;
alter table pedidos        enable row level security;
alter table gcode_arquivos enable row level security;

-- Políticas permissivas para o papel anon (acesso total)
create policy "anon_all_produtos"   on produtos   for all to anon using (true) with check (true);
create policy "anon_all_estoque"    on estoque    for all to anon using (true) with check (true);
create policy "anon_all_relatorios" on relatorios for all to anon using (true) with check (true);
create policy "anon_all_pedidos"    on pedidos    for all to anon using (true) with check (true);
create policy "anon_all_gcode_arquivos" on gcode_arquivos for all to anon using (true) with check (true);
