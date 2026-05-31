# Passo a Passo — Dolibarr ERP & CRM

**Versão:** 23.0.2 | **PHP:** 8.4 | **Banco:** MariaDB 11.8+
**Servidor:** 172.16.0.201 | **Domínio:** https://erp.anderson00.cloudns.ch
**Proxy reverso:** 172.16.0.96 | **Porta Apache:** 87

---

## 1. Instalação Automática

### 1.1 Executar autoinstall.sh

```bash
cd /home/erpuser/dolisystem
./autoinstall.sh install
```

O script oferece menu interativo com dois modos de banco:

| Modo | Descrição |
|------|-----------|
| **Local** | MariaDB no próprio servidor — cria banco e usuário automaticamente |
| **Remoto** | Banco em servidor separado — escolhe criar novo ou conectar a existente |

O que o script faz:
- Instala PHP 8.4 + módulos (apenas FPM, sem mod-php)
- Instala e configura MariaDB (modo local) ou testa conectividade (modo remoto)
- Configura Apache na porta **87** com handler **proxy_fcgi** (socket FPM), **RemoteIP** (TrustedProxy 172.16.0.96)
- Baixa Dolibarr 23.0.2 para `/var/www/dolibarr-23.0.2`
- Configura timezone `America/Sao_Paulo` (OS + php.ini)
- Cria pool FPM **dolibarr** rodando como usuário **erpuser**
- Configura nftables (SSH restrito a IP admin, porta 87 restrita ao proxy)
- Gera `.dolibarr_db_credentials` com dados de conexão

### 1.2 Finalizar via Navegador

1. Acesse: `https://erp.anderson00.cloudns.ch/install/`
2. Siga o instalador web
3. Se banco remoto já existe, escolha **"Conectar a banco existente"** — o instalador não destrói dados
4. Anote a senha do admin

### 1.3 Pós-Instalação

```bash
rm -rf /var/www/dolibarr-23.0.2/htdocs/install/
touch /var/www/dolibarr-23.0.2/htdocs/documents/install.lock
```

### 1.4 Hardening de Segurança

```bash
cd /home/erpuser/dolisystem
./security.sh
```

O script pergunta interativamente as variáveis de rede. Para execução silenciosa:
```bash
./security.sh --domain https://meudominio.com --nginx-ip 10.0.0.1 --desktop-ip 203.0.113.50
```

O que o script faz:
- Pool FPM **dolibarr** (user erpuser) com open_basedir, disable_functions, session hardening
- Apache na porta **87**, handler **proxy_fcgi**, **RemoteIP**, sem security headers
- **nftables** (SSH + porta 87 restritos)
- **fail2ban** com jails apache-auth + apache-dolibarr-login
- Hardening de permissões (root:www-data, erpuser:erpuser, root:erpuser)
- Remove arquivos de debug
- Remove `libapache2-mod-php` (desnecessário)

> **Idempotente:** Pode rodar quantas vezes quiser. Primeira execução é interativa, as seguintes usam cache em `.security_config`.

---

## 2. Customização (ThemePack + Anti-Fingerprinting)

### 2.1 Executar custom.sh

```bash
cd /home/erpuser/dolisystem
./custom.sh
```

> **Importante:** `custom.sh` só deve rodar DEPOIS do `install.php`. Se rodar antes, o SQL é pulado automaticamente (SKIP_SQL guard), mas os arquivos são copiados — rode novamente após o install.

O script faz:
- Copia ~547 arquivos do ThemePack para a instalação Dolibarr
- Aplica anti-fingerprinting (remove referências ao Dolibarr no HTML)
- Configura tema `modern_dark` como padrão
- Ativa modelos PDF master
- Configura PDF: logo 13mm altura, molduras com cantos arredondados
- Insere configurações no banco (via `MYSQL_PWD`, nunca `-p` na CLI)
- Se banco remoto detectado, instala temporariamente `default-mysql-client`, executa SQL, remove o cliente
- Aplica hardening de permissões: `root:www-data` (arquivos), `erpuser:erpuser` (documents), `root:erpuser` (conf.php)
- Reescreve VirtualHost (porta 87, proxy_fcgi, RemoteIP, sem security headers)
- Reinicia PHP-FPM + Apache no final

### 2.2 O que o Anti-Fingerprinting Remove

| Alvo | Ação |
|------|------|
| Meta author em `main.inc.php` | `Dolibarr Development Team` → `getDolGlobalString('MAIN_APPLICATION_TITLE', '')` |
| "Powered by Dolibarr" | Bloco removido via range sed com `}` como delimitador |
| Comentários JS "Includes JS of Dolibarr" | Comentários removidos (padrão longo primeiro) |
| Favicon padrão | Substituído por pixel transparente |
| Logo fallback | Removido |

### 2.3 Arquivos Copiados (ThemePack)

| Categoria | Arquivos |
|-----------|----------|
| Modelos PDF | `pdf_master_order`, `pdf_master_bill`, `pdf_master_propal`, `pdf_master_inter` |
| Libs PHP | `company.lib.php` (SVG logo), `functions.lib.php` (ícones moeda FA) |
| Templates | `login.tpl.php`, `passwordforgotten.tpl.php` |
| Tema | `modern_dark/` completo, `custom.css.php` |
| Traduções | `pt_BR/*.lang` (70 arquivos), `en_US/propal.lang` |
| Outros | `paiement.php`, `onlineSign.php`, `expedition/card.php` |

### 2.4 Mapeamento Moeda → Ícone FontAwesome

Adicionado em `functions.lib.php`: BRL→dollar-sign, EUR→euro-sign, GBP→pound-sign, RUB→ruble-sign, TRY→lira-sign, JPY→yen-sign, multicurrency→coins.

### 2.5 Configurações Padrão de PDF

| Constante | Valor | Descrição |
|-----------|-------|-----------|
| `MAIN_DOCUMENTS_LOGO_HEIGHT` | `13` (mm) | Altura do logo nos PDFs (padrão Dolibarr: 20mm). Logo 6:1 fica ~80mm largura |
| `MAIN_PDF_FRAME_CORNER_RADIUS` | `1` | Molduras com cantos arredondados (0=quadrado, 1=sutil, 2=médio, 3=pronunciado) |

---

## 3. Ativação de Módulos

```bash
cd /home/erpuser/dolisystem
./activate_modules_v2.sh
```

Ativa módulos Dolibarr via banco de dados (sem interface web).

---

## 4. Comandos de Gestão

```bash
# Gestão via autoinstall.sh
./autoinstall.sh status     # Ver status dos serviços
./autoinstall.sh restart    # Reiniciar Apache + PHP-FPM
./autoinstall.sh backup     # Backup manual do banco
./autoinstall.sh update     # Atualizar (download + backup automático)

# Gestão manual de serviços
systemctl restart apache2         # Apache (porta 87)
systemctl restart php8.4-fpm      # PHP-FPM (pools www + dolibarr)
systemctl restart fail2ban        # fail2ban
/usr/sbin/nft -f /etc/nftables.conf  # Recarregar firewall
```

---

## 5. Servidor de Banco Remoto (Configuração Manual)

Se o modo "Remoto → Criar novo banco" do `autoinstall.sh` não for usado:

```bash
# No servidor DB
mariadb -u root <<EOF
CREATE DATABASE dolibarr CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'dolibarr_app'@'<IP_DO_SERVIDOR_APP>' IDENTIFIED BY 'SenhaForte123!';
GRANT ALL PRIVILEGES ON dolibarr.* TO 'dolibarr_app'@'<IP_DO_SERVIDOR_APP>';
FLUSH PRIVILEGES;
EOF
```

> **Nunca use `'%'` como host do usuário** — sempre o IP específico do servidor App.

---

## 6. Shared Hosting (InfinityFree)

Sem shell — apenas FTP + phpMyAdmin.

| Item | Detalhe |
|------|---------|
| Prefixo DB | `llxhq_` (não `llx_`) |
| SQL | Importar `migrate_customizations_llxhq.sql` no phpMyAdmin |
| ThemePack | Upload via FTP para paths correspondentes |
| Anti-fingerprinting | Aplicar sed **localmente antes do upload** |
| Logo | FTP para `documents/mycompany/logos/` + SQL INSERT para `MAIN_INFO_SOCIETE_LOGO` / `LOGO_SMALL` / `LOGO_MINI` |

---

## 6. Arquitetura da Instalação

### 6.1 Topologia de Rede

```
Internet → nginx (172.16.0.96) [TLS termination]
                ↓ porta 87 (nftables permite só do proxy)
           Apache (172.16.0.201:87)
                ↓ proxy_fcgi (socket)
           PHP-FPM pool dolibarr (user: erpuser)
                ↓
           MariaDB (172.16.0.200:3306)
```

### 6.2 Mapa de Portas

| Porta | Serviço | Restrito a |
|-------|---------|-----------|
| 22/tcp | SSH | 172.16.254.248 |
| 87/tcp | Apache (Dolibarr) | 172.16.0.96 (nginx) |
| 443/tcp | Apache (não usado, nftables bloqueia) | — |
| 3306/tcp | MariaDB | Apenas no servidor DB |

### 6.3 Configuração de Proxy Reverso (nginx em 172.16.0.96)

O nginx deve:
- Terminar TLS (certificado SSL)
- Encaminhar para `http://172.16.0.201:87`
- Adicionar header `X-Forwarded-For` com IP real do cliente
- Configurar HSTS

---

## 7. Segurança (Hardening Aplicado)

### 7.1 Pool FPM Dolibarr

Arquivo: `/etc/php/8.4/fpm/pool.d/dolibarr.conf`

| Diretiva | Valor | Finalidade |
|----------|-------|------------|
| `user/group` | `erpuser` | FPM roda como usuário não-privilegiado |
| `listen` | `/run/php/php8.4-dolibarr.sock` | Socket exclusivo |
| `open_basedir` | `htdocs:documents:/tmp` | Impede file inclusion fora do escopo |
| `disable_functions` | `shell_exec,system,passthru,show_source` | Bloqueia execução de comandos perigosos |
| `allow_url_fopen` | `Off` | Impede SSRF via fopen remoto |
| `session.use_strict_mode` | `1` | Previne session fixation |
| `session.cookie_httponly` | `1` | Cookies JS não acessam sessão |
| `session.cookie_secure` | `1` | Cookies só em HTTPS |
| `session.cookie_samesite` | `Lax` | Protege contra CSRF |

### 7.2 Apache

Arquivo: `/etc/apache2/sites-available/dolibarr.conf`

| Item | Valor |
|------|-------|
| Porta | 87 (`Listen 87` em ports.conf) |
| Handler | `proxy_fcgi` (socket dolibarr) — sem mod-php |
| RemoteIP | `X-Forwarded-For` + TrustedProxy `172.16.0.96` |
| ServerTokens | `Prod` (oculta versão) |
| ServerSignature | `Off` |
| Permissions-Policy | `camera=(), microphone=(), geolocation=(), payment=()` |
| Security headers | Removidos (nginx gerencia) |
| API `/api/` | Restrita a `127.0.0.1 ::1 172.16.0.96` |

### 7.3 Permissões de Arquivos

| Caminho | Proprietário | Permissão |
|---------|-------------|-----------|
| `htdocs/` (arquivos PHP) | `root:www-data` | 644 |
| `htdocs/` (diretórios) | `root:www-data` | 755 |
| `documents/` | `erpuser:erpuser` | 750 (www-data lê via grupo erpuser) |
| `conf/conf.php` | `root:erpuser` | 640 |

### 7.4 Firewall (nftables)

Arquivo: `/etc/nftables.conf`

```bash
# Ver regras ativas
nft list ruleset
```

Regras:
- SSH (22) apenas de `<DESKTOP_IP>`
- Apache (87) apenas de `<NGINX_IP>` (172.16.0.96)
- Todo resto bloqueado com log

### 7.5 fail2ban

Jails ativos:

| Jail | Filter | Log | maxretry | bantime |
|------|--------|-----|----------|---------|
| `apache-auth` | apache-auth | `/var/log/apache2/dolibarr-error.log` | 5 | 1h |
| `apache-dolibarr-login` | apache-dolibarr-login | `/var/log/apache2/dolibarr-error.log` | 5 | 1h |
| `sshd` | sshd | `/var/log/auth.log` | 5 | 1h |

---

## 8. Estrutura de Arquivos

```
/var/www/dolibarr-23.0.2/
├── htdocs/
│   ├── conf/conf.php       # Configurações (root:erpuser 640)
│   ├── documents/          # Uploads (erpuser:erpuser 750)
│   ├── api/                # API (restrita ao proxy)
│   └── theme/modern_dark/  # Tema customizado
/etc/
├── apache2/
│   ├── sites-available/dolibarr.conf  # VHost porta 87
│   ├── ports.conf                     # Listen 87
│   └── conf-enabled/security.conf     # ServerTokens Prod
├── php/8.4/fpm/pool.d/dolibarr.conf   # Pool FPM dedicado
├── nftables.conf                      # Firewall restritivo
└── fail2ban/
    ├── jail.local                     # Jails ativos
    └── filter.d/apache-dolibarr-login.conf
/home/erpuser/dolisystem/
├── autoinstall.sh          # Instalação
├── security.sh             # Hardening de segurança (pós-instalação)
├── custom.sh               # Customização + anti-fingerprinting
├── activate_modules_v2.sh  # Ativação de módulos
├── migrate_customizations_llxhq.sql
├── ThemePack/              # Arquivos fonte copiados pelo custom.sh
├── .security_config        # Cache de config do security.sh
├── etc/Steps.md            # Esta documentação
└── docs/CHANGES-2026-05-25.md  # Changelog completo
```

---

## 9. Troubleshooting

| Problema | Solução |
|----------|---------|
| HTTP 500 | `systemctl status php8.4-fpm` + `journalctl -u php8.4-fpm --no-pager \| tail -20` |
| Apache não sobe | `/usr/sbin/apachectl configtest` e `journalctl -u apache2 --no-pager \| tail -20` |
| Banco remoto inacessível | `nc -zv -w5 172.16.0.200 3306` ou `timeout 5 bash -c "echo > /dev/tcp/172.16.0.200/3306"` |
| Página branca | `tail /var/log/apache2/dolibarr-error.log` |
| Permissão negada | `chown -R erpuser:erpuser /var/www/dolibarr-23.0.2/htdocs/documents` |
| Tabela em falta | Verificar se `custom.sh` rodou após `install.php` (SKIP_SQL guard) |
| fail2ban não bane | `fail2ban-client status apache-dolibarr-login` + verificar logpath |
| nftables bloqueando acesso | `nft list ruleset` e verificar IPs permitidos |

### Comandos de Diagnóstico Rápido

```bash
# Ver portas ouvindo
ss -tlnp | grep -E "87|22"

# Ver FPM pools ativos
ps aux | grep "php-fpm"

# Ver regras do firewall
nft list ruleset

# Ver jails fail2ban
fail2ban-client status

# Testar PHP via Apache
curl -I http://localhost:87/
```
