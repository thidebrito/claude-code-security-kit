---
description: Inicializa projeto NOVO com todos os templates de segurança aplicados (gitignore, env.example, pre-commit hook, marker)
---

# /secure-init <pasta> — Inicializar projeto novo com segurança

Quando Thiago invoca `/secure-init <pasta>`, aplica todos os templates da Camada B do sistema THIDEBRITO-SECURITY no projeto, deixando-o pronto pra desenvolver com segurança desde o dia zero.

## Argumento

`<pasta>` — caminho absoluto ou relativo do projeto (ex: `~/PROJETOS/novo-projeto/`, `.`)

Se omitir, usa `pwd` (pasta atual).

## Passos

### 1. Detectar tipo do projeto

```bash
# Auto-detect:
# - tem package.json com react/vite/next → "react"
# - tem package.json sem react → "node"
# - tem index.html ou *.html → "web"
# - default → "node"
```

Confirmar tipo com Thiago se ambíguo.

### 2. Aplicar template

```bash
bash ~/PROJETOS/claude-code-security-kit/scripts/apply-template.sh <pasta>
```

Isso faz:
- Cria/atualiza `.gitignore` (universal + tipo específico)
- Cria `.env.example` (se não existir)
- Instala git hook `pre-commit` (se for repo Git)
- Cria `.security-applied` marker

### 3. Verificar resultado

```bash
cd <pasta>
ls -la .gitignore .env.example .security-applied
[ -d .git ] && ls -la .git/hooks/pre-commit
```

### 4. Sugerir commit (não fazer automaticamente)

```
Próximos passos:
  1. cd <pasta>
  2. git init  # se ainda não for repo
  3. git status
  4. git add .gitignore .env.example .security-applied
  5. git commit -m "chore: setup inicial segurança THIDEBRITO-SECURITY"
```

### 5. Se for projeto público (LP, blog, app)

Lembrar Thiago que antes do primeiro deploy:
```
/secure-protect <pasta>
```

## Exemplo de output esperado

```
🛡️  Aplicando templates de segurança em: novo-projeto
    Path: $HOME/PROJETOS/novo-projeto
    Tipo: react
    Dry-run: não

  ✅ .gitignore atualizado (87 linhas)
  ✅ .env.example criado
  ✅ pre-commit hook instalado
  ✅ .security-applied marker criado

🛡️  Aplicação concluída em: novo-projeto

Próximos passos sugeridos:
  1. cd $HOME/PROJETOS/novo-projeto && git status
  2. git add .gitignore .env.example .security-applied
  3. git commit -m "chore: aplicar templates de segurança THIDEBRITO-SECURITY"
```

## Não fazer

- Não rodar `git init` automaticamente (Thiago pode preferir não-Git)
- Não commitar automaticamente
- Não sobrescrever `.env` real (apenas `.env.example`)
- Não tocar em `.git/` além de instalar o hook `pre-commit`
