#!/bin/bash

# =============================================================================
# Script de Migração - Aplicar Customizações do Dolibarr
# Arquivos copiados de !Changes para a instalação
# =============================================================================

set -e

DOLIBARR_DIR="/var/www/dolibarr-23.0.2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHANGES_DIR="${SCRIPT_DIR}/!Changes"

echo "============================================"
echo "MIGRAÇÃO DE CUSTOMIZAÇÕES - DOLIBARR 23.0.2"
echo "============================================"

# Copiar arquivos modificados
echo "[1/17] Copiando compta/paiement.php..."
cp -f ${CHANGES_DIR}/htdocs/compta/paiement.php ${DOLIBARR_DIR}/htdocs/compta/

echo "[2/17] Copiando core/ajax/onlineSign.php..."
cp -f ${CHANGES_DIR}/htdocs/core/ajax/onlineSign.php ${DOLIBARR_DIR}/htdocs/core/ajax/

echo "[3/17] Copiando core/lib/company.lib.php..."
cp -f ${CHANGES_DIR}/htdocs/core/lib/company.lib.php ${DOLIBARR_DIR}/htdocs/core/lib/

echo "[4/17] Copiando core/modules/commande/doc/..."
cp -f ${CHANGES_DIR}/htdocs/core/modules/commande/doc/pdf_master_order.modules.php ${DOLIBARR_DIR}/htdocs/core/modules/commande/doc/
cp -f ${CHANGES_DIR}/htdocs/core/modules/commande/doc/pdf_moderno_order.modules.php ${DOLIBARR_DIR}/htdocs/core/modules/commande/doc/

echo "[5/17] Copiando core/modules/facture/doc/..."
cp -f ${CHANGES_DIR}/htdocs/core/modules/facture/doc/pdf_master_bill.modules.php ${DOLIBARR_DIR}/htdocs/core/modules/facture/doc/

echo "[6/17] Copiando core/modules/fichinter/doc/..."
cp -f ${CHANGES_DIR}/htdocs/core/modules/fichinter/doc/pdf_master_inter.modules.php ${DOLIBARR_DIR}/htdocs/core/modules/fichinter/doc/
cp -f ${CHANGES_DIR}/htdocs/core/modules/fichinter/doc/pdf_moderno_inter.modules.php ${DOLIBARR_DIR}/htdocs/core/modules/fichinter/doc/

echo "[7/17] Copiando core/modules/propale/doc/..."
cp -f ${CHANGES_DIR}/htdocs/core/modules/propale/doc/pdf_master_propal.modules.php ${DOLIBARR_DIR}/htdocs/core/modules/propale/doc/
cp -f ${CHANGES_DIR}/htdocs/core/modules/propale/doc/pdf_moderno.modules.php ${DOLIBARR_DIR}/htdocs/core/modules/propale/doc/

echo "[8/17] Copiando expedition/card.php..."
cp -f ${CHANGES_DIR}/htdocs/expedition/card.php ${DOLIBARR_DIR}/htdocs/expedition/

echo "[9/17] Copiando langs/en_US/propal.lang..."
cp -f ${CHANGES_DIR}/htdocs/langs/en_US/propal.lang ${DOLIBARR_DIR}/htdocs/langs/en_US/

echo "[10/17] Copiando langs/pt_BR/..."
cp -f ${CHANGES_DIR}/htdocs/langs/pt_BR/*.lang ${DOLIBARR_DIR}/htdocs/langs/pt_BR/

echo "[11/17] Copiando public/onlinesign/newonlinesign.php..."
cp -f ${CHANGES_DIR}/htdocs/public/onlinesign/newonlinesign.php ${DOLIBARR_DIR}/htdocs/public/onlinesign/

echo "[12/17] Copiando theme/modern_dark..."
cp -rf ${CHANGES_DIR}/htdocs/theme/modern_dark ${DOLIBARR_DIR}/htdocs/theme/

echo "[13/17] Copiando theme/custom.css.php..."
cp -f ${CHANGES_DIR}/htdocs/theme/custom.css.php ${DOLIBARR_DIR}/htdocs/theme/

echo "[14/17] Copiando core/tpl/login.tpl.php..."
cp -f ${CHANGES_DIR}/htdocs/core/tpl/login.tpl.php ${DOLIBARR_DIR}/htdocs/core/tpl/

echo "[15/17] Copiando debug_db_raw.php..."
cp -f ${CHANGES_DIR}/htdocs/debug_db_raw.php ${DOLIBARR_DIR}/htdocs/

echo "[16/17] Copiando debug_multicurrency.php..."
cp -f ${CHANGES_DIR}/htdocs/debug_multicurrency.php ${DOLIBARR_DIR}/htdocs/

echo "[17/17] Configurando CSP do Apache para Tailwind CSS..."
a2dissite dolibarr.conf 2>/dev/null || true
cat > /etc/apache2/sites-available/dolibarr.conf << 'CSPEOF'
<VirtualHost *:80>
    ServerAdmin admin@localhost
    DocumentRoot /var/www/dolibarr-23.0.2/htdocs

    <Directory /var/www/dolibarr-23.0.2/htdocs>
        Options -Indexes -FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    <FilesMatch "^\.">
        Require all denied
    </FilesMatch>

    <Directory /var/www/dolibarr-23.0.2/htdocs/conf>
        Require all denied
    </Directory>

    <Directory /var/www/dolibarr-23.0.2/htdocs/data>
        Require all denied
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/dolibarr-error.log
    CustomLog ${APACHE_LOG_DIR}/dolibarr-access.log combined

    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://cdn.tailwindcss.com https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; connect-src 'self' https:;"
</VirtualHost>
CSPEOF
a2ensite dolibarr.conf 2>/dev/null || true

echo "[18/17] Corrigindo permissões..."
chown -R www-data:www-data ${DOLIBARR_DIR}/htdocs/theme/modern_dark
chown -R www-data:www-data ${DOLIBARR_DIR}/htdocs/documents

echo "[19/17] Selecionando tema modern_dark..."
mariadb -u root -N -e "INSERT IGNORE INTO llx_const (name, value, entity, type, visible, note) VALUES ('MAIN_THEME', 'modern_dark', 1, 'chaine', 0, 'Tema via migrate') ON DUPLICATE KEY UPDATE value='modern_dark';"

echo "[20/17] Ativando modo escuro..."
mariadb -u root -N -e "INSERT IGNORE INTO llx_const (name, value, entity, type, visible, note) VALUES ('THEME_DARKMODEENABLED', '1', 1, 'chaine', 0, 'Modo escuro via migrate') ON DUPLICATE KEY UPDATE value='1';"

echo ""
echo "============================================"
echo "MIGRAÇÃO CONCLUÍDA!"
echo "============================================"
echo ""
echo "Arquivos copiados:"
echo "  - compta/paiement.php"
echo "  - core/ajax/onlineSign.php"
echo "  - core/lib/company.lib.php"
echo "  - core/modules/commande/doc/pdf_master_order.modules.php"
echo "  - core/modules/commande/doc/pdf_moderno_order.modules.php"
echo "  - core/modules/facture/doc/pdf_master_bill.modules.php"
echo "  - core/modules/fichinter/doc/pdf_master_inter.modules.php"
echo "  - core/modules/fichinter/doc/pdf_moderno_inter.modules.php"
echo "  - core/modules/propale/doc/pdf_master_propal.modules.php"
echo "  - core/modules/propale/doc/pdf_moderno.modules.php"
echo "  - expedition/card.php"
echo "  - langs/en_US/propal.lang"
echo "  - langs/pt_BR/*.lang (70 arquivos)"
echo "  - public/onlinesign/newonlinesign.php"
echo "  - theme/modern_dark/"
echo "  - theme/custom.css.php"
echo "  - core/tpl/login.tpl.php"
echo "  - debug_db_raw.php"
echo "  - debug_multicurrency.php"
echo ""
