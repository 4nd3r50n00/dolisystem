# AGENTS.md

## Active Scripts (use these)

| Script | Purpose | Lines |
|--------|---------|-------|
| `startup_v2.sh` | Install Dolibarr + Apache + PHP + DB (local or remote) | 938 |
| `migrate_customizations_v2.sh` | Apply ThemePack, DB config, anti-fingerprinting | ~300 |
| `migrate_customizations_llxhq.sql` | Same SQL for phpMyAdmin import (InfinityFree, prefix `llxhq_`) | 192 |

All other `.sh` files are v1/legacy — do not edit unless explicitly asked.

## Execution Order (CRITICAL)

```
1. startup_v2.sh install       # installs packages, creates conf.php, writes .dolibarr_db_credentials
2. http://<IP>/install/         # Dolibarr web installer — creates DB tables
3. rm -rf .../htdocs/install/   # remove installer
4. touch .../htdocs/documents/install.lock
5. migrate_customizations_v2.sh # ONLY after tables exist
```

**migrate_customizations_v2.sh MUST run after install.php.** If run before, DB tables don't exist. The script now has a `SKIP_SQL` guard that checks for `llx_const` table — if missing, it skips all SQL but still copies files. You must re-run migrate after install.php to apply the SQL.

## Architecture

- **Two-server deployment**: App server (Apache + PHP) connects to separate DB server (MariaDB)
- **DB credentials file**: `.dolibarr_db_credentials` — created by startup, sourced by migrate. Keys: `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASS`, `DB_TYPE`
- **Remote DB detection**: migrate reads `DB_HOST` from credentials file. If not `localhost`/`127.0.0.1`, it temporarily installs `default-mysql-client`, runs SQL, then removes the client
- **DB user scope**: Remote DB users created with App server IP (e.g. `'dolibarr_app'@'10.0.0.5'`), never `'%'`
- **No sudo**: Servers run as root directly (Debian)

## ThemePack → Dolibarr Mapping

`ThemePack/htdocs/` mirrors the Dolibarr install at `/var/www/dolibarr-23.0.2/htdocs/`. The migrate script `cp -f` copies 547 files from ThemePack into the live install. Changes to ThemePack files take effect on next migrate run.

## Anti-Fingerprinting sed — Known Pitfalls

### 1. Meta author in `main.inc.php:1685`
The line is inside `print '...'."\n";` — a PHP string literal, not standalone HTML.

- **CORRECT**: Replace with `''.getDolGlobalString('MAIN_APPLICATION_TITLE', '').'` (breaks out of single-quoted string via empty-string concatenation)
- **BROKEN** (v1): `<?php echo getDolGlobalString(...) ?>` — inserts raw PHP tags inside a string literal → parse error → HTTP 500 on every page

### 2. "Powered by Dolibarr" block in `company.lib.php`
- Current sed uses range `/if (!getDolGlobalString.*MAIN_HIDE_POWERED_BY.*)/,/^[[:space:]]*$/`
- End pattern `^[[:space:]]*$` matches a **blank line**, not the closing `}` — can overshoot and eat extra lines
- **Should be**: `^[[:space:]]*}[[:space:]]*$` (matches the closing brace)

### 3. JS comment sed order matters
Two sed commands target `"Includes JS of Dolibarr"` and `"Includes JS of Dolibarr (browser layout..."`. The longer pattern must run first. If reversed, the shorter match runs first, modifying the line so the longer pattern never matches.

## Applied Fixes (2025-05)

| Fix | Details |
|-----|---------|
| Meta author: sed → perl | `perl -pi -e` replaces only the text substring `Dolibarr Development Team` → `''.getDolGlobalString('MAIN_APPLICATION_TITLE', '').'`, preserving PHP string delimiters. Sed broke this twice. |
| Range sed end-pattern | `^[[:space:]]*$` → `^[[:space:]]*}[[:space:]]*$` — matches closing brace, not blank line |
| SKIP_SQL guard | Checks `llx_const` table existence; sets `SKIP_SQL=1` if missing; all `$DB_CMD` calls wrapped in `if [[ "$SKIP_SQL" -ne 1 ]]` |
| Apache restart | `systemctl restart apache2` at end of migrate (vhost config + OPcache) |
| php -l syntax check | After each sed on PHP files, runs `php -l`; on failure, restores `.bak` backup |
| Permissions | `chown www-data:www-data` after all `cp -f` operations |
| `2>/dev/null` → `&>/dev/null` | Both startup_v2.sh:770 and migrate_customizations_v2.sh cleanup |
| Error message fix | "startup.sh" → "startup_v2.sh" in migrate error output |

## Remaining Low-Priority Items

| File | Issue | Notes |
|------|-------|-------|
| `START.md` | References v1 scripts only, no remote DB docs | Needs full v2 update |

## Shared Hosting (InfinityFree)

- No shell — only FTP + phpMyAdmin
- DB prefix: `llxhq_` (not `llx_`)
- Use `migrate_customizations_llxhq.sql` for phpMyAdmin import
- ThemePack files must be uploaded via FTP to matching paths
- Anti-fingerprinting sed must be applied **locally before upload** (no shell on server)
- Logo upload via FTP to `documents/mycompany/logos/` + SQL INSERT for `MAIN_INFO_SOCIETE_LOGO` / `LOGO_SMALL` / `LOGO_MINI` (web upload fails due to permissions)

## DB Connection

- No `-p${DB_PASS}` on command line (visible in `ps`) — use `export MYSQL_PWD="$DB_PASS"` instead
- Connectivity test: `nc -zv -w5 $DB_HOST $DB_PORT` or `timeout 5 bash -c "echo > /dev/tcp/$DB_HOST/$DB_PORT"`
- `ss -tlnp | grep 3306` (not `netstat` — may not be installed)

## Git

- Repo: `https://github.com/4nd3r50n00/dolisystem.git`
- User: Anderson Agostinho <andersonemeuemail@gmail.com>
- `.dolibarr_db_credentials` and `.dolibarr_admin` are in `.gitignore` — never commit these