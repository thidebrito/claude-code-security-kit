#!/bin/bash
# pre-deploy-guard.sh — Hook PreToolUse Bash em git push origin main / vercel deploy
#
# Bloqueia ou avisa sobre:
#   1. Pixel Meta ausente em LPs/páginas (BLOQUEIA)
#   2. Secrets conhecidos no diff staged (BLOQUEIA)
#   3. Para projetos PÚBLICOS com .security-applied: protection-manifest.json
#      ausente ou desatualizado (>24h) — só AVISA (não bloqueia)
#
# Bypass: SKIP_PREDEPLOY=1 ou SKIP_HOOKS=1

if [ "${SKIP_PREDEPLOY:-0}" = "1" ] || [ "${SKIP_HOOKS:-0}" = "1" ]; then
  exit 0
fi

input=$(cat)

command=$(echo "$input" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tool_input', {}).get('command', ''))
except:
    pass
" 2>/dev/null)

# Casos cobertos
IS_GIT_PUSH=0
IS_VERCEL_PROD=0
echo "$command" | grep -qE 'git push.*origin.*\bmain\b|git push origin main' && IS_GIT_PUSH=1
echo "$command" | grep -qE 'vercel.*(deploy.*--prod|--prod.*deploy|deploy.*production)' && IS_VERCEL_PROD=1

[ "$IS_GIT_PUSH" -eq 0 ] && [ "$IS_VERCEL_PROD" -eq 0 ] && exit 0

# Determinar cwd
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

# ── 1. Pixel Meta em arquivos HTML staged (só git push) ──
if [ "$IS_GIT_PUSH" -eq 1 ]; then
  staged_html=$(git diff --cached --name-only 2>/dev/null | grep -E '\.(html|tsx|jsx)$' || true)
  if [ -n "$staged_html" ]; then
    for f in $staged_html; do
      if [ -f "$f" ]; then
        if grep -qE 'fbq\(.init|<title>.*Do Riff|<title>.*IA na Prática|landing|<head>' "$f" 2>/dev/null; then
          if ! grep -q "YOUR_META_PIXEL_ID" "$f"; then
            echo "" >&2
            echo "❌ BLOQUEIO: Push pra main interrompido" >&2
            echo "   Arquivo: $f" >&2
            echo "   Motivo: parece ser LP/página de produto mas não tem Pixel Meta YOUR_META_PIXEL_ID" >&2
            echo "   Solução: adicione o pixel OU remova arquivo do commit (git restore --staged $f)" >&2
            echo "   Bypass: SKIP_PREDEPLOY=1 $command" >&2
            echo "" >&2
            exit 2
          fi
        fi
      fi
    done
  fi
fi

# ── 2. Secrets conhecidos no diff staged (só git push) ──
if [ "$IS_GIT_PUSH" -eq 1 ]; then
  secrets_found=$(git diff --cached 2>/dev/null | grep -ohE '(AKIA[0-9A-Z]{16}|sk_live_[a-zA-Z0-9]{24,}|ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}|xoxb-[a-zA-Z0-9-]{20,}|AIza[0-9A-Za-z_-]{35})' | head -1 || true)
  if [ -n "$secrets_found" ]; then
    echo "" >&2
    echo "❌ BLOQUEIO: Push pra main interrompido" >&2
    echo "   Motivo: secret detectado no diff staged" >&2
    echo "   Padrão: $(echo "$secrets_found" | cut -c1-10)..." >&2
    echo "   Solução: remova o secret. Use env vars ou .env (gitignore)." >&2
    echo "   Bypass: SKIP_PREDEPLOY=1 $command" >&2
    echo "" >&2
    exit 2
  fi
fi

# ── 3. Protection manifest pra projetos públicos (avisa, não bloqueia) ──
if [ -f "$cwd/.security-applied" ]; then
  PUBLIC_PROJECT=0
  for marker in "vercel.json" "next.config.js" "next.config.ts" "vite.config.js" "vite.config.ts"; do
    [ -f "$cwd/$marker" ] && PUBLIC_PROJECT=1 && break
  done
  [ -f "$cwd/index.html" ] && PUBLIC_PROJECT=1
  [ -f "$cwd/dist/index.html" ] && PUBLIC_PROJECT=1

  if [ "$PUBLIC_PROJECT" -eq 1 ]; then
    MANIFEST=""
    for c in "dist/protection-manifest.json" "build/protection-manifest.json" "out/protection-manifest.json" "protection-manifest.json"; do
      if [ -f "$cwd/$c" ]; then
        MANIFEST="$cwd/$c"
        break
      fi
    done

    if [ -z "$MANIFEST" ]; then
      echo "" >&2
      echo "⚠️  [pre-deploy] Projeto público SEM protection-manifest.json" >&2
      echo "    Recomendo rodar antes do deploy:" >&2
      echo "      node $HOME/PROJETOS/THIDEBRITO-SECURITY/scripts/protect-build.mjs $cwd" >&2
      echo "    Ou /secure-protect $cwd" >&2
      echo "" >&2
      # Não bloqueia, só avisa
    else
      if [ "$(uname)" = "Darwin" ]; then
        AGE_HOURS=$(( ($(date +%s) - $(stat -f %m "$MANIFEST")) / 3600 ))
      else
        AGE_HOURS=$(( ($(date +%s) - $(stat -c %Y "$MANIFEST")) / 3600 ))
      fi
      if [ "$AGE_HOURS" -gt 24 ]; then
        echo "" >&2
        echo "⚠️  [pre-deploy] protection-manifest.json tem ${AGE_HOURS}h (>24h)" >&2
        echo "    Considere re-rodar /secure-protect antes do deploy" >&2
        echo "" >&2
      fi
    fi
  fi
fi

exit 0
