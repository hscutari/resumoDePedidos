// ============================================================
// auth.js — login, persistência de sessão e proteção das telas.
// Vive em /assets/js/auth.js. Inclua DEPOIS do supabase-js:
//   raiz (index.html):  <script src="assets/js/auth.js"></script>
//   páginas em /app/:   <script src="../assets/js/auth.js"></script>
// Páginas que incluem este arquivo (exceto index.html) exigem login.
// ============================================================
(function(){
  // Caminho até a tela de login conforme a profundidade da página.
  // As telas autenticadas vivem em /app/ (um nível abaixo da raiz).
  const LOGIN = location.pathname.includes("/app/") ? "../index.html" : "index.html";
  const SUPABASE_URL = "https://upctjkyfazudvttqrysp.supabase.co";
  const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVwY3Rqa3lmYXp1ZHZ0dHFyeXNwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEyNzMyMjQsImV4cCI6MjA5Njg0OTIyNH0.MhSONZDBMfbxOkTKzxip1jZ8Yy56TkYxHePtKtunCcw";
  const SESSION_KEY = "hs3d_session";
  const db = (window.supabase) ? window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY) : null;

  async function sha256(txt){
    const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(txt));
    return [...new Uint8Array(buf)].map(b => b.toString(16).padStart(2, "0")).join("");
  }

  function sessao(){
    try { return JSON.parse(localStorage.getItem(SESSION_KEY) || "null"); }
    catch { return null; }
  }

  async function login(usuario, senha){
    if(!db) throw new Error("Banco não configurado.");
    const hash = await sha256(senha);
    const { data, error } = await db.from("usuarios")
      .select("login,nome").eq("login", usuario).eq("senha_hash", hash).maybeSingle();
    if(error) throw error;
    if(!data) return false;
    localStorage.setItem(SESSION_KEY, JSON.stringify({ login: data.login, nome: data.nome, ts: Date.now() }));
    return true;
  }

  function logout(){
    localStorage.removeItem(SESSION_KEY);
    location.replace(LOGIN);
  }

  const paginaAtual = () => (location.pathname.split("/").pop() || "index.html").toLowerCase();

  // Guard: toda página (menos a de login) exige sessão ativa
  function proteger(){
    if(paginaAtual() === "index.html") return;
    if(!sessao()) location.replace(LOGIN);
  }
  proteger();

  // API pública
  window.Auth = { db, sha256, sessao, login, logout, SESSION_KEY };
})();
