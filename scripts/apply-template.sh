#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# apply-template.sh — Aplica templates de segurança em um projeto
#
# Faz:
#   1. Detecta tipo do projeto (web/react/node) ou usa o flag --type
#   2. Cria/atualiza .gitignore (preserva linhas existentes não-cobertas)
#   3. Cria .env.example se não existir
#   4. Instala git hook pre-commit
#   5. Cria .security-applied marker
#
# Uso:
#   ./apply-template.sh /path/to/project              # auto-detect tipo
#   ./apply-template.sh /path/to/project --type web   # força tipo
#   ./apply-template.sh /path/to/project --dry-run    # mostra o que faria
#
# IMPORTANTE: NUNCA sobrescreve .env, .git/, ou arquivos com mudanças locais
# sem confirmação (modo --force só pra reset completo)
# ═══════════════════════════════════════════════════════════════

set -euo pipefail

SECURITY_REPO="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATES_DIR="$SECURITY_REPO/templates"

PROJECT=""
TYPE=""
DRY_RUN=0
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type) TYPE="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) grep '^# ' "$0" | head -20; exit 0 ;;
    *)
      if [ -z "$PROJECT" ]; then PROJECT="$1"; shift
      else echo "Argumento desconhecido: $1"; exit 2; fi ;;
  esac
done

if [ -z "$PROJECT" ]; then
  echo "Uso: $0 <project-path> [--type web|react|node] [--dry-run]"
  exit 2
fi

if [ ! -d "$PROJECT" ]; then
  echo "❌ Diretório não existe: $PROJECT"
  exit 2
fi

PROJECT="$(cd "$PROJECT" && pwd)"
PROJ_NAME="$(basename "$PROJECT")"

# ── Auto-detect tipo se não passado ────────────────────────
if [ -z "$TYPE" ]; then
  if [ -f "$PROJECT/package.json" ]; then
    if grep -qE '"(react|vite|next)"' "$PROJECT/package.json" 2>/dev/null; then
      TYPE="react"
    else
      TYPE="node"
    fi
  elif [ -f "$PROJECT/index.html" ] || ls "$PROJECT"/*.html >/dev/null 2>&1; then
    TYPE="web"
  else
    TYPE="node"
  fi
  echo "📋 Tipo auto-detectado: $TYPE"
fi

# ── Validação tipo ─────────────────────────────────────────
case "$TYPE" in
  web|react|node) ;;
  *) echo "❌ Tipo inválido: $TYPE (use web|react|node)"; exit 2 ;;
esac

UNIVERSAL="$TEMPLATES_DIR/gitignore.universal"
SPECIFIC="$TEMPLATES_DIR/gitignore.$TYPE"

[ ! -f "$UNIVERSAL" ] && { echo "❌ Template não encontrado: $UNIVERSAL"; exit 2; }
[ ! -f "$SPECIFIC" ] && { echo "❌ Template não encontrado: $SPECIFIC"; exit 2; }

echo ""
echo "🛡️  Aplicando templates de segurança em: $PROJ_NAME"
echo "    Path: $PROJECT"
echo "    Tipo: $TYPE"
echo "    Dry-run: $([ $DRY_RUN -eq 1 ] && echo "SIM" || echo "não")"
echo ""

# ── 1. .gitignore: merge ───────────────────────────────────
GITIGNORE_TARGET="$PROJECT/.gitignore"
GITIGNORE_NEW="/tmp/gitignore-merged-$$"

cat "$UNIVERSAL" > "$GITIGNORE_NEW"
echo "" >> "$GITIGNORE_NEW"
cat "$SPECIFIC" >> "$GITIGNORE_NEW"

# Se já existe um .gitignore, preservar linhas customizadas
if [ -f "$GITIGNORE_TARGET" ]; then
  CUSTOM_LINES=$(grep -v '^#' "$GITIGNORE_TARGET" | grep -v '^$' | sort -u | comm -23 - <(grep -v '^#' "$GITIGNORE_NEW" | grep -v '^$' | sort -u) || true)
  if [ -n "$CUSTOM_LINES" ]; then
    echo "" >> "$GITIGNORE_NEW"
    echo "# ── Linhas custom preservadas do .gitignore original ──" >> "$GITIGNORE_NEW"
    echo "$CUSTOM_LINES" >> "$GITIGNORE_NEW"
  fi
fi

if [ $DRY_RUN -eq 1 ]; then
  echo "  [DRY] .gitignore seria atualizado ($(wc -l < "$GITIGNORE_NEW") linhas)"
else
  # Backup do antigo se existir
  if [ -f "$GITIGNORE_TARGET" ] && [ $FORCE -eq 0 ]; then
    cp "$GITIGNORE_TARGET" "$GITIGNORE_TARGET.bak.$(date +%Y%m%d-%H%M)"
  fi
  mv "$GITIGNORE_NEW" "$GITIGNORE_TARGET"
  echo "  ✅ .gitignore atualizado ($(wc -l < "$GITIGNORE_TARGET") linhas)"
fi

# ── 2. .env.example ────────────────────────────────────────
ENV_EXAMPLE_TARGET="$PROJECT/.env.example"
if [ ! -f "$ENV_EXAMPLE_TARGET" ]; then
  if [ $DRY_RUN -eq 1 ]; then
    echo "  [DRY] .env.example seria criado"
  else
    cp "$TEMPLATES_DIR/env.example.template" "$ENV_EXAMPLE_TARGET"
    echo "  ✅ .env.example criado"
  fi
else
  echo "  ⏭  .env.example já existe (preservado)"
fi

# ── 3. git hook pre-commit ─────────────────────────────────
if [ -d "$PROJECT/.git" ]; then
  HOOK_TARGET="$PROJECT/.git/hooks/pre-commit"
  if [ -f "$HOOK_TARGET" ] && [ $FORCE -eq 0 ]; then
    echo "  ⚠️  pre-commit hook já existe (preservado, use --force pra substituir)"
  else
    if [ $DRY_RUN -eq 1 ]; then
      echo "  [DRY] pre-commit hook seria instalado"
    else
      cp "$TEMPLATES_DIR/pre-commit.sh.template" "$HOOK_TARGET"
      chmod +x "$HOOK_TARGET"
      echo "  ✅ pre-commit hook instalado"
    fi
  fi
else
  echo "  ⏭  Não é repo Git (pre-commit não instalado)"
fi

# ── 4. .security-applied marker ────────────────────────────
MARKER_TARGET="$PROJECT/.security-applied"
if [ $DRY_RUN -eq 1 ]; then
  echo "  [DRY] .security-applied seria criado/atualizado"
else
  cat > "$MARKER_TARGET" <<EOF
{
  "version": "1.0.0",
  "applied_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "applied_by": "thidebrito",
  "level": "B",
  "templates_used": [
    "gitignore.universal",
    "gitignore.$TYPE",
    "env.example.template",
    "pre-commit.sh.template"
  ],
  "git_hooks_installed": [$([ -d "$PROJECT/.git" ] && echo '"pre-commit"' || echo '')],
  "audit_report": null,
  "security_repo_version": "1.0.0",
  "notes": ""
}
EOF
  echo "  ✅ .security-applied marker criado"
fi

echo ""
echo "🛡️  Aplicação concluída em: $PROJ_NAME"
echo ""
if [ $DRY_RUN -eq 0 ]; then
  echo "Próximos passos sugeridos:"
  echo "  1. cd $PROJECT && git status   (revisar mudanças no .gitignore)"
  echo "  2. git add .gitignore .env.example .security-applied"
  echo "  3. git commit -m 'chore: aplicar templates de segurança THIDEBRITO-SECURITY'"
fi
