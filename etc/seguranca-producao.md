# Plano de Segurança Genérico — Dolibarr ERP

> Documento unificado que mescla análise de risco nos scripts do repositório (CWE,
> hardcoded secrets, sed em core) com plano prático de hardening de infraestrutura
> (firewall, fail2ban, TLS, WAF, AppArmor). Projetado para ser reutilizável em
> qualquer topologia sem IPs fixos.

---

## Topologia Referência (parametrizável)

```
  ${ADMIN_IP} — Desktop de administração (SSH)
       │
       ├── ${APP_IP} — Servidor de aplicação (Apache + PHP-FPM + Dolibarr)
       ├── ${DB_IP} — Servidor de banco (MariaDB)
       └── ${PROXY_IP} — Proxy reverso com SSL (Nginx, NPM, etc.)
```

```
  Usuário → ${DOMINIO}
               ↓ DNS
           ${PROXY_IP}:443 — SSL (Let's Encrypt)
               ↓ proxy_pass http://${APP_IP}:80 (X-Forwarded-Proto, X-Forwarded-For, Host)
           Apache ${APP_IP}:80 + ModSecurity
               ↓ PHP-FPM
           Dolibarr
               ↓ TCP 3306 (TLS)
           MariaDB ${DB_IP}
```

### Variáveis de ambiente (substituir conforme o deployment)

| Variável | Descrição | Exemplo |
|----------|-----------|---------|
| `${DOMINIO}` | Domínio público do sistema | meuerp.anderson.com.br |
| `${APP_IP}` | IP do servidor de aplicação | 172.16.0.142 |
| `${DB_IP}` | IP do servidor de banco | 172.16.0.200 |
| `${PROXY_IP}` | IP do proxy reverso/SSL | 172.16.0.86 |
| `${ADMIN_IP}` | IP do desktop de administração | 172.16.254.248 |
| `${DOLI_DIR}` | Diretório de instalação do Dolibarr | /var/www/dolibarr-23.0.2/htdocs |

---

## Fase 0 — Premissas

- Servidores Debian (root direto, sem sudo)
- MariaDB remoto com IP fixo do App Server (nunca `%`)
- Repo: `https://github.com/4nd3r50n00/dolisystem.git`
- Senhas geradas aleatoriamente e salvas em `.dolibarr_db_credentials` (chmod 600)

---

## Fase 1 — Segurança no Código dos Scripts

> Origem: RevisarSegurança2kimi26.md — riscos nos arquivos do repositório.

### 1.1 Credenciais externalizadas (CWE-798)

**Risco**: Strings sensíveis (`DB_USER`, `DB_PASS`) hardcoded nos scripts.

**Ação**:
- Todo script deve carregar credenciais via `source "${SCRIPT_DIR}/.dolibarr_db_credentials"`
- Nunca definir `DB_USER`, `DB_PASS`, `DB_HOST` como literal no corpo do script
- `.dolibarr_db_credentials` com `chmod 600` e incluído no `.gitignore`

### 1.2 SQL Injection nos heredocs (CWE-89)

**Risco**: Variáveis interpoladas em strings SQL dentro de heredocs bash.

**Ação**:
- Usar `mysql -e` com aspas simples no heredoc delimiter (`<<'EOF'`) sempre que possível, evitando interpolação pelo shell
- Para casos que exigem variáveis, escapar com `$(printf '%q' "${VAR}")`
- Validar valores antes de interpolar (ex: nome do banco só letras/números)

```bash
# Seguro (sem interpolação):
mysql -h "${DB_HOST}" -u "${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" <<'EOF'
CREATE TABLE IF NOT EXISTS llx_exemplo (id INT);
EOF

# Com variável — escapar:
DB_SAFE=$(printf '%q' "${DB_NAME}")
mysql -h "${DB_HOST}" -u "${DB_USER}" "${DB_NAME}" <<EOF
SELECT * FROM \`${DB_SAFE}\`.llx_const;
EOF
```

### 1.3 `sed` sem validação em core files (CWE-20)

**Risco**: `sed` buscando padrões específicos pode corromper arquivos se o padrão mudar em atualizações do Dolibarr.

**Ação**:
- Preferir `perl -pi -e` quando o padrão contém aspas ou caracteres especiais (já implementado para meta author em `custom.sh`)
- Sempre fazer backup antes (`cp -f ${ARQUIVO} ${ARQUIVO}.bak`)
- Validar sintaxe após alteração: `php -l "${ARQUIVO}"`
- **Alternativa definitiva**: Criar módulo Dolibarr custom em `htdocs/custom/` ao invés de alterar core files

### 1.4 `set -e` sem rollback

**Risco**: Falha em meio à execução deixa o sistema em estado inconsistente.

**Ação**:
```bash
set -e
trap 'echo "[ERRO] Script falhou na linha $LINENO"; exit 1' ERR
# Adicionar funções de rollback no trap
```

### 1.5 Hash de integridade de download

**Risco**: Download corrompido ou comprometido do GitHub sem verificação.

**Ação**:
- Tornar obrigatória a checagem de `sha256sum` no `autoinstall.sh` (hoje é opcional)
- Esperar o hash em `--sha256` como flag obrigatória para produção
- Registrar hash esperado no repositório para cada versão

### 1.6 Rollback de customizações

**Risco**: `custom.sh` aplica SQL e arquivos sem forma de reverter.

**Ação**: Criar `etc/rollback.sh`:
- Restaurar `.bak` de todos os arquivos alterados por `sed`/`perl`
- Reverter INSERTs SQL via DELETE (guardar valores originais)
- Remover arquivos copiados do ThemePack

### 1.7 CWE Mapping

| CWE | Descrição | Onde | Status |
|-----|-----------|------|--------|
| CWE-798 | Hardcoded Credentials | autoinstall.sh (DB_USER, DB_PASS literais) | Parcial (já usa `.dolibarr_db_credentials`) |
| CWE-20 | Improper Input Validation | sed em societe/card.php, main.inc.php | Parcial (perl substituiu sed em alguns locais) |
| CWE-89 | SQL Injection | Heredocs com variáveis em custom.sh, migrate | Não tratado |
| CWE-829 | Inclusion of Functionality from Untrusted Source | wget do GitHub sem hash obrigatório | Parcial (hash opcional) |

---

## Fase 2 — Segurança na Infraestrutura

> Origem: seguranca-producao.md — hardening dos servidores.

### 2.1 UFW — Firewall (todos os servidores)

**Propósito**: Restringir acesso a portas apenas às origens necessárias.

```bash
apt install -y ufw
ufw default deny incoming
ufw default allow outgoing

# App Server:
ufw allow from ${ADMIN_IP} to any port 22 proto tcp
ufw allow from ${PROXY_IP} to any port 80 proto tcp

# DB Server:
ufw allow from ${ADMIN_IP} to any port 22 proto tcp
ufw allow from ${APP_IP} to any port 3306 proto tcp

# Proxy Server:
ufw allow from ${ADMIN_IP} to any port 22 proto tcp
ufw allow 80/tcp
ufw allow 443/tcp

ufw --force enable
```

### 2.2 SSH Hardening (todos os servidores)

**Propósito**: Eliminar senha como fator de autenticação SSH.

```bash
# No desktop administrativo:
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_dolisystem
ssh-copy-id -i ~/.ssh/id_ed25519_dolisystem root@${APP_IP}
ssh-copy-id -i ~/.ssh/id_ed25519_dolisystem root@${DB_IP}
ssh-copy-id -i ~/.ssh/id_ed25519_dolisystem root@${PROXY_IP}
```

`/etc/ssh/sshd_config` (em todos os servidores):
```ini
Port 22
PermitRootLogin prohibit-password
PubkeyAuthentication yes
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
```

```bash
systemctl restart sshd
```

### 2.3 Fail2ban (todos os servidores)

**Propósito**: Bloquear IPs após tentativas repetidas de acesso inválido.

```bash
apt install -y fail2ban
```

`/etc/fail2ban/jail.local`:
```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
```

`/etc/fail2ban/jail.d/dolibarr.conf` (App Server apenas):
```ini
[dolibarr]
enabled = true
port = http,https
logpath = /var/log/apache2/dolibarr-error.log
maxretry = 10
findtime = 300
bantime = 1800
failregex = ^%(_apache_error_client)s POST /(comm/ptv/login|comm/login).* 403
```

`/etc/fail2ban/jail.d/mariadb.conf` (DB Server apenas):
```ini
[mariadb]
enabled = true
port = 3306
logpath = /var/log/mysql/mariadb.log
maxretry = 5
findtime = 300
bantime = 3600
```

```bash
systemctl enable fail2ban --now
```

### 2.4 Trust Proxy — mod_remoteip (App Server)

**Propósito**: Dolibarr enxergar o IP real do visitante, não o IP do proxy.

```bash
a2enmod remoteip
```

`/etc/apache2/conf-available/remoteip.conf`:
```apache
RemoteIPHeader X-Forwarded-For
RemoteIPInternalProxy ${PROXY_IP}
```

```bash
a2enconf remoteip
```

### 2.5 Ocultar versão Apache (App Server)

**Propósito**: Anti-fingerprinting — não expor versão do servidor nos headers HTTP.

```bash
sed -i 's/^ServerTokens.*/ServerTokens Prod/' /etc/apache2/conf-enabled/security.conf
sed -i 's/^ServerSignature.*/ServerSignature Off/' /etc/apache2/conf-enabled/security.conf
```

### 2.6 ModSecurity + OWASP CRS (App Server)

**Propósito**: WAF (Web Application Firewall) bloqueia SQL injection, XSS, path traversal, etc.

```bash
apt install -y libapache2-mod-security2
mv /etc/modsecurity/modsecurity.conf{-recommended,}
```

`/etc/modsecurity/modsecurity.conf`:
```apache
SecRuleEngine On
SecRequestBodyAccess On
SecResponseBodyAccess Off
SecRequestBodyLimit 13107200
SecRequestBodyNoFilesLimit 131072
SecRuleInheritance Off
```

```bash
cd /usr/share/modsecurity-crs
git clone https://github.com/coreruleset/coreruleset.git owasp-crs
cp owasp-crs/crs-setup.conf.example owasp-crs/crs-setup.conf
a2enmod security2
systemctl restart apache2
```

### 2.7 DB TLS — Criptografia em trânsito (App + DB)

**Propósito**: Dados trafegam criptografados entre App Server e DB Server.

```bash
# DB Server:
mkdir -p /etc/mysql/ssl && cd /etc/mysql/ssl
openssl genrsa 2048 > ca-key.pem
openssl req -new -x509 -nodes -days 3650 -key ca-key.pem -out ca.pem \
  -subj "/CN=MariaDB-CA"
openssl req -newkey rsa:2048 -nodes -keyout server-key.pem -out server-req.pem \
  -subj "/CN=${DB_IP}"
openssl x509 -req -days 3650 -set_serial 01 -in server-req.pem -out server-cert.pem \
  -CA ca.pem -CAkey ca-key.pem
chmod 600 *.pem && chown mysql:mysql *.pem
```

`/etc/mysql/mariadb.conf.d/90-ssl.cnf` (DB Server):
```ini
[mariadb]
ssl-ca = /etc/mysql/ssl/ca.pem
ssl-cert = /etc/mysql/ssl/server-cert.pem
ssl-key = /etc/mysql/ssl/server-key.pem
require-secure-transport = ON
```

```bash
systemctl restart mariadb
```

Copiar `ca.pem` para `/etc/mysql/ssl/ca.pem` no App Server.

```sql
ALTER USER 'dolibarr_app'@'${APP_IP}' REQUIRE SSL;
```

### 2.8 AppArmor — Confinamento de processos (App Server)

**Propósito**: Restringir o que Apache/PHP podem acessar no sistema.

```bash
apt install -y apparmor apparmor-utils apparmor-profile-apache2
```

Iniciar em modo `complain` (apenas logging, não bloqueia):
```bash
aa-complain /etc/apparmor.d/usr.sbin.apache2
# Monitorar /var/log/syslog por violações por alguns dias
```

Após validar, ativar:
```bash
aa-enforce /etc/apparmor.d/usr.sbin.apache2
```

### 2.9 Auditd — Monitoramento de integridade (App Server)

**Propósito**: Registrar alterações em arquivos críticos.

```bash
apt install -y auditd
```

`/etc/audit/rules.d/dolibarr.rules`:
```audit
-w ${DOLI_DIR}/conf/conf.php -p wa -k dolibarr-conf
-w ${DOLI_DIR}/main.inc.php -p wa -k dolibarr-core
-w /etc/apache2/ -p wa -k apache-conf
```

```bash
auditctl -R /etc/audit/rules.d/dolibarr.rules
systemctl restart auditd
```

### 2.10 Proxy Reverso — Configuração

| Campo | Valor |
|-------|-------|
| Domain | `${DOMINIO}` |
| Forward | `http://${APP_IP}:80` |
| SSL | Let's Encrypt |
| `proxy_set_header X-Forwarded-Proto $scheme;` | Obrigatório |
| `proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;` | Obrigatório |
| `proxy_set_header Host $host;` | Obrigatório |
| `proxy_read_timeout` | 300s (PDFs grandes) |

Headers de segurança ficam no Apache (não no proxy).

---

## Fase 3 — Aplicação (conf.php)

**Propósito**: Configurações obrigatórias no Dolibarr para produção com proxy HTTPS.

```php
// No arquivo ${DOLI_DIR}/conf/conf.php:

$dolibarr_main_prod = '1';                              // Modo produção
$dolibarr_main_url_root = 'https://${DOMINIO}';          // URL pública com HTTPS
$dolibarr_main_url = 'https://${DOMINIO}';
$dolibarr_main_force_https = '1';                        // Forçar HTTPS interno

// Sessão segura
ini_set('session.cookie_httponly', '1');
ini_set('session.cookie_secure', '1');
ini_set('session.use_strict_mode', '1');

// (Opcional) Restringir comandos do sistema
$dolibarr_main_restrict_os_commands = 'mariadb-dump, mariadb, mysqldump, mysql';
```

**Pós-instalação — segurança imediata**:
```bash
rm -rf ${DOLI_DIR}/install/
touch ${DOLI_DIR}/documents/install.lock
```

---

## Ordem de Implementação Recomendada

```
Fase 1 — Código (repositório)
  [ ] 1.1 Credenciais externalizadas
  [ ] 1.2 SQL sanitizado nos heredocs
  [ ] 1.3 perl no lugar de sed, backup + php -l
  [ ] 1.4 trap ERR + rollback.sh
  [ ] 1.5 sha256sum obrigatório no download

Fase 2 — Infraestrutura base
  [ ] 2.1 UFW (todos servidores)
  [ ] 2.2 SSH hardening (todos)
  [ ] 2.3 Fail2ban (todos)

Fase 3 — Servidor de aplicação
  [ ] 2.4 Trust proxy (mod_remoteip)
  [ ] 2.5 ServerTokens Prod
  [ ] 2.6 ModSecurity + OWASP
  [ ] 3.0 conf.php (prod, domínio, force_https, cookie_secure)
  [ ] Remover install/ + criar install.lock
  [ ] 2.9 Auditd

Fase 4 — Banco de dados
  [ ] 2.7 DB TLS (CA + certificados + REQUIRE SSL)

Fase 5 — Hardening avançado
  [ ] 2.8 AppArmor (complain → enforce)

Fase 6 — Proxy
  [ ] 2.10 Configurar NPM / Nginx
  [ ] Testar acesso público via ${DOMINIO}
```

---

## Matriz por Servidor

| Camada | App (${APP_IP}) | DB (${DB_IP}) | Proxy (${PROXY_IP}) |
|--------|-----------------|---------------|---------------------|
| UFW | ${ADMIN_IP}:22, ${PROXY_IP}:80 | ${ADMIN_IP}:22, ${APP_IP}:3306 | ${ADMIN_IP}:22, 80/tcp, 443/tcp |
| Fail2ban | SSH + Dolibarr | SSH + MariaDB | SSH + Nginx |
| SSH key-only | ✅ | ✅ | ✅ |
| ModSecurity | ✅ | — | — |
| DB TLS | cliente | servidor | — |
| AppArmor | ✅ | — | — |
| Auditd | ✅ | — | — |
| ServerTokens | ✅ | — | — |
| Trust proxy | ✅ | — | — |
| SSL cert | — | — | Let's Encrypt |
| Código seguro | scripts do repo | — | — |
| conf.php prod | ✅ | — | — |

---

## Referências

- **RevisarSegurança2kimi26.md**: Análise CWE, riscos em scripts shell, validação de input
- **seguranca-producao.md** (versão anterior): Plano com IPs fixos para deployment específico
- **autoinstall.sh**: Script de instalação automatizada
- **custom.sh**: Script de customização pós-instalação
- **Steps.md**: Documentação completa do setup
