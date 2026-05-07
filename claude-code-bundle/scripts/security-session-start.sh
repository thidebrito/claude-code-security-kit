#!/bin/bash
# security-session-start.sh — Hook SessionStart de segurança
#
# Roda no início de cada sessão Claude Code:
#   1. Health-check rápido (silencioso se OK)
#   2. Lista projetos sem .security-applied (avisa Claude pra propor aplicar)
#
# NÃO bloqueia. NÃO trava sessão. Só informa.
# Bypass: SECURITY_SESSION_SILENT=1
#
# Performance: <2 segundos no total.

# Garantir PATH e HOME completos (SessionStart roda em ambiente minimo)
export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}"
export HOME="${HOME:-$(eval echo ~$(whoami))}"

set +e  # Não falhar a sessão se algo der errado

if [ "${SECURITY_SESSION_SILENT:-0}" = "1" ]; then
  exit 0
fi

REPO="$HOME/PROJETOS/THIDEBRITO-SECURITY"
[ ! -d "$REPO" ] && exit 0  # sem o repo, não roda

# ── Quick health-check (max 5s; usa gtimeout no Mac se disponível) ─
TIMEOUT_CMD=""
if command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_CMD="gtimeout 5"
elif command -v timeout >/dev/null 2>&1; then
  TIMEOUT_CMD="timeout 5"
fi
HEALTH_OUT=$($TIMEOUT_CMD bash "$REPO/scripts/health-check.sh" --quiet 2>&1)
HEALTH_EC=$?

if [ "$HEALTH_EC" -ne 0 ]; then
  echo ""
  echo "🚨 [security] Health-check do sistema reportou problema:"
  echo "$HEALTH_OUT" | tail -10 | sed 's/^/   /'
  echo "   → Sugestão: bash $REPO/install.sh"
  echo ""
fi

# ── Listar projetos sem marker (rápido, só checa arquivo) ─
UNPROTECTED=()
for d in "$HOME/PROJETOS"/*/ "$HOME/your-website-repo/"; do
  [ -d "$d" ] || continue
  N=$(basename "$d")
  [ "$N" = "THIDEBRITO-SECURITY" ] && continue
  if [ ! -f "$d.security-applied" ]; then
    UNPROTECTED+=("$N")
  fi
done

if [ ${#UNPROTECTED[@]} -gt 0 ]; then
  echo ""
  echo "⚠️  [security] ${#UNPROTECTED[@]} projeto(s) SEM proteção:"
  printf '   - %s\n' "${UNPROTECTED[@]}" | head -10
  [ ${#UNPROTECTED[@]} -gt 10 ] && echo "   (+ $((${#UNPROTECTED[@]} - 10)) outros)"
  echo "   → Aplicar em todos: for p in ${UNPROTECTED[*]}; do bash $REPO/scripts/apply-template.sh ~/PROJETOS/\$p; done"
  echo ""
fi

exit 0
