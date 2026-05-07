# CHANGELOG

Todas as mudanças relevantes do sistema THIDEBRITO-SECURITY.

Formato baseado em [Keep a Changelog](https://keepachangelog.com/), com versionamento semântico.

---

## [1.0.0] — 2026-05-06

### 🎉 Release inicial

Sistema completo de segurança e proteção de propriedade intelectual implantado em **25/25 projetos do ecossistema (100% cobertura)**.

### ✨ Adicionado — Camada 0 (Governance)
- Skill `seguranca-projeto` (always-on em `~/PROJETOS/*` e `~/your-project/`)
- Comando `/secure-init <pasta>` — inicializa projeto novo
- Comando `/secure-audit [pasta]` — audita projeto(s)
- Comando `/secure-protect <pasta>` — pipeline pré-deploy
- Regras 11 e 12 no `~/.claude/CLAUDE.md` global
- Atualização do `/lp-novo` pra invocar `/secure-init` no passo 0

### ✨ Adicionado — Camada B (Segurança Projetos)
- 4 templates de `.gitignore` (universal, web, react, node)
- Template `.env.example` com variáveis comuns documentadas (Supabase, Hotmart, Meta, Resend, etc.)
- Template `pre-commit.sh` (rota gitleaks + pii-scan)
- Template `.gitleaksignore` (suprimir falsos positivos conhecidos)
- Template `.security-applied.json` (marker do projeto auditado)
- Script `apply-template.sh` (aplica template, auto-detecta tipo)
- Script `audit-projects.sh` (itera todo o ecossistema, gera relatório)
- Script `secret-scan.sh` (wrapper de gitleaks)
- Script `pii-scan.sh` (regex pra email/CPF/CNPJ/cartão)
- Playbook `rotate-credentials.md` (procedimento pra rotação de credenciais vazadas)

### ✨ Adicionado — Camada A (Workflow Claude)
- Hook `block-secrets-commit.sh` ativado em settings.json (bloqueia commit de `.env`)
- Hook `pii-scan-hook.sh` (bloqueia commit com PII)
- Hook `security-marker-check.sh` (avisa projetos sem proteção)
- Hook `pre-deploy-guard.sh` mantido (já existia)
- Backup automático do `settings.json` antes de qualquer mudança

### ✨ Adicionado — Camada C (Proteção Autoria)
- Pipeline `protect-build.mjs` (UUID + watermark + SHA-256 + OpenTimestamps)
- Plugin Vite `vite-plugin-tdb-protect.mjs` (closeBundle hook)
- Wrapper `pre-deploy.sh` (pra projetos HTML puro)
- Integração com `npx opentimestamps` (blockchain Bitcoin gratuita)

### ✨ Adicionado — Distribuição
- Bundle `claude-code-bundle/` (cópias dos arquivos do Claude Code)
- Script `install.sh` idempotente (10/10 checks de validação)
- Script `update.sh` (atalho pra git pull + reinstalar)
- Script `health-check.sh` (validação rápida do estado do sistema)
- Guia portátil `~/Downloads/THIDEBRITO-PROPRIEDADE-INTELECTUAL-SECURITY.md` (841 linhas, 28 KB)

### 🐛 Corrigido
- Lógica do `if` em `pii-scan.sh` (estava invertida — sempre marcava PII quando NÃO achava)
- `apply-template.sh` e template `security-applied` removeram email pessoal (PII detectada pelo próprio sistema)
- `audit-projects.sh` tratamento de arrays vazios e `grep -c` sem matches

### ⚠️ Decisões conscientes (NÃO implementado)
- **Ofuscação JavaScript** — adiada. Risco de quebrar Pixel Meta/Hotmart/Supabase considerado alto demais
- **Assinatura GPG** — adiada. OpenTimestamps + SHA-256 já dão 90% do valor jurídico
- **Migração de credenciais do `settings.json` pro Keychain** — pendente (sessão futura)

### 📊 Métricas da release
- **25/25 projetos do ecossistema** com `.security-applied` marker
- **9 repos com pre-commit hook** instalado em `.git/hooks/`
- **4 hooks ativos** no Claude Code
- **7 commits relevantes** entre repos pushed pro GitHub
- **0 leaks reais** no GitHub (gitleaks confirma)
- **0 sites quebrados** em prod (validados HTTP 200)

---

## [Não-lançado / Roadmap]

Possíveis melhorias futuras (não-priorizadas):

- [ ] Hook que detecta projeto NOVO e aplica template **automaticamente** (sem precisar de `/secure-init`)
- [ ] Migração de credenciais do `~/.claude/settings.json` pro macOS Keychain
- [ ] Implementar ofuscação JS opcional (com whitelist de Pixel Meta, Hotmart, etc.)
- [ ] Implementar assinatura GPG do `protection-manifest.json`
- [ ] Dashboard web (HTML estático) que mostra estado de segurança de todos os projetos
- [ ] Integração com GitHub Actions: rodar gitleaks + pii-scan em PRs
- [ ] CLI unificada `tdb-security <comando>` em vez de scripts soltos
