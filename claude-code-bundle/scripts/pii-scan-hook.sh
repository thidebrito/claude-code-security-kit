#!/bin/bash
# pii-scan-hook.sh — Hook PreToolUse Bash matcher git commit
# Bloqueia commit se pii-scan.sh detectar PII no diff staged
#
# Bypass: SKIP_HOOKS=1 git commit ...

if [ "${SKIP_HOOKS:-0}" = "1" ]; then
  exit 0
fi

input=$(cat 2>/dev/null || echo '{}')
command=$(echo "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except:
    pass
" 2>/dev/null)

# Só interessa git commit
case "$command" in
  *"git commit"*) ;;
  *) exit 0 ;;
esac

# cwd
cwd=$(echo "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('cwd', ''))
except:
    pass
" 2>/dev/null)
[ -z "$cwd" ] && cwd=$(pwd)
cd "$cwd" 2>/dev/null || exit 0

# Resolver caminho do repo SECURITY
SECURITY_REPO="${THIDEBRITO_SECURITY:-$HOME/PROJETOS/THIDEBRITO-SECURITY}"
PII_SCRIPT="$SECURITY_REPO/scripts/pii-scan.sh"

if [ ! -x "$PII_SCRIPT" ]; then
  exit 0  # Script não disponível, não bloqueia
fi

# Rodar pii-scan
OUT=$(bash "$PII_SCRIPT" --staged 2>&1)
EC=$?

if [ $EC -ne 0 ]; then
  echo "" >&2
  echo "❌ [pii-scan-hook] PII DETECTADA no diff staged — commit BLOQUEADO" >&2
  echo "$OUT" >&2
  echo "" >&2
  echo "Opções:" >&2
  echo "  1. Remover/ofuscar a PII e tentar novamente" >&2
  echo "  2. Bypass de emergência: SKIP_HOOKS=1 git commit ..." >&2
  echo "" >&2
  exit 2
fi

exit 0
