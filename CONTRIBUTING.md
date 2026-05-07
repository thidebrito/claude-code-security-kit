# Contributing to Claude Code Security Kit

First off — thank you for considering contributing. This kit exists because developers care about security and want it always-on while building with AI agents.

## Quick start for contributors

```bash
# 1. Fork & clone
gh repo fork thidebrito/claude-code-security-kit --clone
cd claude-code-security-kit

# 2. Install locally (idempotent)
bash install.sh

# 3. Run health-check
bash scripts/health-check.sh

# 4. Make your changes, test, commit, push
```

## Ways to contribute

### 🐛 Report bugs
Open an [issue](../../issues/new) with:
- OS + version (macOS / Linux / WSL)
- Hook or script involved
- Steps to reproduce
- Expected vs actual behavior

### ✨ Request a feature
Open an issue with the `feature` label. Describe:
- The problem you're solving
- Why existing tools don't solve it
- Proposed approach

### 📝 Improve documentation
- README typos, clarifications
- New use cases
- Translations (Portuguese exists; English needs polishing; others welcome)
- Diagrams (Mermaid preferred)

### 🔧 Code contributions

Good first issues:
- [ ] Add Linux package manager instructions (`apt`, `dnf`, `pacman`)
- [ ] Adapter for Cursor (`~/.cursor/`) and Copilot Workspace
- [ ] Reduce false positives in `pii-scan.sh` (better email allowlist)
- [ ] Add `windows/wsl` install branch in `install.sh`
- [ ] Static dashboard HTML showing security status across projects
- [ ] Pre-built GitHub Actions workflow templates (`.github/workflows/`)
- [ ] Tests (BATS for shell scripts, Vitest for JS)

## Coding standards

### Shell scripts (`.sh`)
- Use `#!/usr/bin/env bash`
- `set -euo pipefail` (or `set -uo` if intentional)
- Always quote variables: `"$var"` not `$var`
- Test with `shellcheck` before PR
- Add `# Bypass: ENV_VAR=1` documentation for hooks

### JavaScript (`.mjs`)
- ESM only (`.mjs` extension)
- Node.js 18+ APIs
- No external dependencies if possible (we want install to be light)
- If adding dep, justify in PR description

### Markdown
- Follow existing structure
- Use `mermaid` for diagrams when possible (renders on GitHub)
- Keep lines reasonably short (~100 chars) for diff-friendliness

### Commit messages
Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(scope): add new feature
fix(scope): fix a bug
docs(scope): documentation only
refactor(scope): no behavior change
chore(scope): maintenance
test(scope): tests
```

Example: `feat(hooks): add cursor adapter for security-marker-check`

## Pull Request process

1. Open issue first (for non-trivial changes) — let's discuss approach
2. Fork → branch from `main` → make changes
3. Test locally: `bash scripts/health-check.sh` passes
4. Update CHANGELOG.md under `[Unreleased]`
5. Update relevant docs
6. Open PR with template (auto-loaded)
7. Maintainer reviews — usually within 7 days

## Code of Conduct

This project adheres to the [Contributor Covenant 2.1](CODE_OF_CONDUCT.md). By participating, you agree to uphold it.

## Security disclosures

**Don't open public issues for security vulnerabilities.** See [SECURITY.md](SECURITY.md) for responsible disclosure.

## Recognition

Contributors are listed in releases and the README. Significant contributions get a `🌟 Hall of Fame` mention.

Thank you! 🙏
