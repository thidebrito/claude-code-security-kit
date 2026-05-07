
## Sistema de Segurança e Proteção do Ecossistema

**Repo canônico:** `~/PROJETOS/claude-code-security-kit/`
**Spec:** `docs/specs/2026-05-06-security-system-design.md`
**Skill:** `seguranca-projeto` (always-on, dispara automaticamente)

### Comandos
- `/secure-init <pasta>` — inicializa projeto NOVO com templates aplicados
- `/secure-audit [pasta]` — audita projeto(s) existente(s), gera relatório
- `/secure-protect <pasta>` — pipeline pré-deploy (UUID + watermark + SHA-256 + ots)

### Hooks ativos no Claude Code (~/.claude/settings.json)
- `block-secrets-commit.sh` — bloqueia commit de `.env*`
- `pii-scan-hook.sh` — bloqueia commit com PII (email/CPF/telefone) no diff
- `security-marker-check.sh` — alerta se projeto sem `.security-applied`
- `pre-deploy-guard.sh` — bloqueia push sem Pixel ou com secret

### Templates canônicos
Em `~/PROJETOS/claude-code-security-kit/templates/`:
- `gitignore.universal` — base comum
- `gitignore.web` / `gitignore.react` / `gitignore.node` — por tipo de projeto
- `env.example.template` — chaves comuns documentadas, sem valores
- `pre-commit.sh.template` — git hook pra cada projeto

### Aplicação retroativa
```bash
bash ~/PROJETOS/claude-code-security-kit/scripts/audit-projects.sh
# Revisar reports/ e aplicar template em projetos sem .security-applied:
bash ~/PROJETOS/claude-code-security-kit/scripts/apply-template.sh <projeto>
```

### Privacidade
- NUNCA exibir conteúdo de `.env*`, `~/.claude/settings.json`, ou tokens
- Em outputs/screenshots: redact valores antes de mostrar
- gitleaks roda com `--redact` por padrão
