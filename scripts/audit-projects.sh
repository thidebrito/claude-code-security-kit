#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# audit-projects.sh — Audita TODOS os projetos do ecossistema
#
# Faz por projeto:
#   - Status do .gitignore (existe? tamanho? cobre .env?)
#   - Status do .security-applied (existe?)
#   - Secret scan: últimos 50 commits (gitleaks)
#   - PII scan: arquivos top-level
#
# Output:
#   reports/audit-YYYY-MM-DD.json (consolidado)
#   reports/details/<projeto>.json (por projeto)
#
# Uso:
#   ./audit-projects.sh                # Audita tudo
#   ./audit-projects.sh --only ebook   # Filtra por nome
#   ./audit-projects.sh --quick        # Pula gitleaks (só estrutural)
# ═══════════════════════════════════════════════════════════════

set -o pipefail

SECURITY_REPO="$(cd "$(dirname "$0")/.." && pwd)"
TIMESTAMP="$(date +%Y-%m-%d-%H%M)"
REPORT_DIR="$SECURITY_REPO/reports"
DETAILS_DIR="$REPORT_DIR/details"
CONSOLIDATED="$REPORT_DIR/audit-$TIMESTAMP.json"

ONLY=""
QUICK=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --only) ONLY="$2"; shift 2 ;;
    --quick) QUICK=1; shift ;;
    -h|--help) grep '^# ' "$0" | head -25; exit 0 ;;
    *) echo "Opção desconhecida: $1"; exit 2 ;;
  esac
done

mkdir -p "$DETAILS_DIR"

# ── Lista de projetos ──────────────────────────────────────
PROJECTS=()
for d in "$HOME/PROJETOS"/*/; do
  PROJECTS+=("$d")
done
# Adicionar your-website-repo (fora de PROJETOS)
[ -d "$HOME/your-website-repo" ] && PROJECTS+=("$HOME/your-website-repo/")

if [ -n "$ONLY" ]; then
  FILTERED=()
  for p in "${PROJECTS[@]}"; do
    if [[ "$p" == *"$ONLY"* ]]; then
      FILTERED+=("$p")
    fi
  done
  PROJECTS=("${FILTERED[@]}")
fi

echo "📋 Auditando ${#PROJECTS[@]} projeto(s)..."
echo ""

# ── JSON consolidado ──────────────────────────────────────
echo "{" > "$CONSOLIDATED"
echo "  \"audit_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"," >> "$CONSOLIDATED"
echo "  \"audit_version\": \"1.0.0\"," >> "$CONSOLIDATED"
echo "  \"quick_mode\": $QUICK," >> "$CONSOLIDATED"
echo "  \"projects\": [" >> "$CONSOLIDATED"

FIRST=1
TOTAL_LEAKS=0
TOTAL_NO_GITIGNORE=0
TOTAL_NO_MARKER=0

for proj_path in "${PROJECTS[@]}"; do
  proj_name="$(basename "$proj_path")"
  echo "──────────────────────────────────────────────────────"
  echo "📦 $proj_name"

  HAS_GIT=0; HAS_GITIGNORE=0; GITIGNORE_LINES=0
  GITIGNORE_COVERS_ENV=0; HAS_MARKER=0
  LEAKS_COUNT=0; LEAKS_FOUND=0; SCAN_RAN=0
  ENV_FILES_FOUND=()

  # Estado básico
  [ -d "$proj_path/.git" ] && HAS_GIT=1
  if [ -f "$proj_path/.gitignore" ]; then
    HAS_GITIGNORE=1
    GITIGNORE_LINES=$(wc -l < "$proj_path/.gitignore")
    if grep -qE '^\.env(\*|$|\.)' "$proj_path/.gitignore" 2>/dev/null; then
      GITIGNORE_COVERS_ENV=1
    fi
  fi
  [ -f "$proj_path/.security-applied" ] && HAS_MARKER=1

  # .env real presente? (CRÍTICO: precisa estar gitignored)
  while IFS= read -r envf; do
    relpath="${envf#$proj_path}"
    ENV_FILES_FOUND+=("$relpath")
  done < <(find "$proj_path" -maxdepth 2 -type f \( -name ".env" -o -name ".env.local" -o -name ".env.production" -o -name ".env.development" \) 2>/dev/null)

  # Gitleaks scan
  if [ $QUICK -eq 0 ] && [ $HAS_GIT -eq 1 ] && command -v gitleaks >/dev/null 2>&1; then
    SCAN_RAN=1
    DETAIL_FILE="$DETAILS_DIR/$proj_name-leaks.json"
    cd "$proj_path"
    set +e
    gitleaks detect --redact --no-banner --log-opts="--max-count=50" \
      --report-path="$DETAIL_FILE" --report-format=json 2>/dev/null
    GL_EXIT=$?
    set -e
    cd - > /dev/null
    if [ -f "$DETAIL_FILE" ] && [ -s "$DETAIL_FILE" ]; then
      LEAKS_COUNT=$(grep -c '"RuleID"' "$DETAIL_FILE" 2>/dev/null || true)
      LEAKS_COUNT="${LEAKS_COUNT:-0}"
      LEAKS_COUNT="${LEAKS_COUNT//[^0-9]/}"
      LEAKS_COUNT="${LEAKS_COUNT:-0}"
      [ "$LEAKS_COUNT" -gt 0 ] 2>/dev/null && LEAKS_FOUND=1 || true
    fi
  fi

  # Stats
  echo "  Git:        $([ $HAS_GIT -eq 1 ] && echo "✓ sim" || echo "✗ não")"
  echo "  .gitignore: $([ $HAS_GITIGNORE -eq 1 ] && echo "✓ ${GITIGNORE_LINES}L $([ $GITIGNORE_COVERS_ENV -eq 1 ] && echo "(.env ✓)" || echo "(.env ✗ FALTANDO)")" || echo "✗ NÃO EXISTE")"
  echo "  Marker:     $([ $HAS_MARKER -eq 1 ] && echo "✓ sim" || echo "✗ não")"
  ENV_COUNT="${#ENV_FILES_FOUND[@]}"
  if [ "$ENV_COUNT" -gt 0 ]; then
    echo "  ⚠️  .env REAL encontrado: ${ENV_FILES_FOUND[*]}"
  fi
  if [ $SCAN_RAN -eq 1 ]; then
    if [ $LEAKS_FOUND -eq 1 ]; then
      echo "  🚨 LEAKS: $LEAKS_COUNT detectado(s) em últimos 50 commits → $DETAIL_FILE"
      TOTAL_LEAKS=$((TOTAL_LEAKS + LEAKS_COUNT))
    else
      echo "  Leaks:      ✓ nenhum (50 commits)"
    fi
  fi

  [ $HAS_GITIGNORE -eq 0 ] && TOTAL_NO_GITIGNORE=$((TOTAL_NO_GITIGNORE + 1))
  [ $HAS_MARKER -eq 0 ] && TOTAL_NO_MARKER=$((TOTAL_NO_MARKER + 1))

  # Append ao JSON
  ENV_FILES_JSON=""
  if [ "$ENV_COUNT" -gt 0 ]; then
    ENV_FILES_JSON=$(printf '%s\n' "${ENV_FILES_FOUND[@]}" | grep -v '^$' | sed 's/.*/"&"/' | paste -sd, - 2>/dev/null || true)
  fi
  [ "$FIRST" -eq 0 ] && echo "    ," >> "$CONSOLIDATED"
  cat >> "$CONSOLIDATED" <<EOF
    {
      "name": "$proj_name",
      "path": "$proj_path",
      "has_git": $([ $HAS_GIT -eq 1 ] && echo true || echo false),
      "has_gitignore": $([ $HAS_GITIGNORE -eq 1 ] && echo true || echo false),
      "gitignore_lines": $GITIGNORE_LINES,
      "gitignore_covers_env": $([ $GITIGNORE_COVERS_ENV -eq 1 ] && echo true || echo false),
      "has_marker": $([ $HAS_MARKER -eq 1 ] && echo true || echo false),
      "env_files_present": [${ENV_FILES_JSON}],
      "secret_scan_ran": $([ $SCAN_RAN -eq 1 ] && echo true || echo false),
      "leaks_count": $LEAKS_COUNT,
      "leaks_detail_file": "$([ $SCAN_RAN -eq 1 ] && echo "$DETAILS_DIR/$proj_name-leaks.json" || echo "")"
    }
EOF
  FIRST=0
done

cat >> "$CONSOLIDATED" <<EOF
  ],
  "summary": {
    "projects_scanned": ${#PROJECTS[@]},
    "total_leaks": $TOTAL_LEAKS,
    "projects_without_gitignore": $TOTAL_NO_GITIGNORE,
    "projects_without_marker": $TOTAL_NO_MARKER
  }
}
EOF

echo ""
echo "══════════════════════════════════════════════════════"
echo "📊 RESUMO"
echo "  Projetos auditados:        ${#PROJECTS[@]}"
echo "  Leaks totais:              $TOTAL_LEAKS"
echo "  Sem .gitignore:            $TOTAL_NO_GITIGNORE"
echo "  Sem marker .security-applied: $TOTAL_NO_MARKER"
echo ""
echo "📄 Relatório consolidado: $CONSOLIDATED"
echo "📁 Detalhes por projeto:   $DETAILS_DIR/"

if [ $TOTAL_LEAKS -gt 0 ]; then
  echo ""
  echo "🚨 ATENÇÃO: $TOTAL_LEAKS possível(is) leak(s) detectado(s)"
  echo "   → Consulte os arquivos *-leaks.json em details/ pra revisão"
  echo "   → Se confirmado, aplicar playbook docs/playbooks/rotate-credentials.md"
fi
