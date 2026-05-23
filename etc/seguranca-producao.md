# Plano de Segurança — Produção Dolibarr

## Topologia

```
Desktop (172.16.254.248) — administração SSH
  │
  ├── App Server (172.16.0.142) — Apache + PHP-FPM + Dolibarr
  ├── DB Server (172.16.0.200) — MariaDB
  └── Nginx Proxy Manager (172.16.0.86) — SSL Let's Encrypt
```

```
Usuário → meuerp.anderson.com.br
             ↓ DNS
         Nginx Proxy Manager (172.16.0.86):443 — SSL
             ↓ proxy_pass http://172.16.0.142:80 (X-Forwarded-Proto, X-Forwarded-For, Host)
         Apache (172.16.0.142:80) + ModSecurity
             ↓ PHP-FPM
         Dolibarr
             ↓ TCP 3306 (TLS)
         MariaDB (172.16.0.200)
```

---

## 1. Firewall (UFW) — Todos os Servidores

### App Server (172.16.0.142)

```bash
apt install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow from 172.16.254.248 to any port 22 proto tcp    # SSH administração
ufw allow from 172.16.0.86 to any port 80 proto tcp       # Nginx Proxy
ufw --force enable
```

### DB Server (172.16.0.200)

```bash
apt install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow from 172.16.254.248 to any port 22 proto tcp    # SSH administração
ufw allow from 172.16.0.142 to any port 3306 proto tcp    # App Server
ufw --force enable
```

### Nginx Proxy Manager (172.16.0.86)

```bash
apt install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow from 172.16.254.248 to any port 22 proto tcp    # SSH administração
ufw allow 80/tcp                                           # HTTP público (redirect)
ufw allow 443/tcp                                          # HTTPS público
ufw --force enable
```

---

## 2. Fail2ban — Todos os Servidores

### Instalação

```bash
apt install -y fail2ban
```

### SSH (todos os servidores)

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

### Dolibarr (App Server apenas)

`/etc/fail2ban/jail.d/dolibarr.conf`:
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

### MariaDB (DB Server apenas)

`/etc/fail2ban/jail.d/mariadb.conf`:
```ini
[mariadb]
enabled = true
port = 3306
logpath = /var/log/mysql/mariadb.log
maxretry = 5
findtime = 300
bantime = 3600
```

### Ativar

```bash
systemctl enable fail2ban --now
```

---

## 3. SSH Hardening — Todos os Servidores

```bash
# Gerar chave no desktop e copiar para cada servidor
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_dolisystem
ssh-copy-id -i ~/.ssh/id_ed25519_dolisystem root@172.16.0.142
ssh-copy-id -i ~/.ssh/id_ed25519_dolisystem root@172.16.0.200
ssh-copy-id -i ~/.ssh/id_ed25519_dolisystem root@172.16.0.86
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

---

## 4. ModSecurity + OWASP CRS — App Server

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
# OWASP Core Rule Set
cd /usr/share/modsecurity-crs
git clone https://github.com/coreruleset/coreruleset.git owasp-crs
cp owasp-crs/crs-setup.conf.example owasp-crs/crs-setup.conf

# Ativar no Apache
a2enmod security2
systemctl restart apache2
```

---

## 5. DB TLS (MariaDB) — App Server ↔ DB Server

### No DB Server (172.16.0.200)

```bash
# Criar CA e certificados
mkdir -p /etc/mysql/ssl && cd /etc/mysql/ssl
openssl genrsa 2048 > ca-key.pem
openssl req -new -x509 -nodes -days 3650 -key ca-key.pem -out ca.pem \
  -subj "/CN=MariaDB-CA"

openssl req -newkey rsa:2048 -nodes -keyout server-key.pem -out server-req.pem \
  -subj "/CN=172.16.0.200"
openssl x509 -req -days 3650 -set_serial 01 -in server-req.pem -out server-cert.pem \
  -CA ca.pem -CAkey ca-key.pem

chmod 600 *.pem && chown mysql:mysql *.pem
```

`/etc/mysql/mariadb.conf.d/90-ssl.cnf`:
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

### No App Server (172.16.0.142)

```bash
mkdir -p /etc/mysql/ssl
```

Copiar `ca.pem` do DB Server para `/etc/mysql/ssl/ca.pem` no App Server.

```bash
chmod 600 /etc/mysql/ssl/ca.pem
```

Criar usuário MariaDB com SSL obrigatório:
```sql
ALTER USER 'dolibarr_app'@'172.16.0.142' REQUIRE SSL;
```

`conf.php` — Dolibarr já suporta SSL nativamente via parâmetros:
```php
$dolibarr_main_db_host = '172.16.0.200';
$dolibarr_main_db_port = '3306';
// Opções SSL adicionais via mysqli (Dolibarr 23+):
// Definir constantes extras se necessário
```

---

## 6. AppArmor — App Server

```bash
apt install -y apparmor apparmor-utils
aa-status  # Verificar se o kernel suporta
```

Perfil AppArmor para Apache:
```bash
apt install -y apparmor-profile-apache2
aa-enforce /etc/apparmor.d/usr.sbin.apache2
```

**Cuidado**: AppArmor requer monitoramento inicial e pode quebrar funcionalidades se muito restritivo. Recomendo começar em modo `complain` por alguns dias:
```bash
aa-complain /etc/apparmor.d/usr.sbin.apache2
# Após validar logs:
aa-enforce /etc/apparmor.d/usr.sbin.apache2
```

---

## 7. Auditd — App Server

```bash
apt install -y auditd
```

`/etc/audit/rules.d/dolibarr.rules`:
```audit
-w /var/www/dolibarr-23.0.2/htdocs/conf/conf.php -p wa -k dolibarr-conf
-w /var/www/dolibarr-23.0.2/htdocs/main.inc.php -p wa -k dolibarr-core
-w /etc/apache2/ -p wa -k apache-conf
```

```bash
auditctl -R /etc/audit/rules.d/dolibarr.rules
systemctl restart auditd
```

---

## 8. Ocultar Versão Apache — App Server

```bash
sed -i 's/^ServerTokens.*/ServerTokens Prod/' /etc/apache2/conf-enabled/security.conf
sed -i 's/^ServerSignature.*/ServerSignature Off/' /etc/apache2/conf-enabled/security.conf
```

---

## 9. Trust Proxy — App Server (já implementado)

```bash
a2enmod remoteip
cat > /etc/apache2/conf-available/remoteip.conf << 'EOF'
RemoteIPHeader X-Forwarded-For
RemoteIPInternalProxy 172.16.0.86
EOF
a2enconf remoteip
```

---

## 10. Nginx Proxy Manager — Configuração

| Campo | Valor |
|-------|-------|
| Domain | `meuerp.anderson.com.br` |
| Forward | `http://172.16.0.142:80` |
| SSL | Let's Encrypt ✅ |
| Cache Assets | Ligar (opcional) |
| Websockets | Desligado |
| `proxy_set_header X-Forwarded-Proto $scheme;` | Verificar (default NPM envia) |
| `proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;` | Verificar (default NPM envia) |
| `proxy_set_header Host $host;` | Verificar (default NPM envia) |

Headers de segurança ficam no Apache, não no NPM.

---

## 11. Ordem de Execução Recomendada

```
Fase 1 — Infraestrutura de rede
  1. UFW em todos os servidores
  2. Verificar conectividade

Fase 2 — Acesso remoto seguro
  3. Chave SSH em todos os servidores
  4. Desabilitar senha SSH
  5. Fail2ban em todos

Fase 3 — Servidor de aplicação
  6. conf.php: prod=1, domínio, force_https, cookie_secure
  7. Trust proxy (mod_remoteip)
  8. ServerTokens Prod
  9. ModSecurity OWASP

Fase 4 — Banco de dados
  10. TLS entre App e DB
  11. Usuário DB com REQUIRE SSL

Fase 5 — Hardening avançado
  12. AppArmor (modo complain → enforce)
  13. Auditd + regras

Fase 6 — NPM
  14. Configurar proxy host + SSL
  15. Testar acesso público
```

---

## Resumo por Servidor

| Camada | App (142) | DB (200) | NPM (86) |
|--------|-----------|----------|----------|
| UFW | ✅ | ✅ | ✅ |
| Fail2ban | ✅ SSH+Doli | ✅ SSH+Maria | ✅ SSH+Nginx |
| SSH key-only | ✅ | ✅ | ✅ |
| ModSecurity | ✅ | — | — |
| DB TLS | ✅ cliente | ✅ servidor | — |
| AppArmor | ✅ | — | — |
| Auditd | ✅ | — | — |
| ServerTokens | ✅ | — | — |
| Trust proxy | ✅ | — | — |
| SSL cert | — | — | ✅ Let's Encrypt |
