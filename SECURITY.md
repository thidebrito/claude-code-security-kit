# Security Policy

## Reporting a Vulnerability

**Please do not open public GitHub issues for security vulnerabilities.**

If you discover a security issue in this kit (e.g., a hook that fails to block a real leak, a bypass that shouldn't exist, an injection vector in `protect-build.mjs`), please report privately:

1. **GitHub Security Advisories** (preferred): use the [Security tab](../../security/advisories/new) to file privately
2. **Email**: open a regular issue asking for contact, do NOT include details

Include:
- What component is affected (hook script, template, etc.)
- Steps to reproduce
- Impact (what the vulnerability allows)
- Suggested fix (if you have one)

We aim to respond within **7 days** and patch within **30 days** for high-severity issues.

## Scope

In scope:
- Hook scripts (`block-secrets-commit`, `pii-scan-hook`, `security-marker-check`, `pre-deploy-guard`, `security-session-start`)
- `protect-build.mjs` and Vite plugin
- `install.sh`, `update.sh`, `health-check.sh`
- Templates that could leak data if applied incorrectly

Out of scope:
- Vulnerabilities in dependencies (gitleaks, opentimestamps) — report to those projects
- Issues with your specific configuration (use issues for those)
- Theoretical attacks requiring root access already

## Public Disclosure

After a fix is released, we publish a security advisory with:
- CVE if assigned
- Affected versions
- Fix version
- Acknowledgment to reporter (unless anonymity preferred)

## Hall of Fame

Researchers who report valid security issues are credited here unless they request anonymity:

_(empty — be the first!)_

## Hardening tips for users

If you're using this kit on a sensitive project, consider:

- **Rotate credentials regularly** — even if no leak detected
- **Migrate `~/.claude/settings.json` secrets to macOS Keychain / 1Password / Bitwarden** — don't leave in plain text
- **Run `bash scripts/audit-projects.sh` weekly** — catch new leaks early
- **Verify Bitcoin timestamps** after 24h with `npx opentimestamps upgrade <file>.ots`
- **Review `.gitleaksignore` quarterly** — old suppressions may no longer be needed

Thank you for helping keep this project secure. 🛡️
