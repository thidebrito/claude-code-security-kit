#!/bin/bash
# block-secrets-commit.sh — Hook PreToolUse (matcher Bash)
# Bloqueia comandos git que poderiam subir secrets para repos remotos.
#
# O que bloqueia:
#   1. "git add .env" ou "git add .env.local" (exceto .env.example)
#   2. "git commit -a" se houver .env* staged
#   3. "git push" se o ultimo commit tem arquivo .env* (exceto .env.example)
#   4. Strings de secret em staged diff: sk-, ghp_, AIza[...], Bearer <token>
#      (apenas aviso no push, nao bloqueia — poderia ter muitos falsos positivos)
#
# Como funciona:
#   - Exit 0 = permite. Exit 2 + stderr = bloqueia (Claude ve a mensagem).
#
# Retorno JSON:
#   { "decision": "block", "reason": "<motivo>" }

set -e

DATA=$(cat 2>/dev/null || echo '{}')
CMD=$(echo "$DATA" | jq -r '.tool_input.command // ""' 2>/dev/null)

# Rapido exit se nao e git
case "$CMD" in
  *"git add"*|*"git commit"*|*"git push"*) ;;
  *) exit 0 ;;
esac

BLOCK_REASON=""

# ── 1. git add .env* (exceto .env.example) ────────────────────────────────
if echo "$CMD" | grep -qE 'git +add +[^ ]*\.env[^ ]*'; then
  if echo "$CMD" | grep -qvE 'git +add +[^ ]*\.env\.(example|sample|template)'; then
    # Pode ser "git add .env.local" ou "git add ." — verifica nao esta adicionando .env
    if echo "$CMD" | grep -qE 'git +add +[^ ]*\.env(\.local|\.production|[^a-z]|$)'; then
      BLOCK_REASON="BLOQUEADO: tentativa de git add em arquivo .env (potencial leak de secrets). Use .env.example para templates."
    fi
  fi
fi

# ── 2. git commit -a com .env* staged ─────────────────────────────────────
if [ -z "$BLOCK_REASON" ] && echo "$CMD" | grep -qE 'git +commit.*-[aA]'; then
  # Staged files potenciais (commit -a stagea tudo modificado)
  # Checa se existem .env* modificados que NAO sao .example/.sample
  MODIFIED_ENV=$(git status --porcelain 2>/dev/null | grep -E '^ ?M +\.env' | grep -vE '\.env\.(example|sample|template)' || true)
  if [ -n "$MODIFIED_ENV" ]; then
    BLOCK_REASON="BLOQUEADO: git commit -a com .env modificado detectado: $MODIFIED_ENV"
  fi
fi

# ── 3. git push com .env* em qualquer commit pending ──────────────────────
if [ -z "$BLOCK_REASON" ] && echo "$CMD" | grep -qE '^[^&|;]*git +push'; then
  # Arquivos nos commits entre origin/main e HEAD que matcham .env* (nao example)
  RISKY=$(git log origin/main..HEAD --name-only --pretty=format: 2>/dev/null | sort -u | grep -E '(^|/)\.env' | grep -vE '\.env\.(example|sample|template)' || true)
  if [ -n "$RISKY" ]; then
    BLOCK_REASON="BLOQUEADO: git push com arquivo .env em commit pendente: $RISKY"
  fi
fi

# ── 4. Secret patterns no staged diff (aviso, nao bloqueia) ───────────────
if [ -z "$BLOCK_REASON" ] && echo "$CMD" | grep -qE 'git +(commit|push)'; then
  SUSPECT=$(git diff --cached 2>/dev/null | grep -oE '(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{30,}|AIza[0-9A-Za-z_-]{35}|Bearer +[a-zA-Z0-9_-]{20,})' | head -3 || true)
  if [ -n "$SUSPECT" ]; then
    BLOCK_REASON="BLOQUEADO: padrao de secret detectado no staged diff: $(echo "$SUSPECT" | head -1 | cut -c1-20)..."
  fi
fi

# Se bloqueou, retorna JSON com decision=block
if [ -n "$BLOCK_REASON" ]; then
  jq -n --arg r "$BLOCK_REASON" '{
    "hookSpecificOutput": {
      "hookEventName": "PreToolUse",
      "permissionDecision": "deny",
      "permissionDecisionReason": $r
    }
  }'
  exit 0
fi

exit 0
