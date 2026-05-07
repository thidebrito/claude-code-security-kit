# Commands Reference

The kit installs 3 slash commands in Claude Code's `~/.claude/commands/`. They're rarely needed (hooks fire automatically), but useful for explicit actions.

## `/secure-init <pasta>`

**Purpose:** initialize a new project with all security templates applied.

**When to use:** you just created a new project folder and want it protected before adding any code. (Note: the `security-marker-check` hook usually does this automatically when you start editing.)

**Example:**
```
/secure-init ~/PROJETOS/new-landing-page
```

**What it does:**
1. Auto-detects project type (web, react, node)
2. Applies `.gitignore` (universal + type-specific, ~120-160 lines)
3. Creates `.env.example` (if not present)
4. Installs pre-commit hook (if Git repo)
5. Creates `.security-applied` marker

**Output:**
```
🛡️  Aplicando templates de segurança em: new-landing-page
    Path: /Users/you/PROJETOS/new-landing-page
    Tipo: web

  ✅ .gitignore atualizado (137 linhas)
  ✅ .env.example criado
  ✅ pre-commit hook instalado
  ✅ .security-applied marker criado
```

---

## `/secure-audit [pasta]`

**Purpose:** audit one project or the entire ecosystem for security issues.

**When to use:**
- Periodic audit (weekly/monthly)
- After applying changes to multiple projects
- Before public releases

**Examples:**
```
/secure-audit                    # audit all projects in ~/PROJETOS/* and ~/your-project/
/secure-audit ebook              # filter by name (matches projects containing "ebook")
/secure-audit ~/PROJETOS/ia-euro # specific path
```

**What it checks per project:**
- ✓ Has Git repo?
- ✓ Has `.gitignore`?
- ✓ Does `.gitignore` cover `.env*`?
- ✓ Has `.security-applied` marker?
- ✓ Has `.env*` files that may not be gitignored?
- ✓ Secret scan over last 50 commits (gitleaks)

**Output:**
- Console summary per project
- Consolidated JSON: `reports/audit-YYYY-MM-DD-HHMM.json`
- Per-repo leak details: `reports/details/<project>-leaks.json`

**Modes:**
```
/secure-audit --quick     # skips gitleaks (faster, structural only)
```

---

## `/secure-protect <pasta>`

**Purpose:** apply Layer C (IP protection pipeline) before deploying a public LP/app.

**When to use:** before `vercel deploy --prod` (or equivalent) for public-facing projects with IP value.

**Example:**
```
/secure-protect ~/PROJETOS/my-landing-page
```

**What it does:**
1. Generates UUID v4 unique to this build
2. Calculates SHA-256 of every file in `dist/` (or `build/`, or `out/`, or root)
3. Injects invisible watermarks:
   - HTML meta tags (`x-author`, `x-author-id`, `x-built-at`, `x-canonical-source`)
   - JS: `window.__TDB__ = atob(...)` with author + UUID encoded
   - CSS comments: `/* © Author · date · uuid */`
4. Generates `protection-manifest.json` in `dist/`
5. Stamps manifest hash on Bitcoin blockchain via OpenTimestamps
6. Saves `.ots` proof in `~/PROJETOS/claude-code-security-kit/timestamps/<project>/`

**Output:**
```
🛡️  protect-build.mjs
   Projeto:   my-landing-page
   Build UUID: a3f9c2e1-...

🔎 Mapeando arquivos do build...
   12 arquivos encontrados
💧 Watermarks injetados: 4 HTML, 3 JS, 2 CSS
🔐 Calculando SHA-256 de cada arquivo...
   12 arquivos hasheados (1.2 MB total)
📜 Manifest gerado: dist/protection-manifest.json
⏱️  Aplicando OpenTimestamps...
✅ OpenTimestamps stamp criado: timestamps/my-landing-page/2026-05-06_2130_a3f9c2e1.json.ots
```

**Flags:**
```
--dry-run          # show what would happen, modifies nothing
--skip-timestamp   # skips blockchain stamp (useful for local tests)
--dist-dir build   # use build/ instead of dist/
--verbose          # show every file processed
```

**After deploy + 6h:** finalize the Bitcoin anchor:
```bash
npx opentimestamps upgrade ~/PROJETOS/claude-code-security-kit/timestamps/my-landing-page/2026-05-06_2130_a3f9c2e1.json.ots
```

This updates the `.ots` file with the Bitcoin block number where your hash is permanently anchored. Now you have **legally admissible proof** that your build existed at that exact time.

---

## When you'd run commands manually vs hooks

| Scenario | Hook does it automatically? | Manual command needed? |
|---|---|---|
| New project — apply template | ✅ `security-marker-check` | Optional `/secure-init` |
| Block commit with `.env` | ✅ `block-secrets-commit` | Never |
| Block commit with PII | ✅ `pii-scan-hook` | Never |
| Audit ecosystem | ❌ | ✅ `/secure-audit` (weekly) |
| Apply IP protection before deploy | ❌ (warns only) | ✅ `/secure-protect` |
| Health-check | ✅ `security-session-start` | Optional `bash scripts/health-check.sh` |
