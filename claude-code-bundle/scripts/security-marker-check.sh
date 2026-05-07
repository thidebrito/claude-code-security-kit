#!/bin/bash
# security-marker-check.sh — Hook PreToolUse Edit/Write
#
# Comportamento INTELIGENTE (auto-aplicar em projeto novo):
#   - Se pasta tem >5 arquivos OU foi criada há mais de 5 min → AVISA (não aplica)
#   - Se pasta tem <=5 arquivos E foi criada há <5 min → AUTO-APLICA template
#     (heurística: projeto recém-criado pelo usuário/Claude)
#
# Pra desabilitar:
#   SECURITY_MARKER_SKIP=1     → silencia tudo
#   SECURITY_NO_AUTOAPPLY=1    → só avisa, nunca aplica

if [ "${SECURITY_MARKER_SKIP:-0}" = "1" ]; then
  exit 0
fi

input=$(cat 2>/dev/null || echo '{}')

file_path=$(echo "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('file_path', ''))
except:
    pass
" 2>/dev/null)

[ -z "$file_path" ] && exit 0

# Filtrar só ~/PROJETOS/* e ~/your-project/
case "$file_path" in
  "$HOME/PROJETOS/"*) ;;
  "$HOME/your-website-repo/"*) ;;
  *) exit 0 ;;
esac

# Detectar pasta do projeto
case "$file_path" in
  "$HOME/PROJETOS/"*)
    proj=$(echo "$file_path" | sed "s|$HOME/PROJETOS/||" | cut -d'/' -f1)
    proj_path="$HOME/PROJETOS/$proj"
    ;;
  "$HOME/your-website-repo/"*)
    proj_path="$HOME/your-website-repo"
    proj="your-website-repo"
    ;;
esac

# Pular meta-projeto
[ "$proj" = "THIDEBRITO-SECURITY" ] && exit 0

# Pular pasta vazia/inexistente
[ ! -d "$proj_path" ] && exit 0

# Já tem marker? Sai.
[ -f "$proj_path/.security-applied" ] && exit 0

# ── DECISÃO: auto-aplicar OU só avisar ─────────────────
REPO="$HOME/PROJETOS/THIDEBRITO-SECURITY"

# Heurística: projeto recém-criado (poucos arquivos + criado recentemente)
NUM_FILES=$(find "$proj_path" -maxdepth 2 -type f -not -path "*/.git/*" 2>/dev/null | head -20 | wc -l | tr -d ' ')

# Idade da pasta em minutos
if [ "$(uname)" = "Darwin" ]; then
  PROJ_AGE_MIN=$(( ($(date +%s) - $(stat -f %B "$proj_path")) / 60 ))
else
  PROJ_AGE_MIN=$(( ($(date +%s) - $(stat -c %Y "$proj_path")) / 60 ))
fi

# Critério "projeto novo": <=5 arquivos E criado nos últimos 60 min
if [ "${SECURITY_NO_AUTOAPPLY:-0}" != "1" ] && \
   [ "$NUM_FILES" -le 5 ] && \
   [ "$PROJ_AGE_MIN" -lt 60 ] && \
   [ -d "$REPO" ]; then

  echo "" >&2
  echo "🤖 [security-marker-check] Projeto NOVO detectado (sem .security-applied)" >&2
  echo "    Auto-aplicando template..." >&2
  echo "    (pra desabilitar auto: export SECURITY_NO_AUTOAPPLY=1)" >&2
  echo "" >&2

  # Auto-aplicar (silencioso, só erro)
  bash "$REPO/scripts/apply-template.sh" "$proj_path" 2>&1 | grep -E "(✅|❌)" | sed 's/^/    /' >&2
  echo "" >&2
else
  # Modo aviso (projeto existente)
  echo "" >&2
  echo "⚠️  [security-marker-check] Projeto '$proj' SEM .security-applied" >&2
  echo "    → /secure-audit $proj  (pra revisar antes)" >&2
  echo "    → bash $REPO/scripts/apply-template.sh $proj_path  (pra aplicar)" >&2
  echo "    → export SECURITY_MARKER_SKIP=1  (pra silenciar nesta sessão)" >&2
  echo "" >&2
fi

exit 0
