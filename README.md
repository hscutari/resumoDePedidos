# HS3DLab — Resumo de Pedidos

App web estático (HTML/CSS/JS puro, sem build) hospedado no **GitHub Pages**.
Backend via **Supabase** (Postgres + PostgREST) usando a `anon key` pública.
Autenticação client-side simples (ver `docs/TODO.md` → plano de migração para Supabase Auth).

## Estrutura

```
.
├── index.html              # Tela de login — ENTRADA do site (deve ficar na raiz, GitHub Pages)
├── app/                    # Telas autenticadas (exigem sessão; guard em auth.js)
│   ├── dashboard.html          # Painel inicial
│   ├── relatorio_pedidos.html  # Importação de etiquetas (PDF/links) + resumo por plataforma
│   ├── produtos.html           # Catálogo, vínculo de gcode e import em lote
│   ├── producao.html           # Distribuição de impressão entre impressoras (LPT)
│   ├── vendas_grafico.html     # Gráfico de itens vendidos/dia + tendência
│   └── usuarios.html           # Gestão de usuários
├── assets/
│   └── js/
│       └── auth.js         # Login, sessão (localStorage) e guard das telas — compartilhado
├── db/
│   ├── schema.sql          # Schema completo de referência (Supabase)
│   └── migrations/         # Migrações incrementais (rodar no SQL Editor do Supabase)
├── design/                 # Mockups e inspiração de layout (NÃO usados em runtime)
└── docs/
    └── TODO.md             # Pendências, migrações a rodar e plano de segurança
```

## Convenções de caminhos (importante — sem build, tudo relativo)

- A entrada do site é `index.html` na **raiz** (requisito do GitHub Pages).
- Todas as telas autenticadas vivem em **`app/`** (exatamente um nível abaixo da raiz),
  então os caminhos relativos ficam uniformes:
  - cada página em `app/` carrega o script com `<script src="../assets/js/auth.js"></script>`;
  - `index.html` (na raiz) carrega com `<script src="assets/js/auth.js"></script>`;
  - links entre telas de `app/` usam o nome do arquivo direto (mesma pasta);
  - o login redireciona para `app/dashboard.html`; o guard/logout volta para `../index.html`
    (auth.js detecta a profundidade via `/app/` no path).

## Banco de dados

Rode os arquivos de `db/migrations/` no **Supabase → SQL Editor → Run** (ver ordem em `docs/TODO.md`).
A `anon key` é pública por design e fica no frontend; a `service_role` **nunca** deve ir para o cliente.

## Deploy

GitHub Pages serve a partir da raiz do repositório. Faça commit + push e a entrada continua sendo `index.html`.
