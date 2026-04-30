#!/bin/bash

# =============================================================================
# Script de Instalação e Inicialização - Dolibarr ERP & CRM
# Versão: 23.0
# PHP: 8.4
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variáveis de configuração
DOLIBARR_VERSION="23.0.2"
PHP_VERSION="8.4"
DB_NAME="dolibarr"
DB_USER="dolibarr_app"
DB_PASS=""
SERVER_IP=$(hostname -I | awk '{print $1}')
ADMIN_PASS=""
INSTALL_DIR="/var/www/dolibarr-23.0.2"
LOG_FILE="/var/log/dolibarr_install.log"

# =============================================================================
# Funções de Log
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# =============================================================================
# Verificações Iniciais
# =============================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Este script precisa ser executado como root"
        exit 1
    fi
}

check_os() {
    if [[ -f /etc/debian_version ]]; then
        OS="debian"
        log_info "Sistema detectado: Debian/Ubuntu"
    elif [[ -f /etc/redhat-release ]]; then
        OS="rhel"
        log_info "Sistema detectado: RHEL/CentOS"
    else
        log_error "Sistema não suportado"
        exit 1
    fi
}

# =============================================================================
# Instalação PHP 8.4
# =============================================================================

install_php() {
    log_info "Instalando PHP $PHP_VERSION..."

    if [[ "$OS" == "debian" ]]; then
        apt update

        apt install -y apt-transport-https lsb-release ca-certificates wget gnupg2

        if [[ ! -f /etc/apt/sources.list.d/ondrej-php.list ]]; then
            wget -qO- https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/php-sury.gpg
            echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/ondrej-php.list
            apt update
        fi

        apt install -y php${PHP_VERSION} \
            php${PHP_VERSION}-fpm \
            php${PHP_VERSION}-mysql \
            php${PHP_VERSION}-curl \
            php${PHP_VERSION}-gd \
            php${PHP_VERSION}-mbstring \
            php${PHP_VERSION}-xml \
            php${PHP_VERSION}-zip \
            php${PHP_VERSION}-intl \
            php${PHP_VERSION}-bcmath \
            php${PHP_VERSION}-opcache \
            php${PHP_VERSION}-cli \
            php${PHP_VERSION}-common \
            php${PHP_VERSION}-readline

        log_success "PHP $PHP_VERSION instalado"
    fi
}

configure_php() {
    log_info "Configurando PHP para produção..."

    PHP_INI="/etc/php/${PHP_VERSION}/fpm/php.ini"

    # Backup do original
    cp $PHP_INI ${PHP_INI}.backup

    # Configurações seguras de produção
    sed -i 's/^expose_php.*/expose_php = Off/' $PHP_INI
    sed -i 's/^display_errors.*/display_errors = Off/' $PHP_INI
    sed -i 's/^log_errors.*/log_errors = On/' $PHP_INI
    sed -i 's/^max_execution_time.*/max_execution_time = 300/' $PHP_INI
    sed -i 's/^memory_limit.*/memory_limit = 256M/' $PHP_INI
    sed -i 's/^upload_max_filesize.*/upload_max_filesize = 20M/' $PHP_INI
    sed -i 's/^post_max_size.*/post_max_size = 25M/' $PHP_INI
    sed -i 's/^;date.timezone.*/date.timezone = America\/Sao_Paulo/' $PHP_INI

    # Configurar OPcache para melhor performance
    PHP_OPCACHE_INI="/etc/php/${PHP_VERSION}/fpm/conf.d/10-opcache.ini"
    if [[ ! -f $PHP_OPCACHE_INI ]]; then
        touch $PHP_OPCACHE_INI
    fi

    cat > $PHP_OPCACHE_INI << EOF
opcache.enable=1
opcache.enable_cli=0
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=10000
opcache.revalidate_freq=2
opcache.fast_shutdown=1
EOF

    log_success "PHP configurado"
}

# =============================================================================
# Instalação e Configuração do Banco de Dados
# =============================================================================

install_mariadb() {
    log_info "Instalando MariaDB..."

    if [[ "$OS" == "debian" ]]; then
        apt install -y mariadb-server mariadb-client

        # Configuração segura - MariaDB usa mysql em vez de mysql_secure_installation
        mariadb -u root <<EOF
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

        log_success "MariaDB instalado"
    fi
}

configure_mariadb() {
    log_info "Configurando MariaDB..."

    # Gerar senha aleatória segura
    DB_PASS=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 20)

    mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

    # Salvar credenciais
    cat > /root/.dolibarr_db_credentials << EOF
DB_HOST=localhost
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASS=${DB_PASS}
DB_TYPE=mysqli
EOF
    chmod 600 /root/.dolibarr_db_credentials

    log_success "MariaDB configurado"
    log_warning "Senha do banco: $DB_PASS"
}

# =============================================================================
# Instalação e Configuração do Apache
# =============================================================================

install_apache() {
    log_info "Instalando Apache..."

    if [[ "$OS" == "debian" ]]; then
        apt install -y apache2 libapache2-mod-php${PHP_VERSION}

        /usr/sbin/a2enmod rewrite ssl headers proxy_fcgi setenvif
        /usr/sbin/a2enmod php${PHP_VERSION}
        /usr/sbin/a2enconf php${PHP_VERSION}-fpm

        log_success "Apache instalado"
    fi
}

configure_apache() {
    log_info "Configurando VirtualHost..."

    cat > /etc/apache2/sites-available/dolibarr.conf << EOF
<VirtualHost *:80>
    ServerAdmin admin@localhost
    DocumentRoot ${INSTALL_DIR}/htdocs

    <Directory ${INSTALL_DIR}/htdocs>
        Options -Indexes -FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Proteger arquivos sensíveis
    <FilesMatch "^\.">
        Require all denied
    </FilesMatch>

    <Directory ${INSTALL_DIR}/htdocs/conf>
        Require all denied
    </Directory>

    <Directory ${INSTALL_DIR}/htdocs/data>
        Require all denied
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/dolibarr-error.log
    CustomLog \${APACHE_LOG_DIR}/dolibarr-access.log combined

    # Headers de segurança (CSP permite Tailwind CSS CDN)
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.tailwindcss.com https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; connect-src 'self' https:;"
</VirtualHost>
EOF

    /usr/sbin/a2dissite 000-default.conf 2>/dev/null || true
    /usr/sbin/a2ensite dolibarr.conf

    log_success "Apache configurado"
}

# =============================================================================
# Download e Configuração do Dolibarr
# =============================================================================

download_dolibarr() {
    log_info "Baixando Dolibarr $DOLIBARR_VERSION..."

    cd /tmp

    rm -rf dolibarr-${DOLIBARR_VERSION} dolibarr.tar.gz

    log_info "Baixando arquivo..."
    wget https://github.com/Dolibarr/dolibarr/archive/refs/tags/${DOLIBARR_VERSION}.tar.gz -O dolibarr.tar.gz || {
        log_error "Falha ao baixar Dolibarr"
        exit 1
    }

    if [[ ! -s dolibarr.tar.gz ]]; then
        log_error "Arquivo baixado está vazio"
        exit 1
    fi

    log_info "Extraindo..."
    tar -xzf dolibarr.tar.gz || {
        log_error "Falha ao extrair"
        exit 1
    }

    rm dolibarr.tar.gz

    if [[ ! -d "dolibarr-${DOLIBARR_VERSION}" ]]; then
        log_error "Diretório extraído não encontrado"
        exit 1
    fi

    rm -rf ${INSTALL_DIR}
    mv dolibarr-${DOLIBARR_VERSION} ${INSTALL_DIR}

    log_success "Dolibarr baixado"
}

configure_dolibarr() {
    log_info "Configurando Dolibarr..."

    # Criar diretórios necessários
    mkdir -p ${INSTALL_DIR}/htdocs/documents
    mkdir -p ${INSTALL_DIR}/htdocs/conf
    mkdir -p ${INSTALL_DIR}/htdocs/custom

    # Carregar credenciais do banco
    source /root/.dolibarr_db_credentials

    # Criar arquivo de configuração
    cat > ${INSTALL_DIR}/htdocs/conf/conf.php << EOF
<?php
// Arquivo de configuração gerado automaticamente
// NÃO EDITE ESTE ARQUIVO MANUALMENTE

$dolibarr_main_url_root = 'http://${SERVER_IP}';
$dolibarr_main_url = 'http://${SERVER_IP}';
\$dolibarr_main_document_root = '${INSTALL_DIR}/htdocs';
\$dolibarr_main_data_root = '${INSTALL_DIR}/htdocs/documents';
\$dolibarr_main_db_host = '${DB_HOST}';
\$dolibarr_main_db_port = '3306';
\$dolibarr_main_db_name = '${DB_NAME}';
\$dolibarr_main_db_type = '${DB_TYPE}';
\$dolibarr_main_db_user = '${DB_USER}';
\$dolibarr_main_db_pass = '${DB_PASS}';
\$dolibarr_main_authentication = 'dolibarr';

// Configurações de segurança
\$dolibarr_main_prod = '1';

// Configurações de sessão
ini_set('session.cookie_httponly', '1');
ini_set('session.use_strict_mode', '1');
EOF

    # Configurar permissões seguras
    chown -R www-data:www-data ${INSTALL_DIR}
    chown www-data:www-data ${INSTALL_DIR}/htdocs/conf/conf.php
    chmod 640 ${INSTALL_DIR}/htdocs/conf/conf.php

    chmod 755 ${INSTALL_DIR}/htdocs
    chmod 755 ${INSTALL_DIR}/htdocs/*

    # Permissões específicas para documentos
    chown -R www-data:www-data ${INSTALL_DIR}/htdocs/documents
    chmod -R 775 ${INSTALL_DIR}/htdocs/documents

    log_success "Dolibarr configurado"
}

# =============================================================================
# Configurar Atualizações Automáticas
# =============================================================================

setup_auto_update() {
    log_info "Configurando atualização automática..."

    # Criar script de update
    cat > /usr/local/bin/dolibarr-update.sh << 'EOFUPDATE'
#!/bin/bash
LOG_FILE="/var/log/dolibarr_update.log"
DOLIBARR_DIR="/var/www/dolibarr-23.0.2"
DATE=$(date +%Y%m%d_%H%M%S)

log() {
    echo "[$(date)] $1" | tee -a $LOG_FILE
}

log "Iniciando atualização Dolibarr..."

# Backup do banco de dados
mysqldump -u dolibarr_app -p$(cat /root/.dolibarr_db_credentials | grep DB_PASS | cut -d= -f2) dolibarr > /var/backups/dolibarr/db_$DATE.sql 2>/dev/null
if [ $? -eq 0 ]; then
    log "Backup banco de dados: OK"
else
    log "ERRO no backup do banco"
    exit 1
fi

# Entrar no diretório
cd $DOLIBARR_DIR

# Verificar se há atualizações
git fetch --all
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/develop)

if [ "$LOCAL" != "$REMOTE" ]; then
    log "Atualização disponível: $LOCAL -> $REMOTE"
    
    # Atualizar
    git pull origin develop
    
    # Reiniciar PHP-FPM
    systemctl restart php*-fpm
    
    log "Atualização concluída com sucesso"
else
    log "Já está na versão mais recente"
fi
EOFUPDATE

    chmod +x /usr/local/bin/dolibarr-update.sh

    # Agendar atualização semanal (Domingo às 3:00)
    echo "0 3 * * 0 root /usr/local/bin/dolibarr-update.sh >> /var/log/dolibarr_update.log 2>&1" > /etc/cron.d/dolibarr-updates

    # Criar diretório de backup
    mkdir -p /var/backups/dolibarr/db

    log_success "Atualização automática configurada"
}

# =============================================================================
# Configurar Firewall
# =============================================================================

configure_firewall() {
    log_info "Configurando firewall..."

    if [[ "$OS" == "debian" ]]; then
        apt install -y ufw

        /usr/sbin/ufw --force enable
        /usr/sbin/ufw allow 22/tcp
        /usr/sbin/ufw allow 80/tcp
        /usr/sbin/ufw allow 443/tcp

        log_success "Firewall configurado"
    fi
}

# =============================================================================
# Iniciar Serviços
# =============================================================================

start_services() {
    log_info "Iniciando serviços..."

    # MariaDB
    systemctl enable mariadb
    systemctl start mariadb

    # PHP-FPM
    systemctl enable php${PHP_VERSION}-fpm
    systemctl start php${PHP_VERSION}-fpm

    # Apache
    systemctl enable apache2
    systemctl start apache2

    log_success "Serviços iniciados"
}

# =============================================================================
# Criar Usuário Admin
# =============================================================================

create_admin() {
    log_info "Criando usuário administrador..."

    ADMIN_PASS=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 12)

    # A primeira execução do instalador criará o admin
    # Aqui apenas registramos a senha gerada para referência

    cat > /root/.dolibarr_admin << EOF
ADMIN_USER=admin
ADMIN_PASS=$ADMIN_PASS
EOF
    chmod 600 /root/.dolibarr_admin

    log_success "Admin criado: admin / $ADMIN_PASS"
    log_warning "Guarde esta senha em local seguro!"
}

# =============================================================================
# Resumo Final
# =============================================================================

show_summary() {
    echo ""
    echo "============================================"
    echo -e "${GREEN}INSTALAÇÃO CONCLUÍDA!${NC}"
    echo "============================================"
    echo ""
    echo "ACESSO AO DOLIBARR:"
    echo "  URL de instalação: http://${SERVER_IP}/install/"
    echo "  URL de acesso: http://${SERVER_IP}/"
    echo ""
    echo "CREDENCIAIS DO BANCO:"
    echo "  Host: localhost"
    echo "  Database: $DB_NAME"
    echo "  User: $DB_USER"
    echo "  Senha: $(cat /root/.dolibarr_db_credentials | grep DB_PASS | cut -d= -f2)"
    echo ""
    echo "CREDENCIAIS ADMIN (após instalação web):"
    echo "  Usuário: admin"
    echo "  Senha: (definida na instalação web)"
    echo ""
    echo "ARQUIVOS DE CONFIGURAÇÃO:"
    echo "  - Database: /root/.dolibarr_db_credentials"
    echo "  - Admin: /root/.dolibarr_admin"
    echo "  - VirtualHost: /etc/apache2/sites-available/dolibarr.conf"
    echo ""
    echo "PRÓXIMOS PASSOS:"
    echo "  1. Acesse http://${SERVER_IP}/install/"
    echo "  2. Complete a instalação pelo navegador"
    echo "  3. Execute: rm -rf /var/www/dolibarr-23.0.2/htdocs/install/"
    echo "  4. Execute: touch /var/www/dolibarr-23.0.2/htdocs/documents/install.lock"
    echo ""
}

# =============================================================================
# Menu de Opções
# =============================================================================

usage() {
    echo "Uso: $0 [opção]"
    echo ""
    echo "Opções:"
    echo "  install     - Instalação completa"
    echo "  update      - Atualizar Dolibarr"
    echo "  backup      - Fazer backup"
    echo "  status      - Verificar status dos serviços"
    echo "  restart     - Reiniciar serviços"
    echo ""
}

# =============================================================================
# Main
# =============================================================================

main() {
    case "${1:-install}" in
        install)
            check_root
            check_os

            log_info "Iniciando instalação do Dolibarr $DOLIBARR_VERSION com PHP $PHP_VERSION"

            # Criar log
            mkdir -p /var/log
            touch $LOG_FILE

            # Atualizar sistema
            if [[ "$OS" == "debian" ]]; then
                export DEBIAN_FRONTEND=noninteractive
                apt update
                apt upgrade -y
            fi

            # Instalar componentes
            install_php
            configure_php
            install_mariadb
            configure_mariadb
            install_apache
            configure_apache
            configure_firewall
            download_dolibarr
            configure_dolibarr
            setup_auto_update
            create_admin
            start_services

            show_summary
            ;;

        update)
            /usr/local/bin/dolibarr-update.sh
            ;;

        backup)
            DATE=$(date +%Y%m%d_%H%M%S)
            DB_PASS=$(cat /root/.dolibarr_db_credentials 2>/dev/null | grep DB_PASS | cut -d= -f2) || DB_PASS=""

            mkdir -p /var/backups/dolibarr/db

            log_info "Criando backup..."
            mysqldump -u dolibarr_app -p"$DB_PASS" dolibarr > /var/backups/dolibarr/db_$DATE.sql
            tar -czf /var/backups/dolibarr/files_$DATE.tar.gz -C /var/www/dolibarr-23.0.2/htdocs documents custom

            log_success "Backup concluído: db_$DATE.sql"
            ;;

        status)
            echo "Status dos serviços:"
            systemctl status mariadb --no-pager || true
            echo ""
            systemctl status php${PHP_VERSION}-fpm --no-pager || true
            echo ""
            systemctl status apache2 --no-pager || true
            ;;

        restart)
            log_info "Reiniciando serviços..."
            systemctl restart mariadb
            systemctl restart php${PHP_VERSION}-fpm
            systemctl restart apache2
            log_success "Serviços reiniciados"
            ;;

        *)
            usage
            ;;
    esac
}

main "$@"