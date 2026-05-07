# Claude Code Bundle

Cópia distribuível dos arquivos do Claude Code que compõem o sistema THIDEBRITO-SECURITY.

**NÃO MEXA AQUI DIRETAMENTE.** Os arquivos canônicos estão em `~/.claude/`.

Este bundle existe pra:
- O `install.sh` copiar daqui pro `~/.claude/` em qualquer computador
- Versionar mudanças junto com o resto do sistema (Git)
- Permitir reconstrução completa do zero

## Conteúdo

```
claude-code-bundle/
├── README.md                              ← este arquivo
├── claude-md-snippet.md                   ← seção pra appendar no ~/.claude/CLAUDE.md
├── skills/
│   └── seguranca-projeto/
│       └── SKILL.md                       ← skill always-on de segurança
├── commands/
│   ├── secure-init.md                     ← /secure-init <pasta>
│   ├── secure-audit.md                    ← /secure-audit [pasta]
│   └── secure-protect.md                  ← /secure-protect <pasta>
└── scripts/
    ├── block-secrets-commit.sh            ← Hook PreToolUse Bash
    ├── pii-scan-hook.sh                   ← Hook PreToolUse Bash
    ├── security-marker-check.sh           ← Hook PreToolUse Edit/Write
    └── pre-deploy-guard.sh                ← Hook PreToolUse Bash
```

## Como atualizar este bundle

Se você editar um arquivo em `~/.claude/`, copie de volta pra cá:

```bash
# Skill
cp ~/.claude/skills/seguranca-projeto/SKILL.md \
   ~/PROJETOS/claude-code-security-kit/claude-code-bundle/skills/seguranca-projeto/

# Commands
for c in secure-init secure-audit secure-protect; do
  cp ~/.claude/commands/$c.md ~/PROJETOS/claude-code-security-kit/claude-code-bundle/commands/
done

# Scripts
for s in block-secrets-commit pii-scan-hook security-marker-check pre-deploy-guard; do
  cp ~/.claude/scripts/$s.sh ~/PROJETOS/claude-code-security-kit/claude-code-bundle/scripts/
done

# Commit
cd ~/PROJETOS/claude-code-security-kit
git add claude-code-bundle/
git commit -m "chore(bundle): sync arquivos de ~/.claude/"
git push
```

## Como instalar este bundle em outro computador

```bash
cd ~/PROJETOS/claude-code-security-kit
bash install.sh
```

O `install.sh` faz:
1. Backup de `~/.claude/settings.json`
2. Copia skill, commands, scripts pro `~/.claude/`
3. Adiciona hooks no `settings.json` (idempotente)
4. Append seção no `CLAUDE.md`
5. Validação final (10 checks)

Detalhes completos no `install.sh`.
