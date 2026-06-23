# TODO — HS3DLab / Resumo de Pedidos

## 🔐 Segurança
- [ ] **Migrar o login para Supabase Auth.** Hoje a autenticação é client-side: o app usa a `anon key` pública, então a tabela `usuarios` (incluindo os `senha_hash`) é tecnicamente legível por quem tiver a chave, e o hash é SHA-256 **sem salt** (vulnerável a dicionário/rainbow table).
  - Trocar para Supabase Auth (e-mail/senha): autenticação no servidor, sessão via JWT.
  - Fechar cadastro público (signup) e criar usuários pelo painel/admin.
  - RLS com papel `authenticated` nas tabelas (em vez de acesso total ao `anon`).
  - Remover a tabela `usuarios` custom e o hash SHA-256 do `auth.js` depois da migração.

## 🗄️ Migrações do Supabase a rodar (SQL Editor → Run)
- [ ] `supabase_migration_usuarios.sql` — tabela de usuários + admin inicial (admin/admin).
- [ ] `supabase_migration_pedidos_deadline.sql` — coluna `deadline` em `pedidos`.
- [ ] `supabase_migration_unificar_gcodes.sql` — unifica tudo em `gcode_arquivos` e dropa `gcodes`.
- [ ] `supabase_migration_gcode_arquivos.sql` — tabela de gcodes (bulk + individual).
- [ ] Conferir se `supabase_migration_estoque_envio.sql` (coluna `origem` no estoque) já foi aplicada.

## 🐛 Correções pendentes
- [ ] Corrigir o mesmo bug de múltiplos itens por etiqueta no script Python `analise_pedidos.py` (o app web já foi corrigido).
- [ ] Pedidos antigos importados antes da correção de multi-itens têm só o 1º item. Para corrigir o histórico: limpar e reimportar os PDFs (a dedup por nº de pedido impede correção em reimport incremental).

## 🚀 Deploy
- [ ] Commit + push de todas as telas e migrações para o GitHub (GitHub Pages).

## 💡 Ideias / melhorias futuras
- [ ] Produção: opção de objetivo "cumprir prazos por deadline" (além de minimizar makespan).
- [ ] Gráfico de vendas: alternar entre "itens vendidos" e "nº de pedidos"; tendência mais elaborada (média móvel / peso nos dias recentes).
- [ ] Tempo de setup por impressão (configurável) no cálculo de produção.
