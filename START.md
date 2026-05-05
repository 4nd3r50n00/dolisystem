# Guia de Inicialização - Dolibarr ERP & CRM

**Versão:** 23.0.2 | **PHP:** 8.4 | **Banco:** MariaDB

---

## 1. Requisitos do Sistema

### 1.1 Software Necessário

| Componente | Versão Mínima | Recomendado |
|------------|---------------|-------------|
| PHP | 8.1+ | **8.4** |
| MariaDB | 10.4+ | **11.8+** |
| Apache | 2.4+ | 2.4+ |
| Extensões PHP | curl, gd, mbstring, mysqli, xml, zip, intl, bcmath | todas |

### 1.2 Verificar Instalação

```bash
php -v           # PHP 8.4.x
mysql --version  # MariaDB 10.4+
apache2 -v       # Apache 2.4.x
```

---

## 2. Instalação Automática (Recomendada)

### 2.1 Executar Script de Instalação

```bash
cd /root
sudo ./startup.sh install
```

O script irá:
- Instalar PHP 8.4 com módulos de segurança
- Instalar e configurar MariaDB
- Configurar Apache com headers de segurança
- Baixar Dolibarr 23.0.0 para /var/www/dolibarr-23.0.2
- Configurar permissões seguras
- Configurar firewall (UFW)
- Configurar atualização automática semanal

### 2.2 Finalizar via Navegador

1. Abra: `http://localhost/install/`
2. Siga os passos do instalador web
3. Anote a senha do admin

### 2.3 Limpeza Pós-Instalação

```bash
# Remover diretório de instalação
sudo rm -rf /var/www/dolibarr-23.0.2/htdocs/install/

# Criar arquivo de segurança install.lock
sudo touch /var/www/dolibarr-23.0.2/htdocs/documents/install.lock
sudo chown www-data:www-data /var/www/dolibarr-23.0.2/htdocs/documents/install.lock
sudo chmod 644 /var/www/dolibarr-23.0.2/htdocs/documents/install.lock

# Testar acesso
# http://localhost/
```

---

## 3. Instalação Manual (Passo a Passo)

### 3.1 Instalar Dependências (Debian 12/13)

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# PHP 8.4 - Adicionar repositório Sury
sudo apt install -y apt-transport-https lsb-release ca-certificates wget gnupg2
wget -qO- https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/php-sury.gpg
echo "deb https://packages.sury.org/php/ trixie main" | tee /etc/apt/sources.list.d/ondrej-php.list
sudo apt update
sudo apt install -y php8.4 php8.4-fpm php8.4-mysql php8.4-curl php8.4-gd \
    php8.4-mbstring php8.4-xml php8.4-zip php8.4-intl php8.4-bcmath \
    php8.4-opcache php8.4-cli

# MariaDB
sudo apt install -y mariadb-server mariadb-client

# Apache
sudo apt install -y apache2 libapache2-mod-php8.4

# Firewall
sudo apt install -y ufw
sudo ufw --force enable
sudo ufw allow 22/tcp 80/tcp 443/tcp
```

### 3.2 Configurar PHP 8.4

```bash
# Arquivo de configuração
PHP_INI=/etc/php/8.4/fpm/php.ini

# Backup
sudo cp $PHP_INI ${PHP_INI}.backup

# Aplicar configurações seguras
sudo sed -i 's/^expose_php.*/expose_php = Off/' $PHP_INI
sudo sed -i 's/^display_errors.*/display_errors = Off/' $PHP_INI
sudo sed -i 's/^max_execution_time.*/max_execution_time = 300/' $PHP_INI
sudo sed -i 's/^memory_limit.*/memory_limit = 256M/' $PHP_INI
sudo sed -i 's/^upload_max_filesize.*/upload_max_filesize = 20M/' $PHP_INI
sudo sed -i 's/^;date.timezone.*/date.timezone = America\/Sao_Paulo/' $PHP_INI
```

### 3.3 Configurar MariaDB

```bash
# Iniciar serviço
sudo systemctl enable mariadb
sudo systemctl start mariadb

# Instalação segura
sudo mariadb -u root <<EOF
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

# Criar banco e usuário
sudo mariadb -u root <<EOF
CREATE DATABASE dolibarr CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'dolibarr_app'@'localhost' IDENTIFIED BY 'SenhaForte123!';
GRANT ALL PRIVILEGES ON dolibarr.* TO 'dolibarr_app'@'localhost';
FLUSH PRIVILEGES;
EOF
```

### 3.4 Baixar Dolibarr

```bash
DOLIBARR_DIR="/var/www/dolibarr-23.0.2"
DOLIBARR_VERSION="23.0.0"

# Baixar
cd /tmp
wget https://github.com/Dolibarr/dolibarr/archive/refs/tags/${DOLIBARR_VERSION}.tar.gz
tar -xzf ${DOLIBARR_VERSION}.tar.gz
rm ${DOLIBARR_VERSION}.tar.gz

# Mover
sudo rm -rf $DOLIBARR_DIR
sudo mv dolibarr-${DOLIBARR_VERSION} $DOLIBARR_DIR

# Permissões
sudo chown -R www-data:www-data $DOLIBARR_DIR
```

### 3.5 Configurar Apache

```bash
# Criar VirtualHost
sudo cat > /etc/apache2/sites-available/dolibarr.conf <<EOF
<VirtualHost *:80>
    ServerAdmin admin@localhost
    DocumentRoot ${DOLIBARR_DIR}/htdocs

    <Directory ${DOLIBARR_DIR}/htdocs>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    <Directory ${DOLIBARR_DIR}/htdocs/conf>
        Require all denied
    </Directory>

    <Directory ${DOLIBARR_DIR}/htdocs/data>
        Require all denied
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/dolibarr-error.log
    CustomLog \${APACHE_LOG_DIR}/dolibarr-access.log combined

    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.tailwindcss.com https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; connect-src 'self' https:;"
</VirtualHost>
EOF

# Ativar site
sudo a2dissite 000-default.conf
sudo a2ensite dolibarr.conf
sudo a2enmod rewrite headers

# Iniciar Apache
sudo systemctl enable apache2
sudo systemctl restart apache2
```

### 3.6 Finalizar Instalação

Acesse: `http://localhost/install/`

Após instalação:
```bash
sudo rm -rf ${DOLIBARR_DIR}/htdocs/install/
```

---

## 4. Comandos de Gestão

### 4.1 Script de Gestão

```bash
# Ver status
sudo ./startup.sh status

# Reiniciar serviços
sudo ./startup.sh restart

# Atualizar (download + backup automático)
sudo ./startup.sh update

# Backup manual
sudo ./startup.sh backup
```

### 4.2 Comandos Manuais

```bash
# Status serviços
sudo systemctl status mariadb
sudo systemctl status apache2
sudo systemctl status php8.4-fpm

# Reiniciar
sudo systemctl restart mariadb apache2 php8.4-fpm

# Logs
tail -f /var/log/apache2/dolibarr-error.log
tail -f /var/log/mysql/error.log
```

---

## 5. Atualizações de Segurança

### 5.1 Atualização Automática

O script configura atualização semanal automática:
- Backup automático do banco
- Verificação de novas versões
- Reinício automático dos serviços

Arquivo cron: `/etc/cron.d/dolibarr-updates`

### 5.2 Atualização Manual

```bash
# Verificar atualizações
cd /var/www/dolibarr-23.0.2
git fetch --all

# Atualizar (somente se necessário)
sudo ./startup.sh update
```

---

## 6. Segurança

### 6.1 Práticas Recomendadas

1. **Sempre use HTTPS em produção**
2. **Mantenha o PHP atualizado** (versão atual: 8.4)
3. **Mantenha o MariaDB atualizado**
4. **Remova diretórios de instalação** após uso
5. **Use senhas fortes** (mínimo 12 caracteres)
6. **Configure firewall**

### 6.2 Configurações de Segurança Incluídas

- `expose_php = Off`
- `display_errors = Off`
- Headers de segurança (X-Frame-Options, CSP, etc.)
- Arquivos sensíveis protegidos (.htaccess)
- Permissões restritivas em conf e data
- `session.cookie_httponly = 1`

---

## 7. Troubleshooting

### 7.1 Problemas Comuns

| Problema | Solução |
|----------|---------|
| Página branca | Ver logs: `tail /var/log/apache2/error.log` |
| Erro conexão BD | Verificar credenciais em `conf/conf.php` |
| Permissão negada | `sudo chown -R www-data:www-data /var/www/dolibarr-23.0.2` |
| PHP não reconhecido | Verificar versão: `php -v` |
| Erro 404 no install | Verificar DocumentRoot no Apache |

### 7.2 Verificar Instalação

```bash
# Testar PHP
php -v
php -m | grep -E "mysqli|curl|gd|mbstring|zip"

# Testar banco
mariadb -u dolibarr_app -p -e "SHOW DATABASES;"

# Testar Apache
curl -I http://localhost/
```

---

## 8. Estrutura de Arquivos

```
/var/www/dolibarr-23.0.2/
├── htdocs/           # Aplicação web
│   ├── conf/         # Configurações (protegido)
│   ├── documents/    # Arquivos uploadados
│   ├── custom/       # Módulos personalizados
│   └── install/     # Instalador (remover após uso)
/var/backups/dolibarr/ # Backups automáticos
/etc/apache2/sites-available/dolibarr.conf
/var/log/dolibarr_*.log
```

---

Desenvolvido por Dolibarr Foundation | Licença GPL-3+

---

## 9. Temas Customizados

### 9.1 Migrar Tema Customizado

Se você tem um tema customizado de outra instalação, siga os passos:

```bash
# Copiar a pasta do tema para a nova instalação
cp -r /caminho/do/tema_customizado /var/www/dolibarr-23.0.2/htdocs/theme/

# Corrigir permissões
sudo chown -R www-data:www-data /var/www/dolibarr-23.0.2/htdocs/theme/nome_do_tema
```

### 9.2 Ativar Tema

1. Acesse: `http://localhost/admin/`
2. Vá em **Configuração > Aparência > Skin e Cores**
3. Selecione o tema customizado
4. Salve

---

## 10. Correções de Banco de Dados

Se houver erro de tabela em falta (ex: `llx_categorie_propal doesn't exist`), execute:

```bash
sudo mysql -u root dolibarr << 'EOF'
-- Tabelas de Categorização que podem estar em falta

-- llx_categorie_propal
CREATE TABLE IF NOT EXISTS llx_categorie_propal (
    rowid int AUTO_INCREMENT PRIMARY KEY,
    fk_categorie int NOT NULL,
    fk_propal int NOT NULL,
    entity int NOT NULL DEFAULT 1,
    import_key varchar(14) DEFAULT NULL,
    UNIQUE KEY uk_categorie_propal (fk_categorie, fk_propal, entity),
    KEY idx_categorie_propal_fk_categorie (fk_categorie),
    KEY idx_categorie_propal_fk_propal (fk_propal)
) ENGINE=innodb DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- llx_categorie_societe
CREATE TABLE IF NOT EXISTS llx_categorie_societe (
    rowid int AUTO_INCREMENT PRIMARY KEY,
    fk_categorie int NOT NULL,
    fk_societe int NOT NULL,
    entity int NOT NULL DEFAULT 1,
    import_key varchar(14) DEFAULT NULL,
    UNIQUE KEY uk_categorie_societe (fk_categorie, fk_societe, entity),
    KEY idx_categorie_societe_fk_categorie (fk_categorie),
    KEY idx_categorie_societe_fk_societe (fk_societe)
) ENGINE=innodb DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- llx_categorie_intervention (ficheinter)
CREATE TABLE IF NOT EXISTS llx_categorie_intervention (
    rowid int AUTO_INCREMENT PRIMARY KEY,
    fk_categorie int NOT NULL,
    fk_intervention int NOT NULL,
    entity int NOT NULL DEFAULT 1,
    import_key varchar(14) DEFAULT NULL,
    UNIQUE KEY uk_categorie_intervention (fk_categorie, fk_intervention, entity)
) ENGINE=innodb DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
EOF
```

Liste todas as tabelas de categorização existentes:
```bash
sudo mysql -u root dolibarr -e "SHOW TABLES LIKE 'llx_categorie_%';"
```

---

## 11. Migração de Customizações

### 11.1 Executar Script de Migração

Após a instalação do Dolibarr, execute o script de migração para aplicar as customizações:

```bash
cd /root/dolisystem
sudo ./migrate_customizations.sh
```

O scriptirá:
- Copiar arquivos customizados da pasta `!Changes`
- Configurar Apache com CSP para Tailwind CSS
- Ativar tema modern_dark
- Configurar modelos PDF master
- Aplicar configurações no banco de dados

### 11.2 Arquivos Copiados

| # | Arquivo | Descrição |
|---|--------|-----------|
| 1 | `compta/paiement.php` | Processamento de pagamentos |
| 2 | `core/ajax/onlineSign.php` | Assinatura online |
| 3 | `core/lib/company.lib.php` | Biblioteca de empresa |
| 4 | `core/modules/commande/doc/pdf_master_order.modules.php` | Modelo PDF pedidos |
| 5 | `core/modules/facture/doc/pdf_master_bill.modules.php` | Modelo PDF faturas |
| 6 | `core/modules/fichinter/doc/pdf_master_inter.modules.php` | Modelo PDF intervenções |
| 7 | `core/modules/propale/doc/pdf_master_propal.modules.php` | Modelo PDF propostas |
| 8 | `expedition/card.php` | Card de expedição |
| 9 | `langs/en_US/propal.lang` | Tradução propostas inglês |
| 10 | `langs/pt_BR/*.lang` | Traduções português (70 arquivos) |
| 11 | `public/onlinesign/newonlinesign.php` | Interface de assinatura online |
| 12 | `theme/modern_dark/` | Tema dark moderno |
| 13 | `theme/custom.css.php` | CSS customizado |
| 14 | `core/tpl/login.tpl.php` | Template de login |
| 15 | `debug_db_raw.php` | Ferramenta debug DB |
| 16 | `debug_multicurrency.php` | Ferramenta debug moeda |

### 11.3 Configurações Aplicadas

#### Tema e Visual
| Configuração | Valor | Descrição |
|--------------|-------|----------|
| `MAIN_THEME` | modern_dark | Tema padrão do sistema |
| `THEME_DARKMODEENABLED` | 2 | Modo escuro sempre ativado |
| `THEME_TOPMENU_DISABLE_IMAGE` | 3 | Menu com ícones + texto |

#### Modelos PDF
| Tipo | Modelo | Descrição |
|------|--------|--------|
| Pedidos | master_order | Master Order |
| Faturas | master_bill | Master Bill |
| Propostas | master_propal | Master Propal |
| Intervenções | master_inter | Master Inter |

O script Remove outros modelos PDF da mesma categoria, mantendo apenas o master.

#### Apache
- CSP atualizada para permitir Tailwind CSS CDN
- Headers de segurança mantidos

### 11.4 Estrutura da Pasta !Changes

```
!Changes/
└── htdocs/
    ├── compta/paiement.php
    ├── core/
    │   ├── ajax/onlineSign.php
    │   ├── lib/company.lib.php
    │   ├── modules/
    │   │   ├── commande/doc/pdf_master_order.modules.php
    │   │   ├── facture/doc/pdf_master_bill.modules.php
    │   │   ├── fichinter/doc/pdf_master_inter.modules.php
    │   │   └── propale/doc/pdf_master_propal.modules.php
    │   └── tpl/login.tpl.php
    ├── expedition/card.php
    ├── langs/
    │   ├── en_US/propal.lang
    │   └── pt_BR/*.lang (70 arquivos)
    ├── public/onlinesign/newonlinesign.php
    ├── theme/
    │   ├── modern_dark/
    │   └── custom.css.php
    ├── debug_db_raw.php
    └── debug_multicurrency.php
```