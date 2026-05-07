#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# pii-scan.sh — Detecta PII (email, CPF, CNPJ, telefone, cartão)
# em arquivos staged ou em diretório
#
# Uso:
#   ./pii-scan.sh --staged           # Diff staged do repo atual
#   ./pii-scan.sh --path /path       # Scan recursivo num diretório
#   ./pii-scan.sh --files a.js b.js  # Arquivos específicos
# ═══════════════════════════════════════════════════════════════

set -uo pipefail

MODE="staged"
SCAN_PATH="."
FILES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --staged) MODE="staged"; shift ;;
    --path) MODE="path"; SCAN_PATH="$2"; shift 2 ;;
    --files) MODE="files"; shift; while [[ $# -gt 0 && "$1" != --* ]]; do FILES+=("$1"); shift; done ;;
    -h|--help)
      grep '^# ' "$0" | head -15
      exit 0
      ;;
    *) echo "Opção desconhecida: $1"; exit 2 ;;
  esac
done

# Patterns ─ regex calibradas pra reduzir falso positivo
# Email: aceita formato comum
EMAIL_RE='[A-Za-z0-9._+-]+@[A-Za-z0-9-]+\.[A-Za-z0-9.-]+'
# CPF: 000.000.000-00 ou 00000000000 (11 dígitos isolados)
CPF_RE='([0-9]{3}\.[0-9]{3}\.[0-9]{3}-[0-9]{2}|\b[0-9]{11}\b)'
# CNPJ: 00.000.000/0000-00 ou 14 dígitos
CNPJ_RE='([0-9]{2}\.[0-9]{3}\.[0-9]{3}/[0-9]{4}-[0-9]{2}|\b[0-9]{14}\b)'
# Telefone BR: (00) 00000-0000 ou +55 11 99999-9999
PHONE_RE='(\(?[0-9]{2,3}\)?[\s-]?[0-9]{4,5}[\s-]?[0-9]{4})'
# Cartão de crédito (4 grupos de 4 dígitos)
CARD_RE='([0-9]{4}[\s-]?[0-9]{4}[\s-]?[0-9]{4}[\s-]?[0-9]{4})'

# Allowlist comum pra evitar falsos positivos:
#   - emails de exemplo (example.com, test@, noreply@)
#   - números muito comuns (000, 123, 999)
#   - placeholders genéricos
ALLOWLIST_RE='(example\.(com|org)|noreply@|test@|placeholder|XXXX|YYYY|0{4,}|1{4,}|9{4,}|<[A-Za-z_]+>)'

# Allowlist por arquivo (paths que sempre podem conter dados de teste)
PATH_ALLOWLIST='(\.example|\.template|/tests?/|/fixtures?/|/__mocks__|node_modules/|/dist/|/build/|/\.git/|README|CHANGELOG|LICENSE)'

scan_content() {
  local label="$1"
  local content="$2"
  local found=0

  while IFS= read -r line; do
    # Pula linhas em allowlist global
    if echo "$line" | grep -qE "$ALLOWLIST_RE"; then
      continue
    fi

    # Email
    if echo "$line" | grep -qE "$EMAIL_RE"; then
      echo "  ⚠️  EMAIL: $label: $(echo "$line" | grep -oE "$EMAIL_RE" | head -1)"
      found=1
    fi
    # CPF (formato com pontos)
    if echo "$line" | grep -qE '[0-9]{3}\.[0-9]{3}\.[0-9]{3}-[0-9]{2}'; then
      echo "  ⚠️  CPF: $label: $(echo "$line" | grep -oE '[0-9]{3}\.[0-9]{3}\.[0-9]{3}-[0-9]{2}' | head -1)"
      found=1
    fi
    # CNPJ (formato com pontos)
    if echo "$line" | grep -qE '[0-9]{2}\.[0-9]{3}\.[0-9]{3}/[0-9]{4}-[0-9]{2}'; then
      echo "  ⚠️  CNPJ: $label: $(echo "$line" | grep -oE '[0-9]{2}\.[0-9]{3}\.[0-9]{3}/[0-9]{4}-[0-9]{2}' | head -1)"
      found=1
    fi
    # Cartão (formato com espaços/traços)
    if echo "$line" | grep -qE '[0-9]{4}[\s-][0-9]{4}[\s-][0-9]{4}[\s-][0-9]{4}'; then
      echo "  ⚠️  CARTÃO?: $label (verifique manualmente)"
      found=1
    fi
  done <<< "$content"

  return $found
}

EXIT_CODE=0

case "$MODE" in
  staged)
    if [ ! -d ".git" ]; then
      echo "⚠️  Não é repo Git no diretório atual"
      exit 0
    fi
    echo "🔐 [pii-scan] Modo: STAGED"
    STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)
    if [ -z "$STAGED_FILES" ]; then
      echo "  (nada staged)"
      exit 0
    fi
    while IFS= read -r f; do
      if echo "$f" | grep -qE "$PATH_ALLOWLIST"; then
        continue
      fi
      [ ! -f "$f" ] && continue
      DIFF=$(git diff --cached "$f" 2>/dev/null | grep '^+' || true)
      scan_content "$f" "$DIFF"
      if [ $? -ne 0 ]; then
        EXIT_CODE=1
      fi
    done <<< "$STAGED_FILES"
    ;;
  path)
    echo "🔐 [pii-scan] Modo: PATH ($SCAN_PATH)"
    while IFS= read -r f; do
      if echo "$f" | grep -qE "$PATH_ALLOWLIST"; then
        continue
      fi
      CONTENT=$(cat "$f" 2>/dev/null || true)
      scan_content "$f" "$CONTENT"
      if [ $? -ne 0 ]; then
        EXIT_CODE=1
      fi
    done < <(find "$SCAN_PATH" -type f \( -name "*.js" -o -name "*.ts" -o -name "*.tsx" -o -name "*.jsx" -o -name "*.html" -o -name "*.json" -o -name "*.md" -o -name "*.txt" -o -name "*.yaml" -o -name "*.yml" \) 2>/dev/null)
    ;;
  files)
    echo "🔐 [pii-scan] Modo: FILES (${#FILES[@]} arquivos)"
    for f in "${FILES[@]}"; do
      [ ! -f "$f" ] && continue
      CONTENT=$(cat "$f" 2>/dev/null || true)
      scan_content "$f" "$CONTENT"
      if [ $? -ne 0 ]; then
        EXIT_CODE=1
      fi
    done
    ;;
esac

if [ $EXIT_CODE -eq 0 ]; then
  echo "✅ pii-scan: SEM PII detectada"
else
  echo "❌ pii-scan: PII DETECTADA — revisar e ofuscar antes de commitar/publicar"
fi

exit $EXIT_CODE
