---
description: Pipeline pré-deploy — aplica UUID + watermark + SHA-256 + OpenTimestamps no build de projeto público. Rodar ANTES de vercel deploy --prod.
---

# /secure-protect <pasta> — Proteção de autoria pré-deploy

Quando Thiago invoca `/secure-protect <pasta>`, roda o pipeline da Camada C do sistema THIDEBRITO-SECURITY no projeto, aplicando provas de autoria criptográficas antes do deploy em produção.

## Argumento

`<pasta>` — caminho do projeto. Ex: `~/PROJETOS/ebook_producao_musical/`

## Quando usar

✅ Aplicar em:
- LPs públicas (`ia-euro`, `ianapratica`)
- Site principal (`your-website-repo`)
- App PWA (`ebook_producao_musical`)
- LPs cliente (`lp-dr-felipe-machado`, `claucarvalho`)

❌ NÃO aplicar em:
- Projetos internos (`google-ads-automation`, `hotmart-mcp`, `autopilot`)
- Meta-projetos (`THIDEBRITO-SECURITY`)
- Projetos sem público externo

**Critério:** tem URL pública + IP que vale proteger? → aplica.

## Pré-requisitos

1. Build do projeto deve estar pronto (`dist/` populado ou similar)
2. Repo `~/PROJETOS/claude-code-security-kit/` clonado e atualizado
3. `node`, `npx` disponíveis no PATH

## Passos

### 1. Confirmar pre-requisitos

```bash
cd <pasta>
[ -d "dist" ] || [ -d "build" ] || [ -d "out" ] || ls *.html
```

Se faltar build, sugerir: `npm run build` ou `npm run build:prod`.

### 2. Rodar pipeline

```bash
node ~/PROJETOS/claude-code-security-kit/scripts/protect-build.mjs <pasta>
```

Pipeline:
1. Gera UUID v4 da build
2. Calcula SHA-256 de cada arquivo do `dist/`
3. Injeta watermarks invisíveis:
   - Meta tags HTML (x-author, x-author-id, x-built-at, x-canonical-source)
   - Comentário CSS header em todos `.css`
   - Variável JS `window.__TDB__` codificada em base64
   - Classe CSS marker `.tdb-<8chars>` em wrapper neutro
4. Gera `protection-manifest.json` no `dist/`
5. Roda `npx opentimestamps stamp` no manifest → cria `.ots`
6. Salva `.ots` em `~/PROJETOS/claude-code-security-kit/timestamps/<projeto>/<YYYY-MM-DD-HHmm>.ots`
7. Comita o `.ots` no repo SECURITY (prova versionada)

### 3. Verificar saídas

```bash
# No projeto:
cat <pasta>/dist/protection-manifest.json | head -20
grep -l "x-author-id" <pasta>/dist/index.html

# No SECURITY:
ls ~/PROJETOS/claude-code-security-kit/timestamps/<projeto>/
```

### 4. Lembrar Thiago

```
✅ Proteção aplicada em <projeto>

Build UUID: <uuid>
Manifest: dist/protection-manifest.json
Timestamp: timestamps/<projeto>/<YYYY-MM-DD-HHmm>.ots

📜 Prova de autoria registrada — aguardando ancoragem na blockchain Bitcoin
   (3-6h pra confirmação, automático)

Próximo passo:
   vercel deploy --prod
```

### 5. Pós-deploy (opcional, mais tarde)

Após 6-24h, atualizar a prova com a confirmação Bitcoin:
```bash
npx opentimestamps upgrade ~/PROJETOS/claude-code-security-kit/timestamps/<projeto>/<arquivo>.ots
```

## Limitações documentadas

1. Watermarks são **deterrents**, não barreiras absolutas
2. OpenTimestamps + SHA-256 SÃO prova jurídica forte
3. NÃO protege contra screenshot/redesign visual (trade dress)
4. Cobertura é a partir de hoje — versões antigas no Vercel ficam como estão

## Bypass / dry-run

```bash
# Só simular, não modificar arquivos:
node ~/PROJETOS/claude-code-security-kit/scripts/protect-build.mjs <pasta> --dry-run

# Pular timestamp (útil em testes locais):
node ~/PROJETOS/claude-code-security-kit/scripts/protect-build.mjs <pasta> --skip-timestamp
```

## Troubleshooting

- **Erro `opentimestamps not found`** → `npm i -g opentimestamps` ou usar via `npx`
- **OpenTimestamps server timeout** → tentar de novo (servidores agregam em batch a cada poucos minutos)
- **Watermark quebrou layout** → reportar bug, abrir no navegador antes do deploy
