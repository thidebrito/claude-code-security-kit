---
name: seguranca-projeto
description: Sistema de Segurança Always-On do ecossistema Your Name. Aciona AUTOMATICAMENTE em qualquer trabalho dentro de ~/PROJETOS/* ou ~/your-project — verifica .security-applied marker, alerta projetos sem proteção, recomenda /secure-audit ou /secure-init, valida pre-commit hooks, monitora vazamento de credenciais. Fonte canônica em ~/PROJETOS/claude-code-security-kit/.
---

# Sistema de Segurança — Always On

## Quando acionar (obrigatório)

**SEMPRE que detectar trabalho dentro de:**
- `~/PROJETOS/*/` (qualquer projeto)
- `~/your-project/`

**Exceção:** o próprio repo `~/PROJETOS/claude-code-security-kit/` (meta-projeto, não precisa de marker).

## Checklist obrigatório (rodar nesta ordem)

### 1. Verificar `.security-applied` marker

```bash
PROJ_PATH=<path do projeto>
[ -f "$PROJ_PATH/.security-applied" ] && echo "PROTEGIDO" || echo "DESPROTEGIDO"
```

- **PROTEGIDO** → seguir trabalho normal
- **DESPROTEGIDO** → ação imediata:
  - **Para projeto NOVO (acabou de ser criado)** → **EXECUTAR AUTOMATICAMENTE** sem perguntar:
    ```bash
    bash ~/PROJETOS/claude-code-security-kit/scripts/apply-template.sh <pasta>
    ```
    É proteção básica, sem efeitos colaterais. Não precisa pedir confirmação pra coisa que torna o projeto mais seguro.
  - **Para projeto EXISTENTE com mudanças** → **PERGUNTAR antes** de aplicar:
    "Esse projeto não tem `.security-applied`. Posso rodar `/secure-audit <pasta>` antes de mexermos?"
  - **Bypass de emergência:** `export SECURITY_MARKER_SKIP=1` na sessão

### 2. Verificar `.gitignore` mínimo

Se o projeto tem `.git/`, validar se `.gitignore` cobre:
- `.env*` (exceto `.env.example`)
- `*.pem`, `*.key`, `secrets.json`, `credentials.json`
- `node_modules/`, `dist/`, `.vercel/`
- `.DS_Store`, `.claude/worktrees/`

Se faltar, recomendar aplicar template:
```bash
bash ~/PROJETOS/claude-code-security-kit/scripts/apply-template.sh "$PROJ_PATH"
```

### 3. Detectar `.env` real não-gitignored

```bash
find "$PROJ_PATH" -maxdepth 2 -name ".env*" -not -name "*.example" -not -name "*.template" 2>/dev/null
```

Se houver `.env` real:
- ⚠️ ALERTAR imediatamente
- Confirmar que está no `.gitignore`
- Se já foi commitado uma vez: aplicar playbook `~/PROJETOS/claude-code-security-kit/docs/playbooks/rotate-credentials.md`

### 4. Pre-deploy de projeto público (LP, blog, app PWA)

Antes de `vercel deploy --prod`:
```bash
/secure-protect <pasta>
```

Pipeline aplica: UUID + watermark + SHA-256 + OpenTimestamps.

## Comandos disponíveis

| Comando | Quando usar |
|---------|-------------|
| `/secure-init <pasta>` | Projeto NOVO — aplica todos os templates de uma vez |
| `/secure-audit [pasta]` | Auditar projeto existente, gera relatório, recomenda correções |
| `/secure-protect <pasta>` | Antes de deploy de projeto público — aplica Camada C |

## Hooks ativos no Claude Code

Esses hooks rodam automaticamente, mas é bom saber:

| Hook | Quando | O que faz |
|------|--------|-----------|
| `block-secrets-commit.sh` | PreToolUse Bash matcher `git commit/add/push` | Bloqueia commit de `.env*` |
| `pii-scan-hook.sh` | PreToolUse Bash matcher `git commit` | Bloqueia commit com PII (email, CPF, telefone) no diff |
| `security-marker-check.sh` | PreToolUse Edit/Write em projetos | Avisa se projeto sem `.security-applied` |
| `pre-deploy-guard.sh` | PreToolUse Bash matcher `git push origin main` | Bloqueia se faltar Pixel Meta ou tiver secret |

## Bypass de emergência (USAR COM CUIDADO)

```bash
SKIP_HOOKS=1 git commit -m "..."             # pula pre-commit do projeto
SECURITY_MARKER_SKIP=1                       # pula warning de marker nesta sessão
```

## Comportamento esperado de Claude

Quando entrar em projeto:

1. **Silenciosamente** verificar `.security-applied`
2. Se faltar: **mencionar uma vez** ao Thiago no início da resposta:
   > "⚠️ Projeto X sem `.security-applied`. Recomendo `/secure-audit X` antes de mexermos."
3. Não bloquear trabalho — Thiago decide se aplica antes ou continua
4. Se for um deploy: SEMPRE rodar `/secure-protect` antes do `vercel deploy --prod`

## Aplicação retroativa

Pra aplicar em todos os projetos existentes de uma vez:
```bash
cd ~/PROJETOS/claude-code-security-kit
bash scripts/audit-projects.sh        # gera relatório
# revisar reports/audit-YYYY-MM-DD.json
# aplicar template em cada projeto que precisar:
bash scripts/apply-template.sh ~/PROJETOS/<projeto>
```

## Fonte canônica

Tudo nesse sistema vem de `~/PROJETOS/claude-code-security-kit/`:
- `templates/` — `.gitignore` por tipo de projeto
- `scripts/` — automação
- `docs/playbooks/` — rotação de credenciais, incidentes
- `docs/specs/` — spec do sistema (versão 1.0.0)

**Nunca duplicar templates ou scripts em outros lugares.** Sempre pull do repo SECURITY.

## Privacidade e segurança operacional

1. **NUNCA** exibir conteúdo de `.env*` em respostas
2. **NUNCA** exibir conteúdo de `~/.claude/settings.json` (contém credenciais MCP)
3. Se precisar referenciar uma chave, mencionar **só o nome da variável**: `OBSIDIAN_API_KEY` ✓ vs `OBSIDIAN_API_KEY=486420bd...` ✗
4. Em screenshots ou outputs: redact valores antes de mostrar
5. Logs em `~/.claude/logs/` — gitignored, nunca commitados

## Relacionamento com outras skills

- Antes de `/lp-novo`, `/produzir`, `/blog`: rodar essa skill
- Após `auditor`: pode incluir item "verificar marker" no checklist
- Conflito com outra skill? Esta tem prioridade pra qualquer questão de segurança
