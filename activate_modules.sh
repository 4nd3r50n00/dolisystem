#!/bin/bash

# =============================================================================
# Script de Ativação de Módulos e Configurações Dolibarr
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "ATIVANDO MÓDULOS E CONFIGURAÇÕES DOLIBARR"
echo "============================================"

mariadb -u root -N dolibarr <<EOF
-- ============================================
-- MÓDULOS PRINCIPAIS
-- ============================================
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_SOCIETE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_PRODUCT', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_SERVICE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_FACTURE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_COMMANDE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_PROPALE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_FOURNISSEUR', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_BANQUE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_COMPTABILITE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_TAX', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_AGENDA', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_USER', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_EXPEDITION', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_STOCK', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_CATEGORIE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_ECM', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_EXPORT', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_IMPORT', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_FCKEDITOR', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_WORKFLOW', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_TICKET', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_TICKET_TRIGGERS', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_PRODUCTBATCH', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_FICHEINTER', '1', 1, 'chaine', 0);

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
EOF

echo "Módulos e configurações ativados com sucesso!"
echo ""