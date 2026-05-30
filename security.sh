#!/bin/bash
#
# security.sh — Hardening de Segurança Pós-Instalação Dolibarr
# Versão: 1.0
# Uso: ./security.sh [--force]
#
# Aplica todas as configurações de segurança:
#   - Pool FPM dedicado (user erpuser)
#   - Apache: porta 87, proxy_fcgi, RemoteIP, sem security headers
#   - nftables: SSH + porta 87 restritos
#   - fail2ban com jails para Apache
#   - Hardening de permissões
#   - Session hardening, disable_functions, open_basedir
#

set -euo pipefail

# =============================================================================
# Configurações
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/.security_config"
BACKUP_DIR="${SCRIPT_DIR}/backups/security_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="${SCRIPT_DIR}/security.log"

DOL_DIR="/var/www/dolibarr-23.0.2"
HTDOCS="${DOL_DIR}/htdocs"
PHP_VERSION="8.4"
FPM_POOL_CONF="/etc/php/${PHP_VERSION}/fpm/pool.d/dolibarr.conf"
APACHE_CONF="/etc/apache2/sites-available/dolibarr.conf"
APACHE_PORTS="/etc/apache2/ports.conf"
APACHE_SECURITY="/etc/apache2/conf-enabled/security.conf"
NFTABLES_CONF="/etc/nftables.conf"
FAIL2BAN_JAIL="/etc/fail2ban/jail.local"
FAIL2BAN_FILTER="/etc/fail2ban/filter.d/apache-dolibarr-login.conf"

# Cores
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

FORCE=0
DOMAIN="https://erp.anderson00.cloudns.ch"
NGINX_IP="172.16.0.96"
APACHE_PORT="87"
DESKTOP_IP=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --force|-f) FORCE=1; shift ;;
        --domain) DOMAIN="$2"; shift 2 ;;
        --nginx-ip) NGINX_IP="$2"; shift 2 ;;
        --desktop-ip) DESKTOP_IP="$2"; shift 2 ;;
        --port) APACHE_PORT="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# =============================================================================
# Funções de Log
# =============================================================================

log_info()  { echo -e "${BLUE}[INFO]${NC} $*" | tee -a "$LOG_FILE"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $*" | tee -a "$LOG_FILE"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}[ERRO]${NC} $*" | tee -a "$LOG_FILE"; exit 1; }

# =============================================================================
# Detect current SSH IP
# =============================================================================

detect_ssh_ip() {
    local ip
    ip=$(echo "$SSH_CLIENT" | awk '{print $1}')
    echo "${ip:-}"
}

# =============================================================================
# Load or collect config
# =============================================================================

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        log_info "Config carregada de ${CONFIG_FILE}"
        return 0
    fi
    return 1
}

save_config() {
    cat > "$CONFIG_FILE" << EOF
DOMAIN="${DOMAIN}"
NGINX_IP="${NGINX_IP}"
DESKTOP_IP="${DESKTOP_IP}"
APACHE_PORT="${APACHE_PORT}"
EOF
    chmod 600 "$CONFIG_FILE"
    log_ok "Config salva em ${CONFIG_FILE}"
}

collect_config() {
    local ssh_ip
    ssh_ip=$(detect_ssh_ip)

    echo ""
    echo "============================================"
    echo "  CONFIGURAÇÃO DE SEGURANÇA"
    echo "============================================"
    echo ""

    read -p "  Domínio do Dolibarr [https://erp.anderson00.cloudns.ch]: " DOMAIN_INPUT
    DOMAIN="${DOMAIN_INPUT:-https://erp.anderson00.cloudns.ch}"

    read -p "  IP do proxy reverso (nginx) [172.16.0.96]: " NGINX_INPUT
    NGINX_IP="${NGINX_INPUT:-172.16.0.96}"

    if [[ -n "$ssh_ip" ]]; then
        read -p "  IP do admin (SSH) [${ssh_ip}]: " DESKTOP_INPUT
        DESKTOP_IP="${DESKTOP_INPUT:-$ssh_ip}"
    else
        read -p "  IP do admin (SSH): " DESKTOP_INPUT
        DESKTOP_IP="${DESKTOP_INPUT}"
    fi

    read -p "  Porta do Apache [87]: " APACHE_INPUT
    APACHE_PORT="${APACHE_INPUT:-87}"

    echo ""
    echo "Confirmando:"
    echo "  Domínio:    ${DOMAIN}"
    echo "  Proxy:      ${NGINX_IP}"
    echo "  SSH admin:  ${DESKTOP_IP}"
    echo "  Porta:      ${APACHE_PORT}"
    echo ""
    read -p "Confirmar? [S/n]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Nn] ]]; then
        log_warn "Reiniciando coleta..."
        collect_config
        return
    fi

    save_config
}

# =============================================================================
# Backup & Rollback
# =============================================================================

do_backup() {
    mkdir -p "$BACKUP_DIR"
    local files=(
        "$FPM_POOL_CONF"
        "$APACHE_CONF"
        "$APACHE_PORTS"
        "$APACHE_SECURITY"
        "$NFTABLES_CONF"
        "$FAIL2BAN_JAIL"
        "$FAIL2BAN_FILTER"
        "${HTDOCS}/conf/conf.php"
    )
    for f in "${files[@]}"; do
        if [[ -f "$f" ]]; then
            cp -a "$f" "${BACKUP_DIR}/" 2>/dev/null || true
        fi
    done
    log_ok "Backup salvo em ${BACKUP_DIR}"
}

rollback() {
    log_warn "Rollback em andamento..."
    if [[ -d "$BACKUP_DIR" ]]; then
        for f in "$BACKUP_DIR"/*; do
            local target
            target=$(basename "$f")
            # Map backup filenames back to original paths
            case "$target" in
                dolibarr.conf)        cp -a "$f" "$APACHE_CONF" ;;
                ports.conf)           cp -a "$f" "$APACHE_PORTS" ;;
                security.conf)        cp -a "$f" "$APACHE_SECURITY" ;;
                nftables.conf)        cp -a "$f" "$NFTABLES_CONF" && /usr/sbin/nft -f "$NFTABLES_CONF" 2>/dev/null || true ;;
                jail.local)           cp -a "$f" "$FAIL2BAN_JAIL" ;;
                apache-dolibarr-login.conf) cp -a "$f" "$FAIL2BAN_FILTER" ;;
                conf.php)             cp -a "$f" "${HTDOCS}/conf/conf.php" ;;
                dolibarr.conf)        cp -a "$f" "$FPM_POOL_CONF" ;;
            esac
        done
        log_ok "Rollback concluído. Reiniciando serviços..."
        systemctl restart php${PHP_VERSION}-fpm 2>/dev/null || true
        systemctl restart apache2 2>/dev/null || true
    fi
    exit 1
}

# =============================================================================
# Validation helpers
# =============================================================================

validate_fpm() {
    log_info "Validando configuração FPM..."
    if ! /usr/sbin/php-fpm${PHP_VERSION} -t 2>&1 | tee -a "$LOG_FILE"; then
        log_error "FPM config inválido. Abortando."
        rollback
    fi
    log_ok "FPM config OK"
}

validate_apache() {
    log_info "Validando configuração Apache..."
    if ! /usr/sbin/apachectl configtest 2>&1 | tee -a "$LOG_FILE"; then
        log_error "Apache config inválido. Abortando."
        rollback
    fi
    log_ok "Apache config OK"
}

restart_services() {
    log_info "Reiniciando serviços..."
    systemctl restart php${PHP_VERSION}-fpm || log_warn "Falha ao reiniciar FPM"
    systemctl restart apache2 || log_warn "Falha ao reiniciar Apache"
    systemctl restart fail2ban 2>/dev/null || log_warn "Falha ao reiniciar fail2ban"
    log_ok "Serviços reiniciados"
}

# =============================================================================
# Health check final
# =============================================================================

health_check() {
    echo ""
    echo "============================================"
    echo "  VERIFICAÇÃO FINAL"
    echo "============================================"
    echo ""

    local ok=0 fail=0

    # Apache port
    if ss -tlnp 2>/dev/null | grep -q ":${APACHE_PORT} "; then
        log_ok "Apache ouvindo na porta ${APACHE_PORT}"
        ((ok++))
    else
        log_error "Apache NÃO está na porta ${APACHE_PORT}"
        ((fail++))
    fi

    # FPM pool
    if ps aux 2>/dev/null | grep -q "php-fpm.*pool dolibarr"; then
        log_ok "Pool FPM dolibarr ativo"
        ((ok++))
    else
        log_error "Pool FPM dolibarr NÃO encontrado"
        ((fail++))
    fi

    # Socket
    if [[ -S "/run/php/php${PHP_VERSION}-dolibarr.sock" ]]; then
        log_ok "Socket dolibarr existe"
        ((ok++))
    else
        log_error "Socket dolibarr NÃO encontrado"
        ((fail++))
    fi

    # nftables
    if /usr/sbin/nft list ruleset 2>/dev/null | grep -q "tcp dport ${APACHE_PORT}"; then
        log_ok "nftables protegendo porta ${APACHE_PORT}"
        ((ok++))
    else
        log_warn "nftables pode não estar configurado para porta ${APACHE_PORT}"
        ((fail++))
    fi

    # fail2ban
    if fail2ban-client status apache-dolibarr-login &>/dev/null; then
        log_ok "fail2ban jail apache-dolibarr-login ativo"
        ((ok++))
    else
        log_warn "fail2ban jail apache-dolibarr-login inativo"
        ((fail++))
    fi

    # HTTP response
    if curl -sI "http://localhost:${APACHE_PORT}/" 2>/dev/null | grep -q "HTTP"; then
        log_ok "Apache responde na porta ${APACHE_PORT}"
        ((ok++))
    else
        log_error "Apache NÃO responde na porta ${APACHE_PORT}"
        ((fail++))
    fi

    # HTTPS redirect
    if curl -sI "http://localhost:${APACHE_PORT}/" 2>/dev/null | grep -q "Location: ${DOMAIN}"; then
        log_ok "Redirect para ${DOMAIN} ativo"
        ((ok++))
    else
        log_warn "Redirect para ${DOMAIN} pode estar incorreto"
        ((fail++))
    fi

    # Server header
    if curl -sI "http://localhost:${APACHE_PORT}/" 2>/dev/null | grep -q "Server: Apache$"; then
        log_ok "ServerTokens Prod (Apache apenas)"
        ((ok++))
    else
        log_warn "ServerTokens pode não estar configurado como Prod"
        ((fail++))
    fi

    echo ""
    echo "  ${GREEN}${ok} OK${NC}, ${RED}${fail} FALHAS${NC}"
    echo ""
}

# =============================================================================
# Step 1: Create FPM pool dolibarr
# =============================================================================

step_fpm_pool() {
    log_info "[1] Criando pool FPM dolibarr..."

    if [[ -f "$FPM_POOL_CONF" && "$FORCE" -eq 0 ]]; then
        log_warn "Pool dolibarr já existe. Use --force para sobrescrever."
        return 0
    fi

    cat > "$FPM_POOL_CONF" << EOF
[dolibarr]
user = erpuser
group = erpuser
listen = /run/php/php${PHP_VERSION}-dolibarr.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660
pm = dynamic
pm.max_children = 10
pm.start_servers = 3
pm.min_spare_servers = 2
pm.max_spare_servers = 5
pm.max_requests = 500

; C3 — Restringir escopo de leitura do PHP (file inclusion)
php_admin_value[open_basedir] = ${HTDOCS}:${HTDOCS}/documents:/tmp

; M5 — Session hardening
php_admin_value[session.use_strict_mode] = 1
php_admin_value[session.cookie_httponly] = 1

; M2 — Cookie secure (HTTPS)
php_admin_value[session.cookie_secure] = 1

; M3 — Cookie samesite
php_admin_value[session.cookie_samesite] = "Lax"

; H7 — Bloquear funções perigosas (exec/popen/proc_open mantidos)
php_admin_value[disable_functions] = shell_exec,system,passthru,show_source

; M6 — Bloquear fopen remoto
php_admin_value[allow_url_fopen] = Off
EOF

    validate_fpm
    log_ok "Pool dolibarr criado"
}

# =============================================================================
# Step 2: Configure Apache
# =============================================================================

step_apache_ports() {
    log_info "[2a] Configurando ports.conf (Listen ${APACHE_PORT})..."

    cat > "$APACHE_PORTS" << EOF
# Gerado por security.sh
Listen ${APACHE_PORT}

<IfModule ssl_module>
	Listen 443
</IfModule>

<IfModule mod_gnutls.c>
	Listen 443
</IfModule>
EOF
    log_ok "ports.conf atualizado (porta ${APACHE_PORT})"
}

step_apache_vhost() {
    log_info "[2b] Configurando VirtualHost..."

    cat > "$APACHE_CONF" << EOF
<VirtualHost 0.0.0.0:${APACHE_PORT}>
    ServerAdmin admin@localhost
    DocumentRoot ${HTDOCS}

    RemoteIPHeader X-Forwarded-For
    RemoteIPTrustedProxy ${NGINX_IP}

    <Directory ${HTDOCS}>
        Options -Indexes -FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    <FilesMatch "^\.">
        Require all denied
    </FilesMatch>

    <Directory ${HTDOCS}/conf>
        Require all denied
    </Directory>

    <Directory ${HTDOCS}/data>
        Require all denied
    </Directory>

    <Directory ${HTDOCS}/api>
        Require ip 127.0.0.1 ::1 ${NGINX_IP}
    </Directory>

    <FilesMatch "debug_.*\.php$">
        Require ip 127.0.0.1 ::1
        Require all denied
    </FilesMatch>

    <FilesMatch \.php$>
        SetHandler "proxy:unix:/run/php/php${PHP_VERSION}-dolibarr.sock|fcgi://localhost/"
    </FilesMatch>

    Header always set Permissions-Policy "camera=(), microphone=(), geolocation=(), payment=()"
    ErrorLog \${APACHE_LOG_DIR}/dolibarr-error.log
    CustomLog \${APACHE_LOG_DIR}/dolibarr-access.log combined
</VirtualHost>
EOF

    /usr/sbin/a2dissite 000-default.conf 2>/dev/null || true
    /usr/sbin/a2ensite dolibarr.conf 2>/dev/null || true

    log_ok "VirtualHost reescrito"
}

step_apache_security() {
    log_info "[2c] Configurando ServerTokens e ServerSignature..."

    sed -i 's/^ServerTokens .*/ServerTokens Prod/' "$APACHE_SECURITY"
    sed -i 's/^ServerSignature .*/ServerSignature Off/' "$APACHE_SECURITY"
    log_ok "ServerTokens Prod + ServerSignature Off"
}

step_apache_modules() {
    log_info "[2d] Configurando módulos Apache..."

    /usr/sbin/a2enmod remoteip proxy_fcgi rewrite ssl headers setenvif 2>/dev/null || true
    /usr/sbin/a2dismod php${PHP_VERSION} 2>/dev/null || true
    /usr/sbin/a2disconf php${PHP_VERSION}-fpm 2>/dev/null || true

    log_ok "Módulos configurados"
}

# =============================================================================
# Step 3: nftables
# =============================================================================

step_nftables() {
    log_info "[3] Configurando nftables..."

    cat > "$NFTABLES_CONF" << EOF
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority filter; policy drop;

        iif lo accept
        ct state established,related accept
        ip protocol icmp accept
        ip6 nexthdr icmpv6 accept

        tcp dport 22 ip saddr ${DESKTOP_IP} accept
        tcp dport ${APACHE_PORT} ip saddr ${NGINX_IP} accept

        log prefix "[nftables INPUT] " drop
    }

    chain forward {
        type filter hook forward priority filter; policy drop;
    }

    chain output {
        type filter hook output priority filter; policy accept;
    }
}
EOF

    /usr/sbin/nft -f "$NFTABLES_CONF" 2>/dev/null || {
        log_warn "Falha ao carregar nftables. Verifique se os IPs estão corretos."
        log_info "Continuando mesmo assim para não quebrar o SSH."
    }

    # Ativar e habilitar nftables
    systemctl enable nftables 2>/dev/null || true
    systemctl start nftables 2>/dev/null || true

    log_ok "nftables configurado"
}

# =============================================================================
# Step 4: fail2ban
# =============================================================================

step_fail2ban() {
    log_info "[4] Configurando fail2ban..."

    # Instalar se necessário
    if ! command -v fail2ban-server &>/dev/null; then
        apt install -y fail2ban 2>&1 | tail -1
    fi

    # Filter Dolibarr login
    cat > "$FAIL2BAN_FILTER" << 'EOF'
[INCLUDES]
before = apache-common.conf

[Definition]
failregex = ^%(_apache_error_client)s .* Failed login attempt.*$
ignoreregex =
EOF

    # Jail local
    cat > "$FAIL2BAN_JAIL" << EOF
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 5

[apache-auth]
enabled  = true
port     = ${APACHE_PORT}
filter   = apache-auth
logpath  = /var/log/apache2/dolibarr-error.log

[apache-dolibarr-login]
enabled  = true
port     = ${APACHE_PORT}
filter   = apache-dolibarr-login
logpath  = /var/log/apache2/dolibarr-error.log
maxretry = 5
bantime  = 3600
EOF

    systemctl enable fail2ban 2>/dev/null || true
    systemctl restart fail2ban || log_warn "fail2ban pode já estar rodando"

    log_ok "fail2ban configurado"
}

# =============================================================================
# Step 5: Permission hardening
# =============================================================================

step_permissions() {
    log_info "[5] Aplicando hardening de permissões..."

    # Adicionar www-data ao grupo erpuser
    if ! groups www-data 2>/dev/null | grep -q erpuser; then
        /usr/sbin/usermod -aG erpuser www-data
        log_info "www-data adicionado ao grupo erpuser"
    fi

    # Arquivos: root:www-data 644
    find "$HTDOCS" -type f ! -path "${HTDOCS}/documents/*" ! -path "${HTDOCS}/conf/conf.php" -exec chown root:www-data {} + 2>/dev/null || true
    find "$HTDOCS" -type f ! -path "${HTDOCS}/documents/*" ! -path "${HTDOCS}/conf/conf.php" -exec chmod 644 {} + 2>/dev/null || true

    # Diretórios: root:www-data 755
    find "$HTDOCS" -type d ! -path "${HTDOCS}/documents/*" -exec chown root:www-data {} + 2>/dev/null || true
    find "$HTDOCS" -type d ! -path "${HTDOCS}/documents/*" -exec chmod 755 {} + 2>/dev/null || true

    # documents: erpuser:erpuser 750
    chown -R erpuser:erpuser "${HTDOCS}/documents" 2>/dev/null || true
    find "${HTDOCS}/documents" -type d -exec chmod 750 {} + 2>/dev/null || true
    find "${HTDOCS}/documents" -type f -exec chmod 640 {} + 2>/dev/null || true

    # conf.php: root:erpuser 640
    chown root:erpuser "${HTDOCS}/conf/conf.php" 2>/dev/null || true
    chmod 640 "${HTDOCS}/conf/conf.php" 2>/dev/null || true

    # theme/modern_dark: root:www-data
    if [[ -d "${HTDOCS}/theme/modern_dark" ]]; then
        chown -R root:www-data "${HTDOCS}/theme/modern_dark" 2>/dev/null || true
        find "${HTDOCS}/theme/modern_dark" -type f -exec chmod 644 {} + 2>/dev/null || true
        find "${HTDOCS}/theme/modern_dark" -type d -exec chmod 755 {} + 2>/dev/null || true
    fi

    log_ok "Permissões aplicadas"
}

# =============================================================================
# Step 6: Update conf.php
# =============================================================================

step_conf_php() {
    log_info "[6] Atualizando conf.php..."

    local CONF="${HTDOCS}/conf/conf.php"

    if [[ ! -f "$CONF" ]]; then
        log_warn "conf.php não encontrado. Pulando."
        return
    fi

    # URL
    sed -i "s|^\$dolibarr_main_url_root=.*|\$dolibarr_main_url_root='${DOMAIN}';|" "$CONF"
    sed -i "s|^\$dolibarr_main_url=.*|\$dolibarr_main_url='${DOMAIN}';|" "$CONF" 2>/dev/null || true

    # Produção
    sed -i "s|^\$dolibarr_main_prod=.*|\$dolibarr_main_prod='1';|" "$CONF"
    sed -i "s|^\$dolibarr_main_force_https=.*|\$dolibarr_main_force_https='1';|" "$CONF" 2>/dev/null || {
        # Se não existir, adiciona
        sed -i '/\$dolibarr_main_prod/a \$dolibarr_main_force_https='"'"'1'"'"';' "$CONF"
    }

    log_ok "conf.php atualizado"
}

# =============================================================================
# Step 7: Cleanup debug files
# =============================================================================

step_cleanup() {
    log_info "[7] Removendo arquivos de debug..."

    rm -f "${HTDOCS}/debug_db_raw.php" "${HTDOCS}/debug_multicurrency.php"
    rm -f "${SCRIPT_DIR}/ThemePack/htdocs/debug_db_raw.php" "${SCRIPT_DIR}/ThemePack/htdocs/debug_multicurrency.php" 2>/dev/null || true

    log_ok "Arquivos de debug removidos"
}

# =============================================================================
# Step 8: Remove mod-php if present
# =============================================================================

step_remove_mod_php() {
    log_info "[8] Removendo libapache2-mod-php (não necessário)..."

    if dpkg -l libapache2-mod-php${PHP_VERSION} 2>/dev/null | grep -q "^ii"; then
        apt remove -y libapache2-mod-php${PHP_VERSION} 2>&1 | tail -1
        log_ok "libapache2-mod-php${PHP_VERSION} removido"
    else
        log_info "libapache2-mod-php${PHP_VERSION} não instalado"
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    echo ""
    echo "============================================"
    echo "  HARDENING DE SEGURANÇA — DOLIBARR"
    echo "============================================"
    echo ""

    if [[ $EUID -ne 0 ]]; then
        log_error "Este script precisa ser executado como root"
    fi

    # Load or collect config
    if [[ "$FORCE" -eq 1 ]]; then
        log_info "Modo --force: usando defaults ou argumentos CLI"
        if [[ -z "$DESKTOP_IP" ]]; then
            DESKTOP_IP=$(detect_ssh_ip)
            DESKTOP_IP="${DESKTOP_IP:-172.16.254.248}"
        fi
        log_info "DOMAIN=${DOMAIN}, NGINX_IP=${NGINX_IP}, DESKTOP_IP=${DESKTOP_IP}, PORT=${APACHE_PORT}"
    else
        if ! load_config; then
            collect_config
        fi
    fi

    # Verify Dolibarr is installed
    if [[ ! -d "$HTDOCS" ]]; then
        log_error "Dolibarr não encontrado em ${DOL_DIR}. Execute autoinstall.sh primeiro."
    fi

    # Verify erpuser exists
    if ! id erpuser &>/dev/null; then
        log_error "Usuário erpuser não encontrado. Crie-o primeiro."
    fi

    # Check if proxy is ready (apenas na primeira execução interativa)
    if [[ "$FORCE" -eq 0 && ! -f "$CONFIG_FILE" ]]; then
        echo ""
        read -p "O proxy reverso já aponta para a porta ${APACHE_PORT}? [s/N]: " PROXY_OK
        if [[ ! "$PROXY_OK" =~ ^[Ss] ]]; then
            log_warn "Reconfigure o proxy primeiro. O script continuará, mas o site pode ficar inacessível."
        fi
    fi

    # Backup
    log_info "Criando backup em ${BACKUP_DIR}..."
    do_backup

    # Apply steps
    step_remove_mod_php
    step_fpm_pool
    step_apache_ports
    step_apache_vhost
    step_apache_security
    step_apache_modules

    validate_apache

    step_nftables
    step_fail2ban
    step_permissions
    step_conf_php
    step_cleanup

    # Restart
    restart_services

    # Health check
    health_check

    echo ""
    echo "============================================"
    echo -e "${GREEN}HARDENING CONCLUÍDO!${NC}"
    echo "============================================"
    echo ""
    echo " Backup: ${BACKUP_DIR}"
    echo " Log:    ${LOG_FILE}"
    echo ""
}

main "$@"
