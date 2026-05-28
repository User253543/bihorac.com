# Rollback Anti-Bot

## Repo-Layer rückgängig
git revert <commit-hash> für die 5 Anti-Bot-Commits
git push origin master

## Cloudflare rückgängig
- Dashboard → Security → Bots → Bot Fight Mode: OFF
- Dashboard → Security → Bots → Block AI Scrapers: OFF
- Dashboard → Security → WAF → Custom Rules: alle Rules deaktivieren
- Dashboard → Rules → Transform Rules: alle deaktivieren
- Dashboard → DNS: orange Wolke auf grau (Proxy aus) wenn komplett raus aus Cloudflare

## Komplett-Exit Cloudflare
- Nameserver beim Registrar zurück auf GitHub/altes Setup
- Wartezeit: bis 24h DNS-Propagation
