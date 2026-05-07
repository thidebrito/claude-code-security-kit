#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# pre-deploy.sh — Wrapper pra HTML puro / projetos sem Vite
#
# Roda protect-build.mjs antes do deploy.
#
# Uso (no diretório do projeto):
#   bash ~/PROJETOS/claude-code-security-kit/scripts/pre-deploy.sh
#
# Ou adicionar ao vercel.json do projeto:
#   {
#     "buildCommand": "bash $HOME/PROJETOS/THIDEBRITO-SECURITY/scripts/pre-deploy.sh"
#   }
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

PROJECT_PATH="${1:-$(pwd)}"
SECURITY_REPO="$(cd "$(dirname "$0")/.." && pwd)"

# Resolver path absoluto
PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"

echo "🛡️  pre-deploy.sh"
echo "   Projeto: $PROJECT_PATH"
echo "   Security repo: $SECURITY_REPO"
echo ""

# Pre-checagens
if [ ! -d "$PROJECT_PATH" ]; then
  echo "❌ Projeto não existe: $PROJECT_PATH"
  exit 2
fi

# Detectar build dir ou raiz
BUILD_DIR=""
for d in dist build out; do
  if [ -d "$PROJECT_PATH/$d" ]; then
    BUILD_DIR="$d"
    break
  fi
done

if [ -z "$BUILD_DIR" ] && [ ! -f "$PROJECT_PATH/index.html" ]; then
  echo "⚠️  Nenhum dist/, build/, out/ ou index.html encontrado."
  echo "   Rode 'npm run build' antes ou trabalhe em raiz com index.html"
  exit 0  # não bloqueia
fi

# Rodar protect-build
DIST_FLAG=""
[ -n "$BUILD_DIR" ] && DIST_FLAG="--dist-dir $BUILD_DIR"

echo "🚀 Rodando protect-build.mjs..."
node "$SECURITY_REPO/scripts/protect-build.mjs" "$PROJECT_PATH" $DIST_FLAG "$@"

EC=$?
if [ $EC -ne 0 ]; then
  echo "⚠️  protect-build falhou (exit $EC). Deploy continua sem proteção."
  exit 0  # não bloqueia o deploy
fi

echo ""
echo "✅ Pre-deploy concluído. Pode rodar 'vercel deploy --prod' agora."
