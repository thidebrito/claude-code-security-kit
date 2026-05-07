#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# update.sh — Puxa updates do GitHub e re-instala
#
# Atalho pra:
#   git pull origin main
#   bash install.sh
#
# Uso:
#   cd ~/PROJETOS/claude-code-security-kit
#   bash update.sh
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

echo "🔄 Atualizando THIDEBRITO-SECURITY"
echo "   Repo: $REPO_DIR"
echo ""

# Confirmar que estamos num repo Git
if [ ! -d .git ]; then
  echo "❌ Este não é um repo Git. Use install.sh diretamente."
  exit 1
fi

# Salvar mudanças locais (se houver) num stash temporário
LOCAL_CHANGES=$(git status --short | wc -l | tr -d ' ')
if [ "$LOCAL_CHANGES" -gt 0 ]; then
  echo "⚠️  Mudanças locais detectadas:"
  git status --short | head -10
  echo ""
  read -p "Stashar mudanças e continuar? (y/N) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    git stash push -m "update.sh auto-stash $(date +%Y%m%d-%H%M%S)"
    echo "  ✅ Mudanças stashadas (recupere com: git stash pop)"
  else
    echo "Abortado. Resolva as mudanças locais primeiro."
    exit 1
  fi
fi

# Pull
echo "▼ Puxando updates do GitHub..."
BEFORE=$(git rev-parse HEAD)
git pull origin main
AFTER=$(git rev-parse HEAD)

if [ "$BEFORE" = "$AFTER" ]; then
  echo "  ✅ Já está na última versão"
  echo ""
  echo "Pulando re-instalação (nada novo)."
  exit 0
fi

echo ""
echo "📥 Updates puxados:"
git log --oneline "$BEFORE..$AFTER" | head -10
echo ""

# Re-instalar
echo "▼ Re-instalando (idempotente)..."
bash install.sh

echo ""
echo "✅ Update completo. Não esqueça de reiniciar o Claude Code se houver mudanças em skill/commands/hooks."
