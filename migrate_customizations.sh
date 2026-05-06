#!/bin/bash

# =============================================================================
# Script de Migração - Aplicar Customizações do Dolibarr
# Arquivos copiados de ThemePack para a instalação
# =============================================================================

set -e

DOLIBARR_DIR="/var/www/dolibarr-23.0.2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMEPACK_DIR="${SCRIPT_DIR}/ThemePack"

echo "============================================"
echo "MIGRAÇÃO DE CUSTOMIZAÇÕES - DOLIBARR 23.0.2"
echo "============================================"

# Copiar arquivos modificados
echo "[1/17] Copiando compta/paiement.php..."
cp -f ${THEMEPACK_DIR}/htdocs/compta/paiement.php ${DOLIBARR_DIR}/htdocs/compta/

echo "[2/17] Copiando core/ajax/onlineSign.php..."
cp -f ${THEMEPACK_DIR}/htdocs/core/ajax/onlineSign.php ${DOLIBARR_DIR}/htdocs/core/ajax/

echo "[3/17] Copiando core/lib/company.lib.php..."
cp -f ${THEMEPACK_DIR}/htdocs/core/lib/company.lib.php ${DOLIBARR_DIR}/htdocs/core/lib/

echo "[4/17] Copiando core/modules/commande/doc/..."
cp -f ${THEMEPACK_DIR}/htdocs/core/modules/commande/doc/pdf_master_order.modules.php ${DOLIBARR_DIR}/htdocs/core/modules/commande/doc/

echo "[5/17] Copiando core/modules/facture/doc/..."
cp -f ${THEMEPACK_DIR}/htdocs/core/modules/facture/doc/pdf_master_bill.modules.php ${DOLIBARR_DIR}/htdocs/core/modules/facture/doc/

echo "[6/17] Copiando core/modules/fichinter/doc/..."
cp -f ${THEMEPACK_DIR}/htdocs/core/modules/fichinter/doc/pdf_master_inter.modules.php ${DOLIBARR_DIR}/htdocs/core/modules/fichinter/doc/

echo "[7/17] Copiando core/modules/propale/doc/..."
cp -f ${THEMEPACK_DIR}/htdocs/core/modules/propale/doc/pdf_master_propal.modules.php ${DOLIBARR_DIR}/htdocs/core/modules/propale/doc/

echo "[8/17] Copiando expedition/card.php..."
cp -f ${THEMEPACK_DIR}/htdocs/expedition/card.php ${DOLIBARR_DIR}/htdocs/expedition/

echo "[9/17] Copiando langs/en_US/propal.lang..."
cp -f ${THEMEPACK_DIR}/htdocs/langs/en_US/propal.lang ${DOLIBARR_DIR}/htdocs/langs/en_US/

echo "[10/17] Copiando langs/pt_BR/..."
cp -f ${THEMEPACK_DIR}/htdocs/langs/pt_BR/*.lang ${DOLIBARR_DIR}/htdocs/langs/pt_BR/

echo "[11/17] Copiando public/onlinesign/newonlinesign.php..."
cp -f ${THEMEPACK_DIR}/htdocs/public/onlinesign/newonlinesign.php ${DOLIBARR_DIR}/htdocs/public/onlinesign/

echo "[12/17] Copiando theme/modern_dark..."
cp -rf ${THEMEPACK_DIR}/htdocs/theme/modern_dark ${DOLIBARR_DIR}/htdocs/theme/

echo "[13/17] Copiando theme/custom.css.php..."
cp -f ${THEMEPACK_DIR}/htdocs/theme/custom.css.php ${DOLIBARR_DIR}/htdocs/theme/

echo "[14/17] Copiando core/tpl/login.tpl.php..."
cp -f ${THEMEPACK_DIR}/htdocs/core/tpl/login.tpl.php ${DOLIBARR_DIR}/htdocs/core/tpl/

echo "[14b/17] Copiando core/tpl/passwordforgotten.tpl.php..."
cp -f ${THEMEPACK_DIR}/htdocs/core/tpl/passwordforgotten.tpl.php ${DOLIBARR_DIR}/htdocs/core/tpl/

echo "[15/17] Copiando debug_db_raw.php..."
cp -f ${THEMEPACK_DIR}/htdocs/debug_db_raw.php ${DOLIBARR_DIR}/htdocs/

echo "[16/17] Copiando debug_multicurrency.php..."
cp -f ${THEMEPACK_DIR}/htdocs/debug_multicurrency.php ${DOLIBARR_DIR}/htdocs/

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

echo "[18/17] Configurando valores padrão de endereço na criação de clientes..."
if ! grep -q "mysoc->zip" ${DOLIBARR_DIR}/htdocs/societe/card.php; then
	sed -i '/\$object->zip = GETPOST.*zipcode/a\
		if ($action == '\''create'\'' \&\& empty($object->zip)) {\
			$object->zip = $mysoc->zip;\
		}' ${DOLIBARR_DIR}/htdocs/societe/card.php
	sed -i '/\$object->town = GETPOST.*town/a\
		if ($action == '\''create'\'' \&\& empty($object->town)) {\
			$object->town = $mysoc->town;\
		}' ${DOLIBARR_DIR}/htdocs/societe/card.php
	sed -i '/\$object->state_id = GETPOSTINT.*state_id/a\
		if ($action == '\''create'\'' \&\& empty($object->state_id)) {\
			$object->state_id = $mysoc->state_id;\
		}' ${DOLIBARR_DIR}/htdocs/societe/card.php
fi

echo "[19/17] Corrigindo permissões..."
chown -R www-data:www-data ${DOLIBARR_DIR}/htdocs/theme/modern_dark
chown -R www-data:www-data ${DOLIBARR_DIR}/htdocs/documents

echo "[20/17] Selecionando tema modern_dark..."
mariadb -u root -N dolibarr -e "INSERT IGNORE INTO llx_const (name, value, entity, type, visible, note) VALUES ('MAIN_THEME', 'modern_dark', 1, 'chaine', 0, 'Tema via migrate') ON DUPLICATE KEY UPDATE value='modern_dark';"

echo "[21/17] Ativando modo escuro (sempre ativado)..."
mariadb -u root -N dolibarr -e "INSERT IGNORE INTO llx_const (name, value, entity, type, visible, note) VALUES ('THEME_DARKMODEENABLED', '2', 1, 'chaine', 0, 'Modo escuro via migrate') ON DUPLICATE KEY UPDATE value='2';"

echo "[22/17] Configurando menu: ícones com texto abaixo..."
mariadb -u root -N dolibarr -e "INSERT IGNORE INTO llx_const (name, value, entity, type, visible, note) VALUES ('THEME_TOPMENU_DISABLE_IMAGE', '3', 1, 'chaine', 0, 'Menu icones+texto via migrate') ON DUPLICATE KEY UPDATE value='3';"

echo "[23/17] Ativando modelos PDF master..."
mariadb -u root -N dolibarr <<'EOSQL'
-- Inserir modelos PDF master na tabela de registros
INSERT IGNORE INTO llx_document_model (nom, entity, type, libelle) VALUES
('master_order', 1, 'order', 'Master Order'),
('master_bill', 1, 'invoice', 'Master Bill'),
('master_propal', 1, 'propal', 'Master Propal'),
('master_inter', 1, 'ficheinter', 'Master Inter');

-- Desabilitar outros modelos da mesma categoria (manter apenas master)
DELETE FROM llx_document_model WHERE type = 'order' AND nom != 'master_order';
DELETE FROM llx_document_model WHERE type = 'propal' AND nom != 'master_propal';
DELETE FROM llx_document_model WHERE type = 'invoice' AND nom != 'master_bill';
DELETE FROM llx_document_model WHERE type = 'ficheinter' AND nom != 'master_inter';

-- Ativar modelos PDF master (INSERT se não existir, UPDATE se existir)
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('COMMANDE_ADDON_PDF', 'master_order', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'master_order';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('FACTURE_ADDON_PDF', 'master_bill', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'master_bill';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('PROPALE_ADDON_PDF', 'master_propal', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'master_propal';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('FICHEINTER_ADDON_PDF', 'master_inter', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'master_inter';

-- ============================================
-- NUMERAÇÃO DE FATURAS
-- ============================================
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('FACTURE_ADDON', 'mod_facture_mercure', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'mod_facture_mercure';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('FACTURE_MERCURE_MASK_INVOICE', 'FT-{yy}{mm}-{0000@99}', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'FT-{yy}{mm}-{0000@99}';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('FACTURE_MERCURE_MASK_REPLACEMENT', 'FS-{yy}{mm}-{0000@99}', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'FS-{yy}{mm}-{0000@99}';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('FACTURE_MERCURE_MASK_CREDIT', 'NC-{yy}{mm}-{0000@99}', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'NC-{yy}{mm}-{0000@99}';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('FACTURE_MERCURE_MASK_DEPOSIT', 'AD-{yy}{mm}-{0000@99}', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'AD-{yy}{mm}-{0000@99}';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('FACTURE_TVAOPTION', '1', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = '1';

-- ============================================
-- NUMERAÇÃO DE PEDIDOS
-- ============================================
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('COMMANDE_ADDON', 'mod_commande_saphir', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'mod_commande_saphir';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('COMMANDE_SAPHIR_MASK', 'PV-{yy}{mm}-{0000@99}', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'PV-{yy}{mm}-{0000@99}';

-- ============================================
-- NUMERAÇÃO DE PROPOSTAS
-- ============================================
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('PROPALE_ADDON', 'mod_propale_saphir', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'mod_propale_saphir';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('PROPALE_SAPHIR_MASK', 'OR-{yy}{mm}-{0000@99}', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'OR-{yy}{mm}-{0000@99}';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('PROPALE_VALIDITY_DURATION', '15', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = '15';

-- ============================================
-- MODELOS PDF
-- ============================================
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('EXPEDITION_ADDON_PDF', 'espadon', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'espadon';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('STOCK_ADDON_PDF', 'standard_stock', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'standard_stock';

-- ============================================
-- MODELOS PDF NA TABELA
-- ============================================
INSERT IGNORE INTO llx_document_model (nom, entity, type, libelle) VALUES
('master_bill', 1, 'invoice', 'MasterBill'),
('master_order', 1, 'order', 'MasterOrder'),
('master_propal', 1, 'propal', 'MasterPropal'),
('soleil', 1, 'ficheinter', 'Soleil'),
('espadon', 1, 'shipping', 'Espadon'),
('cornas', 1, 'order_supplier', 'Cornas'),
('standard_stock', 1, 'stock', 'Standard Stock');

-- ============================================
-- PRODUTOS E SERVIÇOS
-- ============================================
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('PRODUCT_CODEPRODUCT_ADDON', 'mod_codeproduct_elephant', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'mod_codeproduct_elephant';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('PRODUCT_ELEPHANT_MASK_PRODUCT', 'RP-{00000}', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'RP-{00000}';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('PRODUCT_ELEPHANT_MASK_SERVICE', 'RS-{00000}', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'RS-{00000}';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('PRODUCT_PRICE_BASE_TYPE', 'HT', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'HT';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('PRODUCT_PRICE_UNIQ', '1', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = '1';

-- ============================================
-- PAÍS E MOEDA PADRÃO (BRASIL)
-- ============================================
-- Corrigir label do país para Português
UPDATE llx_c_country SET label = 'Brasil' WHERE code = 'BR';

-- Corrigir label da moeda para Português
UPDATE llx_c_currencies SET label = 'Real Brasileiro' WHERE code_iso = 'BRL';

-- Configurar país e moeda padrão
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_INFO_SOCIETE_COUNTRY', '56:BR:Brasil', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = '56:BR:Brasil';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MONNAIE', 'BRL', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'BRL';

-- ============================================
-- EMPRESA/TERCEIROS
-- ============================================
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('SOCIETE_ADD_REF_IN_LIST', '0', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = '0';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('SOCIETE_CODECLIENT_ADDON', 'mod_codeclient_elephant', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'mod_codeclient_elephant';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('SOCIETE_CODECOMPTA_ADDON', 'mod_codecompta_panicum', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'mod_codecompta_panicum';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('SOCIETE_FISCAL_MONTH_START', '1', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = '1';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('COMPANY_ELEPHANT_MASK_CUSTOMER', 'C-{yy}{mm}-{0000}', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'C-{yy}{mm}-{0000}';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('COMPANY_ELEPHANT_MASK_SUPPLIER', 'F-{yy}{mm}-{0000}', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'F-{yy}{mm}-{0000}';

-- ============================================
-- ESTOQUE
-- ============================================
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('STOCK_CALCULATE_ON_VALIDATE_ORDER', '1', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = '1';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('STOCK_CALCULATE_ON_SUPPLIER_DISPATCH_ORDER', '1', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = '1';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('STOCK_DISALLOW_NEGATIVE_TRANSFER', '1', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = '1';

-- ============================================
-- LOTES E SÉRIES
-- ============================================
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('PRODUCTBATCH_LOT_ADDON', 'mod_lot_free', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'mod_lot_free';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('PRODUCTBATCH_SN_ADDON', 'mod_sn_free', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'mod_sn_free';

-- ============================================
-- FORNECEDOR
-- ============================================
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('COMMANDE_SUPPLIER_ADDON_PDF', 'cornas', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'cornas';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('COMMANDE_SUPPLIER_ADDON_NUMBER', 'mod_commande_fournisseur_muguet', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'mod_commande_fournisseur_muguet';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('INVOICE_SUPPLIER_ADDON_PDF', 'canelle', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'canelle';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('INVOICE_SUPPLIER_ADDON_NUMBER', 'mod_facture_fournisseur_cactus', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'mod_facture_fournisseur_cactus';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('SUPPLIER_ORDER_ADDON_PDF_ODT_PATH', 'DOL_DATA_ROOT/doctemplates/supplier_orders', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'DOL_DATA_ROOT/doctemplates/supplier_orders';
INSERT INTO llx_const (name, value, entity, type, visible) VALUES ('SUPPLIER_INVOICE_ADDON_PDF_ODT_PATH', 'DOL_DATA_ROOT/doctemplates/supplier_invoices', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'DOL_DATA_ROOT/doctemplates/supplier_invoices';
EOSQL

echo "Configurações de banco de dados aplicadas."
mariadb -u root dolibarr <<'EOSQL'

-- Verificar e criar llx_categorie_propal se não existir
CREATE TABLE IF NOT EXISTS llx_categorie_propal (
  fk_categorie INTEGER NOT NULL,
  fk_propal INTEGER NOT NULL,
  import_key VARCHAR(14) DEFAULT NULL,
  PRIMARY KEY (fk_categorie, fk_propal),
  KEY idx_llx_categorie_propal_fk_propal (fk_propal),
  KEY idx_llx_categorie_propal_fk_categorie (fk_categorie)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

EOSQL

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
echo "  - core/modules/facture/doc/pdf_master_bill.modules.php"
echo "  - core/modules/fichinter/doc/pdf_master_inter.modules.php"
echo "  - core/modules/propale/doc/pdf_master_propal.modules.php"
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
