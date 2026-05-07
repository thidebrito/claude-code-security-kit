# Playbook — Rotação de Credenciais Vazadas

**Quando usar:** se `gitleaks` ou auditoria detectar que uma credencial real foi commitada (mesmo que depois removida) num repo público ou que pode ser clonado.

**Princípio:** se vazou uma vez, considere comprometida. Rotacione.

---

## Ordem de prioridade (rotacionar primeiro o que dá mais dano)

### 🔴 CRÍTICO — rotacionar em até 1h
1. **Supabase service_role_key** — acesso total ao DB
2. **Hotmart Basic Token** — acesso a vendas, dados de compradores
3. **Meta Ads Access Token** — pode gastar verba, criar campanhas
4. **Google Ads Refresh Token** — mesmo de Meta
5. **Resend API Key** — pode enviar emails em massa em seu nome

### 🟡 ALTO — rotacionar em até 24h
6. Supabase anon_key (se exposta em repo privado, lower; em público, alto)
7. Vercel deploy tokens
8. GitHub PAT (se houver)
9. OpenAI / Anthropic API keys
10. Apify token

### 🟢 BAIXO — rotacionar quando der
11. Webhooks de canal (Slack, Discord, etc.)
12. Tokens de leitura-only

---

## Passos por serviço

### Supabase
1. Acessar https://supabase.com/dashboard/project/<PROJECT_ID>/settings/api
2. **Reset service_role key** (botão na seção "Project API keys")
3. Atualizar todos os ambientes: Vercel env vars, scripts locais, GitHub secrets
4. Conferir Realtime / functions deployed que usam a key
5. Deploy novo
6. **Audit logs:** https://supabase.com/dashboard/project/<PROJECT_ID>/logs/explorer — filtrar últimas 7 dias por uso anômalo

### Hotmart
1. Acessar https://app-vlc.hotmart.com/tools/api-credentials
2. Revogar credencial vazada
3. Gerar nova
4. Atualizar `hotmart-mcp/index.js` env, Vercel vars
5. Testar webhook

### Meta Ads / Pixel
- Pixel ID NÃO é segredo (é público no <head>)
- Access Token: regenerar em https://developers.facebook.com/tools/debug/accesstoken/
- Conferir Business Manager → Settings → System Users → Tokens

### Google Ads
1. Acessar Google Ads UI → Tools → API Center
2. Refresh token: regenerar via OAuth flow
3. Atualizar `google-ads-automation/.env`
4. Conferir Customer ID que rodaram nas últimas 48h

### Resend
1. Dashboard https://resend.com/api-keys
2. Revogar key
3. Criar nova
4. Atualizar `ebook_producao_musical` env vars no Vercel

---

## Limpeza do histórico Git (último recurso)

⚠️ **Reescreve histórico — coordenar se outras pessoas usam o repo.**

```bash
# 1. Backup full do repo
cp -R /path/to/repo /path/to/repo.bak.$(date +%Y%m%d)

# 2. Instalar git-filter-repo (não usar git filter-branch, deprecated)
brew install git-filter-repo

# 3. Listar arquivos a remover do histórico
echo "path/to/leaked-file.json" > /tmp/files-to-remove.txt

# 4. Remover (rewrite)
cd /path/to/repo
git filter-repo --paths-from-file /tmp/files-to-remove.txt --invert-paths

# 5. Force push (atenção: destrutivo, todos terão que re-clonar)
git push origin --force --all
git push origin --force --tags
```

---

## Pós-rotação

1. ✅ Confirmar que sistemas em prod ainda funcionam (smoke test)
2. ✅ Atualizar `.env.example` se nomes/formatos de variáveis mudaram
3. ✅ Documentar o incidente em `~/PROJETOS/claude-code-security-kit/reports/incidents/YYYY-MM-DD-<slug>.md`
4. ✅ Re-rodar `audit-projects.sh` pra confirmar limpeza
5. ✅ Considerar adicionar a credencial vazada ao gitleaks `.gitleaksignore` se for falso positivo
