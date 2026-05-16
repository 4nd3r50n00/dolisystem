-- =============================================================================
-- Migracao de Customizacoes - Dolibarr 23.0.2
-- Para importacao no phpMyAdmin (InfinityFree)
-- Prefixo: llxhq_
-- =============================================================================

-- [21/27] Selecionar tema modern_dark
INSERT INTO llxhq_const (name, value, entity, type, visible, note) VALUES ('MAIN_THEME', 'modern_dark', 1, 'chaine', 0, 'Tema via migrate')
ON DUPLICATE KEY UPDATE value='modern_dark';

-- [22/27] Ativar modo escuro (sempre ativado)
INSERT INTO llxhq_const (name, value, entity, type, visible, note) VALUES ('THEME_DARKMODEENABLED', '2', 1, 'chaine', 0, 'Modo escuro via migrate')
ON DUPLICATE KEY UPDATE value='2';

-- [23/27] Configurar menu: icones com texto abaixo
INSERT INTO llxhq_const (name, value, entity, type, visible, note) VALUES ('THEME_TOPMENU_DISABLE_IMAGE', '3', 1, 'chaine', 0, 'Menu icones+texto via migrate')
ON DUPLICATE KEY UPDATE value='3';

-- [24/27] Ativar modelos PDF master

-- Inserir modelos PDF master na tabela de registros
INSERT IGNORE INTO llxhq_document_model (nom, entity, type, libelle) VALUES
('master_order', 1, 'order', 'Master Order'),
('master_bill', 1, 'invoice', 'Master Bill'),
('master_propal', 1, 'propal', 'Master Propal'),
('master_inter', 1, 'ficheinter', 'Master Inter');

-- Desabilitar outros modelos da mesma categoria (manter apenas master)
DELETE FROM llxhq_document_model WHERE type = 'order' AND nom != 'master_order';
DELETE FROM llxhq_document_model WHERE type = 'propal' AND nom != 'master_propal';
DELETE FROM llxhq_document_model WHERE type = 'invoice' AND nom != 'master_bill';
DELETE FROM llxhq_document_model WHERE type = 'ficheinter' AND nom != 'master_inter';

-- Ativar modelos PDF master
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('COMMANDE_ADDON_PDF', 'master_order', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'master_order';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('FACTURE_ADDON_PDF', 'master_bill', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'master_bill';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('PROPALE_ADDON_PDF', 'master_propal', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'master_propal';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('FICHEINTER_ADDON_PDF', 'master_inter', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'master_inter';

-- ============================================
-- NUMERACAO DE FATURAS
-- ============================================
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('FACTURE_ADDON', 'mod_facture_mercure', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'mod_facture_mercure';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('FACTURE_MERCURE_MASK_INVOICE', 'FT-{yy}{mm}-{0000@99}', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'FT-{yy}{mm}-{0000@99}';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('FACTURE_MERCURE_MASK_REPLACEMENT', 'FS-{yy}{mm}-{0000@99}', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'FS-{yy}{mm}-{0000@99}';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('FACTURE_MERCURE_MASK_CREDIT', 'NC-{yy}{mm}-{0000@99}', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'NC-{yy}{mm}-{0000@99}';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('FACTURE_MERCURE_MASK_DEPOSIT', 'AD-{yy}{mm}-{0000@99}', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'AD-{yy}{mm}-{0000@99}';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('FACTURE_TVAOPTION', '1', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = '1';

-- ============================================
-- NUMERACAO DE PEDIDOS
-- ============================================
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('COMMANDE_ADDON', 'mod_commande_saphir', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'mod_commande_saphir';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('COMMANDE_SAPHIR_MASK', 'PV-{yy}{mm}-{0000@99}', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'PV-{yy}{mm}-{0000@99}';

-- ============================================
-- NUMERACAO DE PROPOSTAS
-- ============================================
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('PROPALE_ADDON', 'mod_propale_saphir', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'mod_propale_saphir';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('PROPALE_SAPHIR_MASK', 'OR-{yy}{mm}-{0000@99}', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'OR-{yy}{mm}-{0000@99}';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('PROPALE_VALIDITY_DURATION', '15', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = '15';

-- ============================================
-- MODELOS PDF
-- ============================================
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('EXPEDITION_ADDON_PDF', 'espadon', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'espadon';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('STOCK_ADDON_PDF', 'standard_stock', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'standard_stock';

-- ============================================
-- MODELOS PDF NA TABELA
-- ============================================
INSERT IGNORE INTO llxhq_document_model (nom, entity, type, libelle) VALUES
('master_bill', 1, 'invoice', 'MasterBill'),
('master_order', 1, 'order', 'MasterOrder'),
('master_propal', 1, 'propal', 'MasterPropal'),
('soleil', 1, 'ficheinter', 'Soleil'),
('espadon', 1, 'shipping', 'Espadon'),
('cornas', 1, 'order_supplier', 'Cornas'),
('standard_stock', 1, 'stock', 'Standard Stock');

-- ============================================
-- PRODUTOS E SERVICOS
-- ============================================
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('PRODUCT_CODEPRODUCT_ADDON', 'mod_codeproduct_elephant', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'mod_codeproduct_elephant';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('PRODUCT_ELEPHANT_MASK_PRODUCT', 'RP-{00000}', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'RP-{00000}';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('PRODUCT_ELEPHANT_MASK_SERVICE', 'RS-{00000}', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'RS-{00000}';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('PRODUCT_PRICE_BASE_TYPE', 'HT', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'HT';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('PRODUCT_PRICE_UNIQ', '1', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = '1';

-- ============================================
-- PAIS E MOEDA PADRAO (BRASIL)
-- ============================================
UPDATE llxhq_c_country SET label = 'Brasil' WHERE code = 'BR';
UPDATE llxhq_c_currencies SET label = 'Real Brasileiro' WHERE code_iso = 'BRL';

INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('MAIN_INFO_SOCIETE_COUNTRY', '56:BR:Brasil', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = '56:BR:Brasil';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('MAIN_MONNAIE', 'BRL', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'BRL';

-- ============================================
-- EMPRESA/TERCEIROS
-- ============================================
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('SOCIETE_ADD_REF_IN_LIST', '0', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = '0';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('SOCIETE_CODECLIENT_ADDON', 'mod_codeclient_elephant', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'mod_codeclient_elephant';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('SOCIETE_CODECOMPTA_ADDON', 'mod_codecompta_panicum', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'mod_codecompta_panicum';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('SOCIETE_FISCAL_MONTH_START', '1', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = '1';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('COMPANY_ELEPHANT_MASK_CUSTOMER', 'C-{yy}{mm}-{0000}', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'C-{yy}{mm}-{0000}';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('COMPANY_ELEPHANT_MASK_SUPPLIER', 'F-{yy}{mm}-{0000}', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'F-{yy}{mm}-{0000}';

-- ============================================
-- ESTOQUE
-- ============================================
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('STOCK_CALCULATE_ON_VALIDATE_ORDER', '1', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = '1';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('STOCK_CALCULATE_ON_SUPPLIER_DISPATCH_ORDER', '1', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = '1';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('STOCK_DISALLOW_NEGATIVE_TRANSFER', '1', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = '1';

-- ============================================
-- LOTES E SERIES
-- ============================================
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('PRODUCTBATCH_LOT_ADDON', 'mod_lot_free', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'mod_lot_free';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('PRODUCTBATCH_SN_ADDON', 'mod_sn_free', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'mod_sn_free';

-- ============================================
-- FORNECEDOR
-- ============================================
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('COMMANDE_SUPPLIER_ADDON_PDF', 'cornas', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'cornas';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('COMMANDE_SUPPLIER_ADDON_NUMBER', 'mod_commande_fournisseur_muguet', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'mod_commande_fournisseur_muguet';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('INVOICE_SUPPLIER_ADDON_PDF', 'canelle', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'canelle';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('INVOICE_SUPPLIER_ADDON_NUMBER', 'mod_facture_fournisseur_cactus', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'mod_facture_fournisseur_cactus';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('SUPPLIER_ORDER_ADDON_PDF_ODT_PATH', 'DOL_DATA_ROOT/doctemplates/supplier_orders', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'DOL_DATA_ROOT/doctemplates/supplier_orders';
INSERT INTO llxhq_const (name, value, entity, type, visible) VALUES ('SUPPLIER_INVOICE_ADDON_PDF_ODT_PATH', 'DOL_DATA_ROOT/doctemplates/supplier_invoices', 1, 'chaine', 0)
ON DUPLICATE KEY UPDATE value = 'DOL_DATA_ROOT/doctemplates/supplier_invoices';

-- ============================================
-- CRIAR TABELA llxhq_categorie_propal
-- ============================================
CREATE TABLE IF NOT EXISTS llxhq_categorie_propal (
    fk_categorie INTEGER NOT NULL,
    fk_propal INTEGER NOT NULL,
    import_key VARCHAR(14) DEFAULT NULL,
    PRIMARY KEY (fk_categorie, fk_propal),
    KEY idx_llxhq_categorie_propal_fk_propal (fk_propal),
    KEY idx_llxhq_categorie_propal_fk_categorie (fk_categorie)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- [25/27] Inserir metodo de pagamento PIX
INSERT IGNORE INTO llxhq_c_paiement (id, entity, code, libelle, type, active, accountancy_code, module, position) VALUES
(5, 1, 'PIX', 'PIX', 2, 1, NULL, NULL, 0);

-- [26/27] Adicionar colunas PIX na tabela de contas bancarias
ALTER TABLE llxhq_bank_account
ADD COLUMN IF NOT EXISTS tipo_chave_pix ENUM('CPF','CNPJ','EMAIL','TELEFONE','ALEATORIA') NULL,
ADD COLUMN IF NOT EXISTS chave_pix VARCHAR(100) NULL;
