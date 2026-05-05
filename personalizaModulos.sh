#!/bin/bash

# =============================================================================
# Script de Personalização de Configurações Dolibarr
# Apenas numeração, modelos PDF e configurações específicas
# NÃO ativa módulos nem permissões
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "PERSONALIZANDO CONFIGURAÇÕES"
echo "============================================"

mariadb -u root -N dolibarr <<'EOSQL'
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
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('COMPANY_ELEPHANT_MASK_CUSTOMER', 'C-{yy}{mm}-{0000}', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('COMPANY_ELEPHANT_MASK_SUPPLIER', 'F-{yy}{mm}-{0000}', 1, 'chaine', 0);

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
-- FORNECEDOR
-- ============================================
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('COMMANDE_SUPPLIER_ADDON_PDF', 'cornas', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('COMMANDE_SUPPLIER_ADDON_NUMBER', 'mod_commande_fournisseur_muguet', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('INVOICE_SUPPLIER_ADDON_PDF', 'canelle', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('INVOICE_SUPPLIER_ADDON_NUMBER', 'mod_facture_fournisseur_cactus', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('SUPPLIER_ORDER_ADDON_PDF_ODT_PATH', 'DOL_DATA_ROOT/doctemplates/supplier_orders', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('SUPPLIER_INVOICE_ADDON_PDF_ODT_PATH', 'DOL_DATA_ROOT/doctemplates/supplier_invoices', 1, 'chaine', 0);
EOSQL

echo ""
echo "============================================"
echo "Personalização concluída com sucesso!"
echo "============================================"
echo ""
echo "Configurações aplicadas:"
echo "  - Numeração de faturas (Mercure)"
echo "  - Numeração de pedidos (Saphir)"
echo "  - Numeração de propostas (Saphir)"
echo "  - Modelos PDF (master)"
echo "  - Produtos/Serviços (Elephant)"
echo "  - Empresa/Terceiros (Elephant)"
echo "  - Estoque"
echo "  - Lotes/Séries"
echo "  - Fornecedor"
echo ""