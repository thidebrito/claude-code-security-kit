# Comparison vs Alternatives

How this kit compares to popular tools in the same space.

## TL;DR

| Tool | Type | Primary purpose | Best for |
|---|---|---|---|
| **This kit** | Complete out-of-the-box system | Hooks + scanning + IP protection for AI-coded projects | Solo devs / agencies using Claude Code |
| [Husky](https://typicode.github.io/husky/) | Git hooks framework | Run anything on git events | Teams that want to roll their own |
| [Lefthook](https://github.com/evilmartians/lefthook) | Git hooks framework | Faster, parallel hooks | Same as Husky, performance-focused |
| [Trufflehog](https://github.com/trufflesecurity/trufflehog) | Secret scanner CLI | Find secrets in repos/history | Audit one-shot, CI integration |
| [Gitleaks](https://github.com/gitleaks/gitleaks) | Secret scanner CLI | Same as Trufflehog | Audit + pre-commit (used by this kit) |
| [GitGuardian](https://www.gitguardian.com/) | SaaS platform | Enterprise secret monitoring | Companies with security budget |
| [pre-commit](https://pre-commit.com/) | Hook orchestrator | Plugin ecosystem (Python-based) | Polyglot teams |

---

## Feature matrix (extended)

| Feature | This kit | Husky | Lefthook | Trufflehog | Gitleaks | GitGuardian |
|---|---|---|---|---|---|---|
| **License** | MIT | MIT | MIT | AGPL | MIT | Commercial |
| **Cost** | $0 | $0 | $0 | $0 | $0 | $$$ ($75+/dev/mo) |
| **Install effort** | 1 cmd | 2 cmds + config | 2 cmds + config | 1 cmd | 1 cmd | Account + integrations |
| **Idempotent installer** | ✅ | ❌ | ❌ | N/A | N/A | N/A |
| **Pre-commit hooks** | ✅ | ✅ | ✅ | ❌ | ✅ (via wrapper) | ✅ |
| **Pre-push hooks** | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| **AI agent hooks** | ✅ (Claude Code) | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Secret scanning** | ✅ (gitleaks) | DIY | DIY | ✅ | ✅ | ✅ |
| **PII scanning (BR-friendly)** | ✅ | DIY | DIY | ❌ | Partial | ✅ |
| **`.gitignore` templates** | ✅ (4 types) | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Auto-apply to new projects** | ✅ **Unique** | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Authorship watermarking** | ✅ **Unique** | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Blockchain timestamping** | ✅ **Unique** | ❌ | ❌ | ❌ | ❌ | ❌ |
| **Pre-deploy guard** | ✅ | DIY | DIY | ❌ | ❌ | ✅ |
| **History scan (last N commits)** | ✅ | DIY | DIY | ✅ | ✅ | ✅ |
| **Custom rules** | ✅ (Bash) | ✅ | ✅ | ✅ (regex) | ✅ (TOML) | ✅ |
| **CI integration** | ✅ (workflows included) | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Privacy (local-only)** | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ (cloud) |
| **Ecosystem audit (multi-repo)** | ✅ | ❌ | ❌ | Partial | Partial | ✅ |

---

## When to use what

### Use **this kit** when:
- You use Claude Code (or another AI agent that supports hooks via settings.json)
- You want a complete, opinionated system without configuring rules
- You build LPs/apps and want IP authorship proof
- You're a solo dev or small agency, want $0 cost

### Use **Husky/Lefthook** when:
- Your team prefers configuring hooks manually
- You need very specific custom workflows
- You don't care about secret scanning out of the box
- You want fine-grained per-hook control

### Use **Trufflehog/Gitleaks alone** when:
- You only need secret scanning (no PII, no templates, no IP)
- You're integrating into existing CI/CD
- You don't use AI coding agents

### Use **GitGuardian** when:
- You're an enterprise with security/compliance requirements
- You need a SOC 2-certified solution
- You have budget ($75+/dev/month)
- You want a managed dashboard, alerts, integrations

### Use **pre-commit (Python)** when:
- You have polyglot teams (Python, Ruby, Go) needing consistent hooks
- You want a plugin ecosystem (linters, formatters, scanners)
- You don't need the AI agent layer

---

## Combining tools

This kit plays well with others:

- **+ Husky/Lefthook:** if your repo already uses one, the kit's hooks supplement it (different layer — Claude Code, not git directly)
- **+ Trufflehog:** add it to CI for full-history scanning, while this kit handles pre-commit and PreToolUse
- **+ GitGuardian:** use GG for cloud monitoring, this kit for local prevention

You don't need to choose. The kit's value is in the **integration layer** (AI agent hooks + IP protection), not in replacing existing scanners.
