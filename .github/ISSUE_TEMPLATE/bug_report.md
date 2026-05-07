---
name: Bug report
about: Something doesn't work as expected
title: '[BUG] '
labels: 'bug'
assignees: ''
---

## Describe the bug
A clear and concise description of what the bug is.

## Component affected
- [ ] `install.sh`
- [ ] Hook: `block-secrets-commit.sh`
- [ ] Hook: `pii-scan-hook.sh`
- [ ] Hook: `security-marker-check.sh`
- [ ] Hook: `pre-deploy-guard.sh`
- [ ] Hook: `security-session-start.sh`
- [ ] Script: `apply-template.sh`
- [ ] Script: `audit-projects.sh`
- [ ] Script: `protect-build.mjs`
- [ ] Templates
- [ ] Documentation

## To reproduce
Steps:
1. Go to '...'
2. Run '...'
3. See error

## Expected behavior
What you expected to happen.

## Actual behavior
What actually happened. Include error messages (redact any secrets!).

## Environment
- OS: [macOS 14.x / Ubuntu 22.04 / WSL]
- Shell: [bash 5.x / zsh 5.x]
- Node: [v18.x / v20.x]
- gitleaks version: [output of `gitleaks version`]
- Claude Code version (if applicable): [...]

## Additional context
Logs, screenshots (REDACT secrets), related issues.
