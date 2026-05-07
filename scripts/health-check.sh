#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# health-check.sh — Validação rápida do estado do sistema
#
# Verifica:
#   - Componentes do Claude Code (skill, comandos, hooks)
#   - Settings.json válido
#   - CLAUDE.md atualizado
#   - Repo SECURITY consistente
#   - Cobertura retroativa (% projetos com marker)
#   - Sites em prod (opcional, com --check-prod)
#
# Uso:
#   bash scripts/health-check.sh
#   bash scripts/health-check.sh --check-prod   # inclui curl em sites
#   bash scripts/health-check.sh --quiet        # só erros
# ═══════════════════════════════════════════════════════════════

# Garantir PATH e HOME completos (hooks Claude rodam em ambiente minimo)
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"
export HOME="${HOME:-$(eval echo ~$(whoami))}"

set -uo pipefail

CHECK_PROD=0
QUIET=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check-prod) CHECK_PROD=1; shift ;;
    --quiet) QUIET=1; shift ;;
    -h|--help) grep '^# ' "$0" | head -15; exit 0 ;;
    *) echo "Opção desconhecida: $1"; exit 2 ;;
  esac
done

PASS=0; FAIL=0; WARN=0
CLAUDE_DIR="$HOME/.claude"
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"

ok()    { PASS=$((PASS+1)); [ $QUIET -eq 0 ] && echo "  ✅ $1"; return 0; }
fail()  { FAIL=$((FAIL+1)); echo "  ❌ $1"; return 0; }
warn()  { WARN=$((WARN+1)); echo "  ⚠️  $1"; return 0; }
info()  { [ $QUIET -eq 0 ] && echo "$1"; return 0; }

info ""
info "═══ HEALTH CHECK — THIDEBRITO-SECURITY ═══"
info ""

# ── 1. Componentes do Claude Code ────────────────────────
info "▼ 1. Claude Code"
[ -f "$CLAUDE_DIR/skills/seguranca-projeto/SKILL.md" ] && ok "Skill seguranca-projeto" || fail "Skill seguranca-projeto FALTA"
[ -f "$CLAUDE_DIR/commands/secure-init.md" ] && ok "Comando /secure-init" || fail "Comando /secure-init FALTA"
[ -f "$CLAUDE_DIR/commands/secure-audit.md" ] && ok "Comando /secure-audit" || fail "Comando /secure-audit FALTA"
[ -f "$CLAUDE_DIR/commands/secure-protect.md" ] && ok "Comando /secure-protect" || fail "Comando /secure-protect FALTA"

for s in block-secrets-commit pii-scan-hook security-marker-check pre-deploy-guard; do
  [ -x "$CLAUDE_DIR/scripts/$s.sh" ] && ok "Hook $s.sh" || fail "Hook $s.sh FALTA ou sem +x"
done

# ── 2. settings.json ────────────────────────────────────
info ""
info "▼ 2. settings.json"
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  if python3 -c "import json; json.load(open('$CLAUDE_DIR/settings.json'))" 2>/dev/null; then
    ok "settings.json válido"
    HOOKS=$(python3 -c "
import json
s=json.load(open('$CLAUDE_DIR/settings.json'))
n=0
for t,gs in s.get('hooks',{}).items():
    for g in gs:
        for h in g.get('hooks',[]):
            if any(x in h.get('command','') for x in ['block-secrets','pii-scan','security-marker','pre-deploy-guard']): n+=1
print(n)
" 2>/dev/null)
    if [ "$HOOKS" = "4" ]; then
      ok "4 hooks de segurança ativos"
    else
      warn "Esperado 4 hooks, encontrado $HOOKS"
    fi
  else
    fail "settings.json INVÁLIDO (JSON malformado)"
  fi
else
  fail "settings.json NÃO EXISTE"
fi

# ── 3. CLAUDE.md ────────────────────────────────────────
info ""
info "▼ 3. CLAUDE.md global"
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  grep -q "Sistema de Segurança" "$CLAUDE_DIR/CLAUDE.md" && ok "Seção Sistema de Segurança presente" || warn "Seção falta"
  grep -q "Sistema de Segurança Always-On" "$CLAUDE_DIR/CLAUDE.md" && ok "Regra 11 presente" || warn "Regra 11 falta"
  grep -q "Pré-deploy de projeto público" "$CLAUDE_DIR/CLAUDE.md" && ok "Regra 12 presente" || warn "Regra 12 falta"
else
  warn "CLAUDE.md global não existe"
fi

# ── 4. Repo SECURITY ────────────────────────────────────
info ""
info "▼ 4. Repo SECURITY"
[ -d "$REPO_DIR/.git" ] && ok "Repo Git inicializado" || warn "Repo sem .git/"
[ -d "$REPO_DIR/templates" ] && ok "templates/ existe" || fail "templates/ FALTA"
[ -d "$REPO_DIR/scripts" ] && ok "scripts/ existe" || fail "scripts/ FALTA"
[ -d "$REPO_DIR/claude-code-bundle" ] && ok "claude-code-bundle/ existe" || fail "claude-code-bundle/ FALTA"
[ -f "$REPO_DIR/install.sh" ] && [ -x "$REPO_DIR/install.sh" ] && ok "install.sh executável" || fail "install.sh FALTA"

# Templates
TEMPLATES=$(ls "$REPO_DIR/templates/" 2>/dev/null | wc -l | tr -d ' ')
if [ "$TEMPLATES" -ge 7 ]; then
  ok "$TEMPLATES templates"
else
  warn "Esperado ≥7 templates, encontrado $TEMPLATES"
fi

# ── 5. Cobertura retroativa ─────────────────────────────
info ""
info "▼ 5. Cobertura retroativa do ecossistema"
PROTECTED=0; TOTAL_P=0
for d in $HOME/PROJETOS/*/ $HOME/your-project/; do
  N=$(basename "$d")
  [ "$N" = "THIDEBRITO-SECURITY" ] && continue
  TOTAL_P=$((TOTAL_P+1))
  [ -f "$d.security-applied" ] && PROTECTED=$((PROTECTED+1))
done
PCT=$((PROTECTED * 100 / TOTAL_P))
if [ "$PCT" -ge 95 ]; then
  ok "Cobertura: $PROTECTED/$TOTAL_P ($PCT%)"
elif [ "$PCT" -ge 70 ]; then
  warn "Cobertura: $PROTECTED/$TOTAL_P ($PCT%) — abaixo do ideal (95%+)"
else
  fail "Cobertura: $PROTECTED/$TOTAL_P ($PCT%) — crítico"
fi

# ── 6. Dependências ─────────────────────────────────────
info ""
info "▼ 6. Dependências externas"
command -v git >/dev/null && ok "git instalado ($(git --version | cut -d' ' -f3))" || fail "git FALTA"
command -v node >/dev/null && ok "node instalado ($(node --version))" || fail "node FALTA"
command -v python3 >/dev/null && ok "python3 instalado ($(python3 --version | cut -d' ' -f2))" || fail "python3 FALTA"
command -v gitleaks >/dev/null && ok "gitleaks instalado ($(gitleaks version))" || warn "gitleaks NÃO instalado (recomendado)"

# ── 7. Sites em prod (opcional) ─────────────────────────
if [ "$CHECK_PROD" -eq 1 ]; then
  info ""
  info "▼ 7. Sites em prod"
  for url in https://www.yourdomain.com https://ia1.yourdomain.com/quiz; do
    CODE=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 5 "$url" 2>/dev/null)
    if [ "$CODE" = "200" ]; then
      ok "$url → 200"
    else
      warn "$url → $CODE"
    fi
  done
fi

# ── Resultado final ─────────────────────────────────────
TOTAL=$((PASS + FAIL + WARN))

# Em modo --quiet, só printar se tiver erros
if [ $QUIET -eq 0 ] || [ $FAIL -gt 0 ]; then
  info ""
  info "═══════════════════════════════════════════════════════════════"
  echo "📊 RESULTADO: $PASS OK · $WARN warnings · $FAIL erros (total: $TOTAL)"
  info "═══════════════════════════════════════════════════════════════"
fi

if [ $FAIL -gt 0 ]; then
  echo ""
  echo "❌ Sistema com falhas. Recomendações:"
  echo "  - Rodar: bash install.sh"
  echo "  - Verificar guia: ~/Downloads/THIDEBRITO-PROPRIEDADE-INTELECTUAL-SECURITY.md"
  exit 1
elif [ $WARN -gt 0 ] && [ $QUIET -eq 0 ]; then
  echo ""
  echo "⚠️  Sistema funcional com $WARN warning(s). Considere investigar."
  exit 0
elif [ $QUIET -eq 0 ]; then
  echo ""
  echo "✅ Tudo perfeito!"
  exit 0
else
  exit 0
fi
