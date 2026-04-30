#!/bin/bash

# =============================================================================
# Script de Personalizações Dolibarr
# Aplica configurações após módulos serem ativados via interface web
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "APLICANDO PERSONALIZAÇÕES DOLIBARR"
echo "============================================"

mariadb -u root -N dolibarr <<EOF
-- ============================================
-- NUMERAÇÃO DE FATURAS
-- ============================================
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('FACTURE_ADDON', 'mod_facture_mercure', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('FACTURE_MERCURE_MASK_INVOICE', 'FT-{yy}{mm}-{0000@99}', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('FACTURE_MERCURE_MASK_REPLACEMENT', 'FS-{yy}{mm}-{0000@99}', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('FACTURE_MERCURE_MASK_CREDIT', 'NC-{yy}{mm}-{0000@99}', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('FACTURE_MERCURE_MASK_DEPOSIT', 'AD-{yy}{mm}-{0000@99}', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('FACTURE_TVAOPTION', '1', 1, 'chaine', 0);

-- ============================================
-- NUMERAÇÃO DE PEDIDOS
-- ============================================
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('COMMANDE_ADDON', 'mod_commande_saphir', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('COMMANDE_SAPHIR_MASK', 'PV-{yy}{mm}-{0000@99}', 1, 'chaine', 0);

-- ============================================
-- NUMERAÇÃO DE PROPOSTAS
-- ============================================
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('PROPALE_ADDON', 'mod_propale_saphir', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('PROPALE_SAPHIR_MASK', 'OR-{yy}{mm}-{0000@99}', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('PROPALE_VALIDITY_DURATION', '15', 1, 'chaine', 0);

-- ============================================
-- MODELOS PDF
-- ============================================
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('FACTURE_ADDON_PDF', 'master_bill', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('COMMANDE_ADDON_PDF', 'master_order', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('PROPALE_ADDON_PDF', 'master_propal', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('EXPEDITION_ADDON_PDF', 'espadon', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('FICHEINTER_ADDON_PDF', 'soleil', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('STOCK_ADDON_PDF', 'standard_stock', 1, 'chaine', 0);

-- ============================================
-- PRODUTOS E SERVIÇOS
-- ============================================
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('PRODUCT_CODEPRODUCT_ADDON', 'mod_codeproduct_elephant', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('PRODUCT_ELEPHANT_MASK_PRODUCT', 'RP-{00000}', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('PRODUCT_ELEPHANT_MASK_SERVICE', 'RS-{00000}', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('PRODUCT_PRICE_BASE_TYPE', 'HT', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('PRODUCT_PRICE_UNIQ', '1', 1, 'chaine', 0);

-- ============================================
-- EMPRESA/TERCEIROS
-- ============================================
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('SOCIETE_ADD_REF_IN_LIST', '0', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('SOCIETE_CODECLIENT_ADDON', 'mod_codeclient_elephant', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('SOCIETE_CODECOMPTA_ADDON', 'mod_codecompta_panicum', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('SOCIETE_FISCAL_MONTH_START', '1', 1, 'chaine', 0);

-- ============================================
-- ESTOQUE
-- ============================================
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('STOCK_CALCULATE_ON_VALIDATE_ORDER', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('STOCK_CALCULATE_ON_SUPPLIER_DISPATCH_ORDER', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('STOCK_DISALLOW_NEGATIVE_TRANSFER', '1', 1, 'chaine', 0);

-- ============================================
-- LOTES E SÉRIES
-- ============================================
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('PRODUCTBATCH_LOT_ADDON', 'mod_lot_free', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('PRODUCTBATCH_SN_ADDON', 'mod_sn_free', 1, 'chaine', 0);

-- ============================================
-- AGENDA - AUTOMÇÕES
-- ============================================
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_ACTION_CREATE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_COMPANY_CREATE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_COMPANY_MODIFY', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_COMPANY_DELETE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_CONTACT_CREATE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_CONTACT_MODIFY', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_BILL_VALIDATE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_BILL_UNVALIDATE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_BILL_MODIFY', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_BILL_DELETE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_BILL_CREATE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_BILL_SENTBYMAIL', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_BILL_PAYED', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_BILL_CANCEL', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_ORDER_VALIDATE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_ORDER_CLOSED', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_ORDER_CANCELED', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_PROPAL_VALIDATE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_PROPAL_CLOSE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_PROPAL_SENTBYMAIL', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_PROD_CREATE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_PROD_MODIFY', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_ORDER_SUPPLIER_VALIDATE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_ORDER_SUPPLIER_APPROVE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_ORDER_SUPPLIER_REFUSE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_ORDER_SUPPLIER_CANCELED', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_BILL_SUPPLIER_VALIDATE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_BILL_SUPPLIER_UNVALIDATE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_BILL_SUPPLIER_MODIFY', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_BILL_SUPPLIER_DELETE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_BILL_SUPPLIER_PAYED', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_BILL_SUPPLIER_CANCELED', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_BILL_SUPPLIER_SENTBYMAIL', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_AGENDA_ACTIONAUTO_EXPEDITION_VALIDATE', '1', 1, 'chaine', 0);
EOF

echo "Personalizações aplicadas com sucesso!"
echo ""