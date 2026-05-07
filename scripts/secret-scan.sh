#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# secret-scan.sh — Wrapper de gitleaks pra scan de segredos
#
# Uso:
#   ./secret-scan.sh                       # Scan staged + últimos 50 commits do repo atual
#   ./secret-scan.sh --staged              # Apenas diff staged
#   ./secret-scan.sh --history             # Últimos 50 commits
#   ./secret-scan.sh --full                # História completa (lento, nível c)
#   ./secret-scan.sh --path /path/to/repo  # Scan de outro repo
#   ./secret-scan.sh --json out.json       # Output em JSON pra audit-projects
# ═══════════════════════════════════════════════════════════════

set -uo pipefail

REPO_PATH="$(pwd)"
MODE="full-staged-and-history"
JSON_OUT=""
COMMIT_LIMIT=50

while [[ $# -gt 0 ]]; do
  case "$1" in
    --staged) MODE="staged"; shift ;;
    --history) MODE="history"; shift ;;
    --full) MODE="full"; shift ;;
    --path) REPO_PATH="$2"; shift 2 ;;
    --json) JSON_OUT="$2"; shift 2 ;;
    --limit) COMMIT_LIMIT="$2"; shift 2 ;;
    -h|--help)
      grep '^# ' "$0" | head -20
      exit 0
      ;;
    *) echo "Opção desconhecida: $1"; exit 2 ;;
  esac
done

if ! command -v gitleaks >/dev/null 2>&1; then
  echo "❌ gitleaks não instalado. Rode: brew install gitleaks"
  exit 2
fi

if [ ! -d "$REPO_PATH/.git" ]; then
  echo "⚠️  Não é repo Git: $REPO_PATH"
  exit 0
fi

cd "$REPO_PATH"

EXIT_CODE=0
JSON_FLAG=""
if [ -n "$JSON_OUT" ]; then
  JSON_FLAG="--report-path=$JSON_OUT --report-format=json"
fi

case "$MODE" in
  staged)
    echo "🔐 [secret-scan] Modo: STAGED em $REPO_PATH"
    gitleaks protect --staged --redact --no-banner $JSON_FLAG || EXIT_CODE=$?
    ;;
  history)
    echo "🔐 [secret-scan] Modo: HISTORY (últimos $COMMIT_LIMIT commits) em $REPO_PATH"
    gitleaks detect --redact --no-banner --log-opts="--max-count=$COMMIT_LIMIT" $JSON_FLAG || EXIT_CODE=$?
    ;;
  full)
    echo "🔐 [secret-scan] Modo: FULL HISTORY em $REPO_PATH (pode demorar)"
    gitleaks detect --redact --no-banner $JSON_FLAG || EXIT_CODE=$?
    ;;
  full-staged-and-history)
    echo "🔐 [secret-scan] Modo: STAGED + HISTORY em $REPO_PATH"
    gitleaks protect --staged --redact --no-banner || EXIT_CODE=$?
    gitleaks detect --redact --no-banner --log-opts="--max-count=$COMMIT_LIMIT" $JSON_FLAG || EXIT_CODE=$?
    ;;
esac

if [ $EXIT_CODE -eq 0 ]; then
  echo "✅ secret-scan: SEM segredos detectados"
else
  echo "❌ secret-scan: SEGREDOS DETECTADOS — revisar imediatamente"
fi

exit $EXIT_CODE
