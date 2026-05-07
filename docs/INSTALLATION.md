# Installation Guide

## Quick install (recommended)

```bash
git clone https://github.com/thidebrito/claude-code-security-kit.git ~/PROJETOS/claude-code-security-kit
cd ~/PROJETOS/claude-code-security-kit
bash install.sh
```

Then **restart Claude Code** to load the new skill, commands, and hooks.

---

## Pre-requisites

| Tool | Required | Mac install | Linux install (Debian/Ubuntu) |
|---|---|---|---|
| `git` | ✅ | `brew install git` | `sudo apt install git` |
| `node` 18+ | ✅ | `brew install node` | Use [nvm](https://github.com/nvm-sh/nvm) |
| `python3` | ✅ | Pre-installed | `sudo apt install python3` |
| `gitleaks` | Recommended | `brew install gitleaks` | [Download from releases](https://github.com/gitleaks/gitleaks/releases) |
| `gh` CLI | Optional (for repo creation) | `brew install gh` | [Install via apt](https://github.com/cli/cli/blob/trunk/docs/install_linux.md) |
| Claude Code | For Layer A | [claude.ai/code](https://claude.ai/code) | [claude.ai/code](https://claude.ai/code) |

Verify everything:

```bash
git --version && node --version && python3 --version && gitleaks version
```

---

## What `install.sh` does

1. **Validates pre-requisites** — exits early if missing
2. **Backs up `~/.claude/settings.json`** with timestamp suffix
3. **Copies skill** `seguranca-projeto` to `~/.claude/skills/`
4. **Copies 3 commands** `/secure-init`, `/secure-audit`, `/secure-protect`
5. **Copies 5 hook scripts** to `~/.claude/scripts/` and makes executable
6. **Configures `settings.json`** — adds hooks (idempotent: detects duplicates)
7. **Appends section** to `~/.claude/CLAUDE.md` (skips if already present)
8. **Validates** — 11 final checks, exits with success status

If any step fails, the backup ensures you can revert:

```bash
cp ~/.claude/settings.json.bak.<timestamp> ~/.claude/settings.json
```

---

## Post-install

### 1. Restart Claude Code

Cmd+Q the app and reopen. This is required for it to load the new skill, commands, and hooks from disk.

### 2. Verify

In Claude Code, type:

```
/secure-audit
```

If the command is recognized (shows description), installation is OK.

### 3. Audit existing projects

```bash
bash ~/PROJETOS/claude-code-security-kit/scripts/audit-projects.sh
```

Generates a JSON report in `reports/` with:
- Which projects have `.gitignore`
- Which have `.security-applied` marker
- Secret scan over last 50 commits per repo
- Real `.env` files found that may not be gitignored

### 4. Apply template to projects without protection

For each project listed in the audit:

```bash
bash ~/PROJETOS/claude-code-security-kit/scripts/apply-template.sh ~/PROJETOS/<your-project>
```

Auto-detects type (web/react/node) and applies:
- `.gitignore` (universal + type-specific)
- `.env.example` (preserves if exists)
- Pre-commit hook (if Git repo)
- `.security-applied` marker

---

## Manual installation (if `install.sh` fails)

If `install.sh` doesn't work in your environment, install components manually:

```bash
REPO=~/PROJETOS/claude-code-security-kit

# Skill
mkdir -p ~/.claude/skills/seguranca-projeto
cp $REPO/claude-code-bundle/skills/seguranca-projeto/SKILL.md ~/.claude/skills/seguranca-projeto/

# Commands
mkdir -p ~/.claude/commands
for c in secure-init secure-audit secure-protect; do
  cp $REPO/claude-code-bundle/commands/$c.md ~/.claude/commands/
done

# Scripts
mkdir -p ~/.claude/scripts
for s in block-secrets-commit pii-scan-hook security-marker-check pre-deploy-guard security-session-start; do
  cp $REPO/claude-code-bundle/scripts/$s.sh ~/.claude/scripts/
  chmod +x ~/.claude/scripts/$s.sh
done

# settings.json — manually add hooks
# (See claude-code-bundle/claude-md-snippet.md for reference)

# CLAUDE.md — append snippet
cat $REPO/claude-code-bundle/claude-md-snippet.md >> ~/.claude/CLAUDE.md
```

---

## Updating

```bash
cd ~/PROJETOS/claude-code-security-kit
bash update.sh
```

This:
1. Auto-stashes any local changes
2. Pulls from GitHub
3. Re-runs `install.sh` (idempotent — only adds new things)

---

## Uninstalling

```bash
# 1. Restore settings.json from backup
ls ~/.claude/settings.json.bak.*  # find latest
cp ~/.claude/settings.json.bak.<latest> ~/.claude/settings.json

# 2. Remove skill, commands, scripts
rm -rf ~/.claude/skills/seguranca-projeto
rm ~/.claude/commands/secure-{init,audit,protect}.md
rm ~/.claude/scripts/{block-secrets-commit,pii-scan-hook,security-marker-check,pre-deploy-guard,security-session-start}.sh

# 3. (Optional) Remove repo
rm -rf ~/PROJETOS/claude-code-security-kit

# 4. (Optional) Remove section from CLAUDE.md
# Open and delete the "Sistema de Segurança" section manually
```

---

## Troubleshooting

### "Skill not recognized"
- Did you restart Claude Code after install?
- Is the file at `~/.claude/skills/seguranca-projeto/SKILL.md`?
- Is the YAML frontmatter valid (first line `---`, then `name:`, `description:`, then `---`)?

### "Hook blocking legitimate commit"
- Use bypass env var temporarily: `SKIP_HOOKS=1 git commit -m "..."`
- Open issue describing what you tried to commit (REDACT secrets)

### "settings.json broken"
- Restore backup: `cp ~/.claude/settings.json.bak.<timestamp> ~/.claude/settings.json`
- Re-run `install.sh`

### "gitleaks: command not found"
- Mac: `brew install gitleaks`
- Linux: download binary from [releases](https://github.com/gitleaks/gitleaks/releases)
- Without gitleaks, the secret scan hook will skip silently (project still works)

### "Permission denied" on script
- `chmod +x ~/.claude/scripts/*.sh`
- `chmod +x ~/PROJETOS/claude-code-security-kit/scripts/*.sh`

---

For more help: [open an issue](../../issues/new) or see [docs/FAQ.md](FAQ.md).
