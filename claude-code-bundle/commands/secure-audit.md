---
description: Audita projeto(s) existente(s) — gitignore, marker, secret scan via gitleaks. Gera relatório consolidado em reports/.
---

# /secure-audit [pasta] — Auditar projeto existente

Quando Thiago invoca `/secure-audit [pasta]`, roda auditoria completa de segurança do projeto.

## Argumento

`[pasta]` — opcional. Se omitido, audita TODOS os projetos do ecossistema (`~/PROJETOS/*` + `~/your-project`).

Se passar nome parcial (ex: `ebook`), filtra projetos cujo nome contém essa string.

## Passos

### 1. Rodar auditoria

```bash
# Auditar tudo:
bash ~/PROJETOS/claude-code-security-kit/scripts/audit-projects.sh

# Filtrar por nome:
bash ~/PROJETOS/claude-code-security-kit/scripts/audit-projects.sh --only <nome>

# Modo rápido (sem gitleaks):
bash ~/PROJETOS/claude-code-security-kit/scripts/audit-projects.sh --quick
```

### 2. Apresentar resultado consolidado

Ler `reports/audit-YYYY-MM-DD-HHMM.json` e exibir:

```
📊 RESUMO DA AUDITORIA — 2026-05-06

✅ PROTEGIDOS (X projetos):
   - projeto-a (gitignore ✓, marker ✓, sem leaks)

⚠️  ATENÇÃO (Y projetos):
   - projeto-b: sem .gitignore
   - projeto-c: sem marker .security-applied

🚨 CRÍTICO (Z projetos):
   - projeto-d: 4 leaks detectados em últimos 50 commits
   - projeto-e: .env real não-gitignored
```

### 3. Para cada projeto crítico, sugerir ação

Baseado no relatório:

| Achado | Ação sugerida |
|--------|---------------|
| Sem `.gitignore` | `bash apply-template.sh <projeto>` |
| Sem marker | `bash apply-template.sh <projeto>` |
| Leaks em histórico | Consultar `reports/details/<projeto>-leaks.json` + playbook `rotate-credentials.md` |
| `.env` real não-gitignored | URGENTE: adicionar ao `.gitignore`, rotacionar todas as credenciais que ele continha |
| Pre-commit hook ausente | `bash apply-template.sh <projeto>` |

### 4. Não aplicar correções automaticamente

Apresentar achados → aguardar Thiago decidir o que fazer.

Razão: rotacionar credenciais ou alterar projeto em prod é decisão de risco.

### 5. Sumarizar próximos passos

```
PRÓXIMOS PASSOS RECOMENDADOS:

Imediato (hoje):
  □ Rotacionar credencial X em projeto Y (consultar rotate-credentials.md)
  □ Adicionar .env ao .gitignore em projeto Z

Em breve (até 7 dias):
  □ Aplicar template em N projetos sem .gitignore
  □ Aplicar marker em todos via /secure-init

Estratégico:
  □ Avaliar push de gh repos privados pra reduzir surface
  □ Considerar GPG signing nos repos críticos
```

## Privacidade

- gitleaks roda com `--redact` por padrão (segredo não aparece no output)
- NÃO exibir o valor real de leak detectado, mesmo que esteja redacted
- Apenas mostrar: tipo de regra, arquivo afetado, commit (autor/data)

## Auditoria do `~/.claude/settings.json`

A skill `seguranca-projeto` roda este check adicional:
- Detectar credenciais em plain text no `settings.json`
- Sugerir migração pra `.env` carregado por shell wrapper, ou macOS Keychain

## Exemplo de uso

```
/secure-audit                  # tudo
/secure-audit ebook            # só projetos com "ebook" no nome
/secure-audit ~/PROJETOS/ia-euro  # path específico
```
