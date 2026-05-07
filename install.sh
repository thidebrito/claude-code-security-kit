#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# install.sh — Instala THIDEBRITO-SECURITY no computador atual
#
# Idempotente: pode rodar várias vezes sem efeitos colaterais
# Faz backup do settings.json antes de modificar
#
# Uso:
#   cd ~/PROJETOS/claude-code-security-kit
#   bash install.sh
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
BUNDLE="$REPO_DIR/claude-code-bundle"

echo "═══════════════════════════════════════════════════════════════"
echo "🛡️  THIDEBRITO-SECURITY — Instalação"
echo "═══════════════════════════════════════════════════════════════"
echo "    Repo: $REPO_DIR"
echo "    Claude: $CLAUDE_DIR"
echo ""

if [ ! -d "$BUNDLE" ]; then
  echo "❌ Bundle não encontrado em $BUNDLE"
  echo "   Você está rodando do diretório certo?"
  exit 1
fi

# ── 1. Validar pré-requisitos ─────────────────────────────
echo "▼ Verificando dependências..."
MISSING=()
for tool in git node python3; do
  command -v $tool >/dev/null || MISSING+=("$tool")
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "❌ Faltam dependências: ${MISSING[*]}"
  echo ""
  echo "Instalar no Mac:"
  echo "  brew install ${MISSING[*]}"
  echo ""
  echo "Instalar no Linux (Ubuntu/Debian):"
  echo "  sudo apt install ${MISSING[*]}"
  exit 1
fi

if ! command -v gitleaks >/dev/null; then
  echo "  ⚠️  gitleaks não instalado (recomendado, mas opcional)"
  echo "      Mac:   brew install gitleaks"
  echo "      Linux: https://github.com/gitleaks/gitleaks#installation"
  echo ""
  read -p "  Continuar mesmo assim? (y/N) " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] || exit 1
else
  echo "  ✅ gitleaks $(gitleaks version) instalado"
fi

echo "  ✅ git, node, python3 OK"
echo ""

# ── 2. Backup do settings.json ─────────────────────────────
echo "▼ Backup de configurações Claude Code..."
mkdir -p "$CLAUDE_DIR"
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  BACKUP="$CLAUDE_DIR/settings.json.bak.$(date +%Y%m%d-%H%M%S)"
  cp "$CLAUDE_DIR/settings.json" "$BACKUP"
  echo "  ✅ Backup: $(basename "$BACKUP")"
else
  echo "  ℹ️  settings.json não existe, criando vazio"
  echo '{}' > "$CLAUDE_DIR/settings.json"
fi
echo ""

# ── 3. Instalar skill ──────────────────────────────────────
echo "▼ Instalando skill seguranca-projeto..."
mkdir -p "$CLAUDE_DIR/skills/seguranca-projeto"
cp "$BUNDLE/skills/seguranca-projeto/SKILL.md" \
   "$CLAUDE_DIR/skills/seguranca-projeto/SKILL.md"
echo "  ✅ ~/.claude/skills/seguranca-projeto/SKILL.md"
echo ""

# ── 4. Instalar comandos /secure-* ────────────────────────
echo "▼ Instalando comandos /secure-*..."
mkdir -p "$CLAUDE_DIR/commands"
for c in secure-init secure-audit secure-protect; do
  cp "$BUNDLE/commands/$c.md" "$CLAUDE_DIR/commands/$c.md"
  echo "  ✅ /$c"
done
echo ""

# ── 5. Instalar hook scripts ──────────────────────────────
echo "▼ Instalando hook scripts..."
mkdir -p "$CLAUDE_DIR/scripts"
for s in block-secrets-commit pii-scan-hook security-marker-check pre-deploy-guard security-session-start; do
  cp "$BUNDLE/scripts/$s.sh" "$CLAUDE_DIR/scripts/$s.sh"
  chmod +x "$CLAUDE_DIR/scripts/$s.sh"
  echo "  ✅ $s.sh"
done
echo ""

# ── 6. Configurar settings.json ───────────────────────────
echo "▼ Adicionando hooks em settings.json (idempotente)..."
python3 << 'PYEOF'
import json, os, sys

SETTINGS = os.path.expanduser("~/.claude/settings.json")
with open(SETTINGS) as f:
    data = json.load(f)

data.setdefault("hooks", {})
data["hooks"].setdefault("PreToolUse", [])
data["hooks"].setdefault("SessionStart", [])

# Garantir matchers
matchers_pre = {h.get("matcher") for h in data["hooks"]["PreToolUse"]}
if "Bash" not in matchers_pre:
    data["hooks"]["PreToolUse"].append({"matcher": "Bash", "hooks": []})
if "Edit|Write" not in matchers_pre:
    data["hooks"]["PreToolUse"].append({"matcher": "Edit|Write", "hooks": []})

matchers_ss = {h.get("matcher") for h in data["hooks"]["SessionStart"]}
if "startup|resume" not in matchers_ss:
    data["hooks"]["SessionStart"].append({"matcher": "startup|resume", "hooks": []})

ADD_PRE = {
    "Bash": [
        "$HOME/.claude/scripts/pre-deploy-guard.sh",
        "$HOME/.claude/scripts/block-secrets-commit.sh",
        "$HOME/.claude/scripts/pii-scan-hook.sh",
    ],
    "Edit|Write": [
        "$HOME/.claude/scripts/security-marker-check.sh",
    ],
}
ADD_SS = {
    "startup|resume": [
        "$HOME/.claude/scripts/security-session-start.sh",
    ],
}

added = 0
for matcher, scripts in ADD_PRE.items():
    group = next(h for h in data["hooks"]["PreToolUse"] if h.get("matcher") == matcher)
    existing = {h.get("command", "").split("/")[-1] for h in group.get("hooks", [])}
    for script in scripts:
        name = script.split("/")[-1]
        if name not in existing:
            group["hooks"].append({"type": "command", "command": f"bash {script}"})
            added += 1
            print(f"  ➕ Adicionado PreToolUse: [{matcher}] {name}")

for matcher, scripts in ADD_SS.items():
    group = next(h for h in data["hooks"]["SessionStart"] if h.get("matcher") == matcher)
    existing = {h.get("command", "").split("/")[-1] for h in group.get("hooks", [])}
    for script in scripts:
        name = script.split("/")[-1]
        if name not in existing:
            group["hooks"].append({"type": "command", "command": f"bash {script}"})
            added += 1
            print(f"  ➕ Adicionado SessionStart: [{matcher}] {name}")

with open(SETTINGS, "w") as f:
    json.dump(data, f, indent=2)

print(f"\n  ✅ {added} hooks novos adicionados (resto já existia)")
PYEOF
echo ""

# ── 7. Atualizar CLAUDE.md global ─────────────────────────
echo "▼ Atualizando CLAUDE.md global..."
CMD_FILE="$CLAUDE_DIR/CLAUDE.md"
if [ -f "$CMD_FILE" ] && grep -q "Sistema de Segurança e Proteção" "$CMD_FILE"; then
  echo "  ⏭  Seção 'Sistema de Segurança' já existe (skip)"
else
  echo "" >> "$CMD_FILE"
  cat "$BUNDLE/claude-md-snippet.md" >> "$CMD_FILE"
  echo "  ✅ Seção adicionada ao final do CLAUDE.md"
fi
echo ""

# ── 8. Tornar scripts do repo executáveis ─────────────────
echo "▼ Tornando scripts do repo executáveis..."
chmod +x "$REPO_DIR/scripts/"*.sh "$REPO_DIR/scripts/"*.mjs 2>/dev/null || true
echo "  ✅ Scripts em $REPO_DIR/scripts/"
echo ""

# ── 9. Validação final ────────────────────────────────────
echo "▼ Validação final..."
PASS=0; FAIL=0
v() { if eval "$1"; then PASS=$((PASS+1)); echo "  ✅ $2"; else FAIL=$((FAIL+1)); echo "  ❌ $2"; fi; }

v "[ -f $CLAUDE_DIR/skills/seguranca-projeto/SKILL.md ]" "Skill seguranca-projeto"
v "[ -f $CLAUDE_DIR/commands/secure-init.md ]" "Comando /secure-init"
v "[ -f $CLAUDE_DIR/commands/secure-audit.md ]" "Comando /secure-audit"
v "[ -f $CLAUDE_DIR/commands/secure-protect.md ]" "Comando /secure-protect"
v "[ -x $CLAUDE_DIR/scripts/block-secrets-commit.sh ]" "Hook block-secrets-commit.sh"
v "[ -x $CLAUDE_DIR/scripts/pii-scan-hook.sh ]" "Hook pii-scan-hook.sh"
v "[ -x $CLAUDE_DIR/scripts/security-marker-check.sh ]" "Hook security-marker-check.sh"
v "[ -x $CLAUDE_DIR/scripts/pre-deploy-guard.sh ]" "Hook pre-deploy-guard.sh"
v "[ -x $CLAUDE_DIR/scripts/security-session-start.sh ]" "Hook security-session-start.sh"
v "python3 -c 'import json; json.load(open(\"$CLAUDE_DIR/settings.json\"))'" "settings.json válido"
v "grep -q 'Sistema de Segurança' $CLAUDE_DIR/CLAUDE.md" "CLAUDE.md atualizado"

echo ""
echo "═══════════════════════════════════════════════════════════════"
if [ $FAIL -eq 0 ]; then
  echo "✅ Instalação completa! ($PASS/$((PASS+FAIL)) checks OK)"
else
  echo "⚠️  Instalação com $FAIL falha(s) ($PASS/$((PASS+FAIL)) OK)"
fi
echo ""
echo "PRÓXIMOS PASSOS:"
echo ""
echo "  1. Reiniciar Claude Code (pra carregar skill, commands e hooks)"
echo ""
echo "  2. Auditar todos os projetos do ecossistema:"
echo "     bash $REPO_DIR/scripts/audit-projects.sh"
echo "     # gera reports/audit-YYYY-MM-DD.json"
echo ""
echo "  3. Aplicar template em cada projeto que precisar:"
echo "     bash $REPO_DIR/scripts/apply-template.sh ~/PROJETOS/<projeto>"
echo ""
echo "  4. Em projetos novos, usar:"
echo "     /secure-init <pasta>      # inicializa proteção"
echo "     /secure-protect <pasta>   # antes de deploy de LP/app público"
echo ""
echo "═══════════════════════════════════════════════════════════════"
