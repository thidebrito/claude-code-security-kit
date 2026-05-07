# Sistema de Segurança e Proteção do Ecossistema Your Name

**Data:** 2026-05-06
**Autor:** Your Name (com Claude Code)
**Status:** Aprovada — em implementação
**Repo canônico:** `~/PROJETOS/claude-code-security-kit/`

---

## 1. Contexto e motivação

O ecossistema digital do Thiago tem 24+ projetos com perfis de risco heterogêneos:

- **Projetos públicos com IP** — site principal, blog, LPs, app PWA, produtos pagos (ebook, IA na Prática)
- **Projetos com integrações sensíveis** — Hotmart, Supabase, Resend, Meta Ads, Google Ads
- **Projetos cliente** — Mentoria Aurora, Dr. Felipe Machado
- **Conta @yourhandle verificada** — ativo crítico cuja perda seria irreversível

Auditoria inicial revelou:
- Inconsistência de `.gitignore` entre repos (de 1 a 32 linhas, sem padrão)
- `block-secrets-commit.sh` existe em `~/.claude/scripts/` mas não está conectado em `settings.json`
- Sem sistema unificado de proteção de autoria (hash, watermark, timestamp)
- Sem auditoria retroativa do histórico de commits dos repos

**Objetivo:** sistema único, automatizado, always-on, que aplique 3 camadas de proteção em todos os projetos do ecossistema — atuais e futuros.

---

## 2. Princípios de design

1. **Always-on** — Claude aplica as proteções automaticamente em qualquer projeto que tocar, sem precisar ser lembrado.
2. **Fonte canônica única** — `~/PROJETOS/claude-code-security-kit/` é a fonte da verdade. Outros projetos puxam dela, não duplicam.
3. **Reversível** — toda mudança em projeto existente passa por preview/branch antes de produção.
4. **Open-source / custo zero** — todas as ferramentas são gratuitas, sem dependência de SaaS.
5. **Trade-offs honestos** — proteções são deterrents + provas; não são barreiras absolutas.

---

## 3. Arquitetura — 4 camadas

```
┌─────────────────────────────────────────────────────────────┐
│  Camada 0 — Governance (Always On)                          │
│  Skill + Commands + Marker + CLAUDE.md global               │
│  → Garante que Claude aplique as 3 camadas inferiores       │
└─────────────────────────────────────────────────────────────┘
         ↓                    ↓                    ↓
┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  Camada B        │  │  Camada A        │  │  Camada C        │
│  Segurança       │  │  Workflow        │  │  Proteção        │
│  projetos        │  │  Claude          │  │  autoria         │
│                  │  │                  │  │                  │
│  Templates +     │  │  Hooks +         │  │  Pipeline        │
│  scripts +       │  │  rules +         │  │  pré-deploy      │
│  auditoria       │  │  comandos        │  │                  │
└──────────────────┘  └──────────────────┘  └──────────────────┘
```

---

## 4. Camada 0 — Governance (Always On)

### 4.1 Skill `seguranca-projeto`

**Localização:** `~/.claude/skills/seguranca-projeto/SKILL.md`

**Função:** disparada automaticamente antes de qualquer trabalho em projeto. Verifica `.security-applied` na raiz. Se ausente, recomenda rodar `/secure-audit`.

**Trigger:** sempre que Claude entrar em diretório `~/PROJETOS/*/` ou `~/your-project/`.

### 4.2 Marker `.security-applied`

**Localização:** raiz de cada projeto auditado.

**Conteúdo:**
```json
{
  "version": "1.0.0",
  "applied_at": "2026-05-06T15:43:00Z",
  "level": "B",
  "audit_report": "reports/2026-05-06-projeto-x.json",
  "applied_by": "you@example.com",
  "templates_used": ["gitignore.web", "env.example.template"]
}
```

**Importante:** versionado no Git do projeto. Usado pela skill pra detectar projetos não-auditados.

### 4.3 Comandos custom

| Comando | Função |
|---------|--------|
| `/secure-init <pasta>` | Inicializa projeto NOVO com todos os templates da Camada B aplicados |
| `/secure-audit [pasta]` | Audita projeto existente, gera relatório, sugere correções (sem aplicar sem confirmação) |
| `/secure-protect <pasta>` | Roda pipeline da Camada C antes de deploy (UUID + watermark + SHA-256 + OpenTimestamps) |

**Localização:** `~/.claude/commands/secure-*.md`

### 4.4 Update no `CLAUDE.md` global

Adicionar nova seção "Sistema de Segurança" linkando:
- `~/PROJETOS/claude-code-security-kit/README.md`
- Skill `seguranca-projeto`
- Comandos `/secure-*`

Adicionar regras 11 e 12:
- **Regra 11:** "Antes de tocar em qualquer projeto, validar `.security-applied`"
- **Regra 12:** "Antes de deploy de LP/app público, rodar `/secure-protect`"

---

## 5. Camada B — Segurança nos projetos

### 5.1 Templates canônicos

**Localização:** `~/PROJETOS/claude-code-security-kit/templates/`

| Arquivo | Pra que serve |
|---------|---------------|
| `.gitignore.universal` | Base comum (`.env*`, `node_modules/`, `.DS_Store`, `.claude/worktrees/`, etc.) |
| `.gitignore.web` | Universal + extras pra LPs HTML/CSS/JS |
| `.gitignore.react` | Universal + `dist/`, `.next/`, `.cache/`, source maps |
| `.gitignore.node` | Universal + `.vercel/`, logs serverless |
| `.env.example.template` | Template padrão com chaves comuns documentadas, sem valores reais |
| `pre-commit.sh.template` | Shell script: roda gitleaks + pii-scan + lint local |
| `.security-applied.template.json` | Template do marker |

### 5.2 Scripts

**Localização:** `~/PROJETOS/claude-code-security-kit/scripts/`

| Script | Função |
|--------|--------|
| `secret-scan.sh` | Wrapper de `gitleaks` — scan forward do diff staged + últimos 50 commits |
| `pii-scan.sh` | Regex pra emails, CPFs, telefones em arquivos staged ou diff |
| `audit-projects.sh` | Itera todos `~/PROJETOS/*` + `~/your-project`, gera `reports/audit-YYYY-MM-DD.json` |
| `apply-template.sh <projeto> <tipo>` | Copia template apropriado, instala git hooks via `.git/hooks/`, cria marker |
| `rotate-credentials.md` | Playbook de emergência se achar segredo vazado (Supabase, Hotmart, Resend, Meta) |

**Decisão técnica:** shell hooks puros (não husky). Razão: zero deps, alinha com stack mista (HTML puro + React).

### 5.3 Ferramenta principal: gitleaks

**Versão:** 8.30.1
**Licença:** MIT
**Maintainer:** gitleaks/gitleaks (26.6k stars)
**Instalação:** `brew install gitleaks`

### 5.4 Auditoria retroativa — nível (b)

**Aprovado pelo Thiago:** forward-scan + scan dos últimos 50 commits de cada repo.

**Procedimento:**
1. Listar todos os repos com `.git/`
2. Rodar `gitleaks detect --log-opts="--max-count=50"` em cada
3. Gerar relatório consolidado em `reports/audit-2026-05-06.json`
4. Apresentar ao Thiago → decidir rotações (não rotacionar nada sem aprovação explícita)
5. Se achar segredo crítico em repo top-tier (your-website-repo, ebook_producao_musical) → escalar pra scan completo nível (c)

---

## 6. Camada A — Otimização do workflow Claude

### 6.1 Hooks novos em `~/.claude/settings.json`

**⚠️ Backup obrigatório antes:** copiar `settings.json` pra `settings.json.bak.YYYY-MM-DD` antes de editar.

| Hook | Trigger | Função |
|------|---------|--------|
| `block-secrets-commit.sh` (já existe) | PreToolUse Bash matcher `git commit` | Bloqueia commit se gitleaks detectar segredo |
| `pii-scan-hook.sh` (novo) | PreToolUse Bash matcher `git commit` | Regex de PII no diff staged |
| `security-marker-check.sh` (novo) | PreToolUse Edit/Write em projetos | Alerta se faltar `.security-applied` |
| `pre-deploy-guard-v2.sh` (substitui v1) | PreToolUse Bash matcher `vercel deploy` | Adiciona checagens de protect-build |

### 6.2 Scripts em `~/.claude/scripts/`

| Script | Função |
|--------|--------|
| `pii-scan-hook.sh` | Hook wrapper que chama `~/PROJETOS/claude-code-security-kit/scripts/pii-scan.sh` |
| `security-marker-check.sh` | Verifica `.security-applied` no projeto sendo editado |
| `pre-deploy-guard-v2.sh` | Versão evoluída do atual com checagens de protect-build |

### 6.3 Skill `seguranca-projeto` — descrita na Camada 0

### 6.4 CLAUDE.md global

Atualização descrita na Camada 0 (regras 11, 12 + nova seção).

### 6.5 Hardening adicional descoberto durante auditoria

**Achado:** `~/.claude/settings.json` contém chave de API do Obsidian em plain text (`OBSIDIAN_API_KEY`).

**Risco:** baixo (settings.json é local, fora de repo), mas:
- Backup do laptop expõe
- Compartilhamento de settings.json (export/import) expõe

**Mitigação:** mover pra macOS Keychain ou variável de ambiente, referenciar via `${ENV:OBSIDIAN_API_KEY}`. Tarefa documentada como follow-up.

---

## 7. Camada C — Proteção de autoria

### 7.1 Escopo aprovado

| Ponto | Implementação | Status |
|-------|---------------|--------|
| #1 OpenTimestamps (blockchain) | Pipeline + `.ots` versionado | ✅ Implementar agora |
| #2 Watermark invisível | Meta tags + JS oculto + CSS comments + classes | ✅ Implementar agora |
| #3 Ofuscação JavaScript | `javascript-obfuscator` | ❌ NÃO implementar agora (decisão Thiago) |
| #4 Fingerprint UUID | UUID v4 por build, espalhado em locais não-óbvios | ✅ Implementar agora |
| #5 Hash SHA-256 + assinatura GPG | SHA-256 sim (prerequisito de #1), GPG não | ⚠️ SHA-256 sim, GPG mais tarde |

### 7.2 Pipeline `protect-build.mjs`

**Localização:** `~/PROJETOS/claude-code-security-kit/scripts/protect-build.mjs`

**Etapas:**

1. **Gerar UUID v4** — único da build
2. **Calcular SHA-256** de cada arquivo do `dist/` final
3. **Injetar watermarks:**
   - Meta tags HTML (`x-author`, `x-author-id`, `x-built-at`, `x-canonical-source`)
   - Comentário HTML `<!-- TDB-AUTHENTICITY: <hash> -->`
   - Variável JS oculta `window.__TDB__ = atob(...)`
   - Comentário CSS header `/* © Your Name · YYYY-MM-DD · uuid */`
   - Classe CSS marker `.tdb-${uuid.slice(0,8)}` em wrapper neutro
4. **Gerar `protection-manifest.json`:**
```json
{
  "project": "ebook_producao_musical",
  "build_uuid": "...",
  "built_at": "2026-05-06T...",
  "author": "Your Name",
  "files": [{"path": "...", "sha256": "..."}],
  "files_total_bytes": 2840192,
  "ots_proof": "timestamps/.../2026-05-06-1543.ots",
  "watermarks": {"meta": true, "css": true, "js_base64": true}
}
```
5. **OpenTimestamps:**
   - `npx opentimestamps stamp manifest.json` → cria `manifest.json.ots`
   - Salva em `~/PROJETOS/claude-code-security-kit/timestamps/<projeto>/<YYYY-MM-DD-HHmm>.ots`
   - Comita no repo SECURITY (prova legal versionada)

### 7.3 Integrações

| Stack | Mecanismo |
|-------|-----------|
| Vite (React) | Plugin custom `vite-plugin-tdb-protect.mjs` que chama no `closeBundle` |
| HTML puro / static | Script `pre-deploy.sh` chamado antes do `vercel deploy` |
| Vercel static | `vercel.json` com `buildCommand: "node ../THIDEBRITO-SECURITY/scripts/protect-build.mjs"` |

### 7.4 Aplicação seletiva

| Projeto | Aplica? |
|---------|---------|
| your-website-repo | ✅ Sim — site principal público |
| ebook_producao_musical | ✅ Sim — produto pago |
| ia-euro / ianapratica | ✅ Sim — LPs públicas |
| lp-dr-felipe-machado / claucarvalho | ✅ Sim — projetos cliente públicos |
| google-ads-automation / hotmart-mcp / autopilot | ❌ Não — internos, sem público externo |
| THIDEBRITO-SECURITY (esse repo) | ❌ Não — meta-projeto |

**Critério:** tem URL pública + IP que vale proteger? → aplica.

### 7.5 Limitações documentadas

1. Watermark e fingerprint são **deterrents**, não barreiras absolutas. Dev experiente que QUER limpar consegue.
2. OpenTimestamps + SHA-256 SÃO prova jurídica forte (aceito em casos no Brasil/EUA).
3. Não protege contra screenshot/visual copy ("redesenho" da LP) — isso é trade dress, outra disciplina.
4. Cobertura retroativa é parcial. Versões anteriores no Vercel ficam como estão. Marco zero a partir de hoje.

---

## 8. Plano de implementação

| Fase | Duração estimada | Entregável |
|------|------------------|------------|
| **B1** Templates | 2h | `templates/` populado |
| **B2** Scripts | 3h | `scripts/secret-scan.sh`, `pii-scan.sh`, `audit-projects.sh`, `apply-template.sh` |
| **B3** Auditoria retroativa | 1h execução + análise | `reports/audit-2026-05-06.json` consolidado |
| **A1** Hooks settings.json | 1h | settings.json atualizado + backup |
| **A2** Skill | 1h | `~/.claude/skills/seguranca-projeto/SKILL.md` |
| **A3** Comandos | 2h | `/secure-init`, `/secure-audit`, `/secure-protect` |
| **A4** CLAUDE.md | 30min | Nova seção + regras 11, 12 |
| **C1** Pipeline | 4h | `protect-build.mjs` funcionando standalone |
| **C2** Integração Vite + script | 2h | Plugin Vite + `pre-deploy.sh` |
| **Testes** | 2h | Smoke test em 1 projeto antes de aplicar em prod |

**Total estimado:** ~18h de trabalho focado.

---

## 9. Critérios de sucesso

1. Rodar `/secure-init projeto-x` em projeto vazio → projeto fica protegido sem passos manuais
2. Rodar `/secure-audit` em todos os repos → relatório consolidado entregue sem falsos críticos
3. Tentar commit com `.env` real → bloqueado por hook
4. Rodar `/secure-protect ebook_producao_musical` → `dist/` ganha watermarks, manifest gerado, .ots criado e versionado
5. Próxima sessão Claude em projeto sem marker → alerta automático
6. CLAUDE.md global atualizado e Claude segue as novas regras automaticamente

---

## 10. Fora de escopo (decisões explícitas)

- **Ofuscação JavaScript** — adiada. Risco de quebrar integrações em prod (Pixel Meta, Hotmart, Supabase) considerado alto demais pra primeira fase.
- **Assinatura digital GPG** — adiada. OpenTimestamps + SHA-256 dão 90% do valor jurídico com 0% de setup extra.
- **Scan profundo nível (c)** — só será acionado se nível (b) achar segredo crítico em repo top-tier.
- **Hardening da `OBSIDIAN_API_KEY`** — flagado como follow-up, não bloqueia esse plano.

---

## 11. Riscos e mitigações

| Risco | Mitigação |
|-------|-----------|
| Auditoria retroativa achar segredo já vazado | Playbook `rotate-credentials.md` + escalação imediata pra Thiago |
| Hook PreToolUse atrapalhar workflow normal | Hooks com `exit 0` em caso de timeout, logs em `~/.claude/logs/` |
| Watermark quebrar funcionalidade visual | Aplicado em locais neutros (wrapper sem estilo crítico), testado em preview antes |
| Ofuscação (futura) quebrar Pixel Meta | Whitelist obrigatório `fbq`, `gtag`, integrações conhecidas |
| Pipeline OpenTimestamps depender de servidor remoto | Servidor calendar.opentimestamps.org (free, gratuito, comunidade ativa). Fallback: outros calendars (4 servidores em produção) |
| Aplicação automática quebrar projeto em prod | NUNCA aplicar em prod sem preview/branch + aprovação explícita |

---

## 12. Decisões pendentes do usuário

Nenhuma neste momento. Todas as decisões críticas foram aprovadas:

- ✅ Ordem de implementação: B → A → C
- ✅ Auditoria retroativa: nível (b)
- ✅ Camada C reduzida: sem #3 (ofuscação) e sem #5/GPG (apenas SHA-256 simples)
- ✅ Localização: `~/PROJETOS/claude-code-security-kit/`
- ✅ Auto mode ativado pra execução

---

## 13. Próximos passos pós-implementação

1. Aplicação progressiva da Camada C nos projetos públicos (1 por vez, com testes)
2. Re-avaliar implementação da Ofuscação JS após estabilidade do sistema
3. Implementar GPG quando houver necessidade jurídica concreta
4. Hardening da `OBSIDIAN_API_KEY` e outros secrets locais
5. Considerar push do repo SECURITY pro GitHub privado (backup + colaboração futura)
