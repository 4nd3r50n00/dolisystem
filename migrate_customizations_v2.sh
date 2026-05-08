#!/bin/bash

# =============================================================================
# Script de Migração - Aplicar Customizações do Dolibarr
# Arquivos copiados de ThemePack para a instalação
# =============================================================================

set -e

DOLIBARR_DIR="/var/www/dolibarr-23.0.2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEMEPACK_DIR="${SCRIPT_DIR}/ThemePack"
CREDENTIALS_FILE="${SCRIPT_DIR}/.dolibarr_db_credentials"

if [[ ! -f "$CREDENTIALS_FILE" ]]; then
    echo "[ERRO] Arquivo de credenciais não encontrado: $CREDENTIALS_FILE"
    echo "       Execute startup.sh install primeiro."
    exit 1
fi

source "$CREDENTIALS_FILE"

DB_CMD="mysql -h ${DB_HOST} -P ${DB_PORT:-3306} -u ${DB_USER} -p${DB_PASS} ${DB_NAME}"
export MYSQL_PWD="$DB_PASS"

echo "============================================"
echo "MIGRAÇÃO DE CUSTOMIZAÇÕES - DOLIBARR 23.0.2"
echo "============================================"
echo "Banco: ${DB_HOST}:${DB_PORT:-3306}/${DB_NAME} (user: ${DB_USER})"
echo ""

# Copiar arquivos modificados
echo "[1/27] Copiando compta/paiement.php..."
cp -f ${THEMEPACK_DIR}/htdocs/compta/paiement.php ${DOLIBARR_DIR}/htdocs/compta/

echo "[2/27] Copiando core/ajax/onlineSign.php..."
cp -f ${THEMEPACK_DIR}/htdocs/core/ajax/onlineSign.php ${DOLIBARR_DIR}/htdocs/core/ajax/

echo "[3/27] Copiando core/lib/company.lib.php..."
cp -f ${THEMEPACK_DIR}/htdocs/core/lib/company.lib.php ${DOLIBARR_DIR}/htdocs/core/lib/

echo "[4/27] Copiando core/modules/commande/doc/..."
cp -f ${THEMEPACK_DIR}/htdocs/core/modules/commande/doc/pdf_master_order.modules.php ${DOLIBARR_DIR}/htdocs/core/modules/commande/doc/

echo "[5/27] Copiando core/modules/facture/doc/..."
cp -f ${THEMEPACK_DIR}/htdocs/core/modules/facture/doc/pdf_master_bill.modules.php ${DOLIBARR_DIR}/htdocs/core/modules/facture/doc/

echo "[6/27] Copiando core/modules/fichinter/doc/..."
cp -f ${THEMEPACK_DIR}/htdocs/core/modules/fichinter/doc/pdf_master_inter.modules.php ${DOLIBARR_DIR}/htdocs/core/modules/fichinter/doc/

echo "[7/27] Copiando core/modules/propale/doc/..."
cp -f ${THEMEPACK_DIR}/htdocs/core/modules/propale/doc/pdf_master_propal.modules.php ${DOLIBARR_DIR}/htdocs/core/modules/propale/doc/

echo "[8/27] Copiando expedition/card.php..."
cp -f ${THEMEPACK_DIR}/htdocs/expedition/card.php ${DOLIBARR_DIR}/htdocs/expedition/

echo "[9/27] Copiando langs/en_US/propal.lang..."
cp -f ${THEMEPACK_DIR}/htdocs/langs/en_US/propal.lang ${DOLIBARR_DIR}/htdocs/langs/en_US/

echo "[10/27] Copiando langs/pt_BR/..."
cp -f ${THEMEPACK_DIR}/htdocs/langs/pt_BR/*.lang ${DOLIBARR_DIR}/htdocs/langs/pt_BR/

echo "[11/27] Copiando public/onlinesign/newonlinesign.php..."
cp -f ${THEMEPACK_DIR}/htdocs/public/onlinesign/newonlinesign.php ${DOLIBARR_DIR}/htdocs/public/onlinesign/

echo "[12/27] Copiando theme/modern_dark..."
cp -rf ${THEMEPACK_DIR}/htdocs/theme/modern_dark ${DOLIBARR_DIR}/htdocs/theme/

echo "[13/27] Copiando theme/custom.css.php..."
cp -f ${THEMEPACK_DIR}/htdocs/theme/custom.css.php ${DOLIBARR_DIR}/htdocs/theme/

echo "[14/27] Copiando core/tpl/login.tpl.php..."
cp -f ${THEMEPACK_DIR}/htdocs/core/tpl/login.tpl.php ${DOLIBARR_DIR}/htdocs/core/tpl/

echo "[15/27] Copiando core/tpl/passwordforgotten.tpl.php..."
cp -f ${THEMEPACK_DIR}/htdocs/core/tpl/passwordforgotten.tpl.php ${DOLIBARR_DIR}/htdocs/core/tpl/

echo "[16/27] Copiando debug_db_raw.php..."
cp -f ${THEMEPACK_DIR}/htdocs/debug_db_raw.php ${DOLIBARR_DIR}/htdocs/

echo "[17/27] Copiando debug_multicurrency.php..."
cp -f ${THEMEPACK_DIR}/htdocs/debug_multicurrency.php ${DOLIBARR_DIR}/htdocs/

echo "[18/27] Configurando CSP do Apache para Tailwind CSS..."
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

<FilesMatch "debug_.*\.php$">
Require ip 127.0.0.1 ::1
Require all denied
</FilesMatch>

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

echo "[19/27] Configurando valores padrão de endereço na criação de clientes..."
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

echo "[20/27] Corrigindo permissões..."
chown -R www-data:www-data ${DOLIBARR_DIR}/htdocs/theme/modern_dark
chown -R www-data:www-data ${DOLIBARR_DIR}/htdocs/documents

echo "[21/27] Selecionando tema modern_dark..."
$DB_CMD -e "INSERT IGNORE INTO llx_const (name, value, entity, type, visible, note) VALUES ('MAIN_THEME', 'modern_dark', 1, 'chaine', 0, 'Tema via migrate') ON DUPLICATE KEY UPDATE value='modern_dark';" 2>/dev/null

echo "[22/27] Ativando modo escuro (sempre ativado)..."
$DB_CMD -e "INSERT IGNORE INTO llx_const (name, value, entity, type, visible, note) VALUES ('THEME_DARKMODEENABLED', '2', 1, 'chaine', 0, 'Modo escuro via migrate') ON DUPLICATE KEY UPDATE value='2';" 2>/dev/null

echo "[23/27] Configurando menu: ícones com texto abaixo..."
$DB_CMD -e "INSERT IGNORE INTO llx_const (name, value, entity, type, visible, note) VALUES ('THEME_TOPMENU_DISABLE_IMAGE', '3', 1, 'chaine', 0, 'Menu icones+texto via migrate') ON DUPLICATE KEY UPDATE value='3';" 2>/dev/null

echo "[24/27] Ativando modelos PDF master..."
$DB_CMD <<'EOSQL'
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
$DB_CMD <<'EOSQL'

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

echo "[25/27] Inserindo método de pagamento PIX..."
$DB_CMD -e "INSERT IGNORE INTO llx_c_paiement (id, entity, code, libelle, type, active, accountancy_code, module, position) VALUES (5, 1, 'PIX', 'PIX', 2, 1, NULL, NULL, 0);" 2>/dev/null

echo "[26/27] Adicionando colunas PIX na tabela de contas bancárias..."
$DB_CMD -e "
ALTER TABLE llx_bank_account
ADD COLUMN IF NOT EXISTS tipo_chave_pix ENUM('CPF','CNPJ','EMAIL','TELEFONE','ALEATORIA') NULL,
ADD COLUMN IF NOT EXISTS chave_pix VARCHAR(100) NULL;
" 2>/dev/null

echo "[27/27] Anti-fingerprinting: removendo assinaturas Dolibarr de páginas públicas..."

# --- main.inc.php ---

# Meta author: trocar "Dolibarr Development Team" pelo titulo da aplicacao
sed -i 's/<meta name="author" content="Dolibarr Development Team">/<meta name="author" content="<?php echo getDolGlobalString('\''MAIN_APPLICATION_TITLE'\'', '\'''\''); ?>">/' \
    ${DOLIBARR_DIR}/htdocs/main.inc.php

# Comentario CSS
sed -i "s/Includes CSS for Dolibarr theme/Includes CSS/" \
    ${DOLIBARR_DIR}/htdocs/main.inc.php

# Comentario JS (com layout)
sed -i "s/Includes JS of Dolibarr (browser layout/Includes JS (browser layout/" \
    ${DOLIBARR_DIR}/htdocs/main.inc.php

# Comentario JS (sem layout)
sed -i "s/Includes JS of Dolibarr/Includes JS/" \
    ${DOLIBARR_DIR}/htdocs/main.inc.php

# Comentario JS Footer
sed -i "s/Includes JS Footer of Dolibarr/Includes JS Footer/" \
    ${DOLIBARR_DIR}/htdocs/main.inc.php

# --- login.tpl.php ---

# Remover versao do title (linha com @ $titletruedolibarrversion)
sed -i "s/\\$titleofloginpage \.=' @ '\\.'\\$titletruedolibarrversion;/\\/\\/ Versao removida do title por seguranca (anti-fingerprinting)/" \
    ${DOLIBARR_DIR}/htdocs/core/tpl/login.tpl.php

# Remover comentarios HTML que expoe auth mode, cookie name e urlfrom
sed -i '/<!-- authentication mode = /d' ${DOLIBARR_DIR}/htdocs/core/tpl/login.tpl.php
sed -i '/<!-- cookie name used for this session = /d' ${DOLIBARR_DIR}/htdocs/core/tpl/login.tpl.php
sed -i '/<!-- urlfrom in this session = /d' ${DOLIBARR_DIR}/htdocs/core/tpl/login.tpl.php

# --- company.lib.php ---

# Remover bloco "Powered by Dolibarr" (link dolibarr.org + logo)
sed -i '/if (!getDolGlobalString.*MAIN_HIDE_POWERED_BY.*)/,/^[[:space:]]*}$/c\	\/\/ Powered by removido por seguranca (anti-fingerprinting)' \
    ${DOLIBARR_DIR}/htdocs/core/lib/company.lib.php 2>/dev/null || true

# --- PDFs master ---

# Trocar SetCreator de "Dolibarr DOL_VERSION" para "$mysoc->name"
for pdffile in \
    ${DOLIBARR_DIR}/htdocs/core/modules/commande/doc/pdf_master_order.modules.php \
    ${DOLIBARR_DIR}/htdocs/core/modules/facture/doc/pdf_master_bill.modules.php \
    ${DOLIBARR_DIR}/htdocs/core/modules/propale/doc/pdf_master_propal.modules.php \
    ${DOLIBARR_DIR}/htdocs/core/modules/fichinter/doc/pdf_master_inter.modules.php; do
    if [ -f "$pdffile" ]; then
        sed -i 's/\$pdf->SetCreator("Dolibarr "\.DOL_VERSION)/$pdf->SetCreator($mysoc->name)/' "$pdffile"
    fi
done

echo "Anti-fingerprinting aplicado."

unset MYSQL_PWD

echo ""
echo "============================================"
echo "MIGRAÇÃO CONCLUÍDA!"
echo "============================================"
echo ""
echo "Arquivos copiados do ThemePack:"
echo " - compta/paiement.php"
echo " - core/ajax/onlineSign.php"
echo " - core/lib/company.lib.php"
echo " - core/modules/commande/doc/pdf_master_order.modules.php"
echo " - core/modules/facture/doc/pdf_master_bill.modules.php"
echo " - core/modules/fichinter/doc/pdf_master_inter.modules.php"
echo " - core/modules/propale/doc/pdf_master_propal.modules.php"
echo " - expedition/card.php"
echo " - langs/en_US/propal.lang"
echo " - langs/pt_BR/*.lang (70 arquivos)"
echo " - public/onlinesign/newonlinesign.php"
echo " - theme/modern_dark/"
echo " - theme/custom.css.php"
echo " - core/tpl/login.tpl.php"
echo " - core/tpl/passwordforgotten.tpl.php"
echo " - debug_db_raw.php"
echo " - debug_multicurrency.php"
echo ""
echo "Anti-fingerprinting aplicado via sed:"
echo " - main.inc.php: meta author, comentarios CSS/JS"
echo " - login.tpl.php: versao do title, auth mode, cookie, urlfrom"
echo " - company.lib.php: Powered by Dolibarr"
echo " - 4 PDFs master: SetCreator -> nome da empresa"
echo ""
