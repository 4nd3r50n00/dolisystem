#!/bin/bash

# =============================================================================
# Script de Ativação de Módulos e Configurações Dolibarr
# Versão corrigida: inclui permissões e concessões ao admin
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "ATIVANDO MÓDULOS E CONFIGURAÇÕES DOLIBARR"
echo "============================================"

mariadb -u root -N dolibarr <<'EOSQL'
-- ============================================
-- MÓDULOS PRINCIPAIS (ativas constante)
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
-- PERMISSÕES - Terceiros (societe)
-- ============================================
INSERT IGNORE INTO llx_rights_def (id, entity, libelle, module, module_position, family, type, bydefault, perms, subperms, enabled) VALUES
(121, 1, 'Read third parties', 'societe', 10, 'crm', 'r', 0, 'lire', NULL, '1'),
(122, 1, 'Create and update third parties', 'societe', 10, 'crm', 'w', 0, 'creer', NULL, '1'),
(125, 1, 'Delete third parties', 'societe', 10, 'crm', 'd', 0, 'supprimer', NULL, '1'),
(126, 1, 'Export third parties', 'societe', 10, 'crm', 'r', 0, 'export', NULL, '1'),
(281, 1, 'Read contacts', 'societe', 10, 'crm', 'r', 0, 'contact', NULL, '1'),
(282, 1, 'Create and update contact', 'societe', 10, 'crm', 'w', 0, 'contact', NULL, '1'),
(283, 1, 'Delete contacts', 'societe', 10, 'crm', 'd', 0, 'contact', NULL, '1'),
(286, 1, 'Export contacts', 'societe', 10, 'crm', 'd', 0, 'contact', NULL, '1');

-- ============================================
-- PERMISSÕES - Produtos (produit)
-- ============================================
INSERT IGNORE INTO llx_rights_def (id, entity, libelle, module, module_position, family, type, bydefault, perms, subperms, enabled) VALUES
(31, 1, 'Read products', 'produit', 10, 'products', 'r', 0, 'lire', NULL, '1'),
(32, 1, 'Create/modify products', 'produit', 10, 'products', 'w', 0, 'creer', NULL, '1'),
(33, 1, 'Read prices products', 'produit', 10, 'products', 'r', 0, 'product_advance', NULL, '1'),
(34, 1, 'Read supplier prices', 'produit', 10, 'products', 'r', 0, 'product_advance', NULL, '1'),
(35, 1, 'Write supplier prices', 'produit', 10, 'products', 'w', 0, 'product_advance', NULL, '1'),
(36, 1, 'Delete products', 'produit', 10, 'products', 'd', 0, 'supprimer', NULL, '1'),
(38, 1, 'Export products', 'produit', 10, 'products', 'r', 0, 'export', NULL, '1'),
(39, 1, 'Ignore price minimum', 'produit', 10, 'products', 'r', 0, 'ignore_price_min_advance', NULL, '1');

-- ============================================
-- PERMISSÕES - Serviços (service)
-- ============================================
INSERT IGNORE INTO llx_rights_def (id, entity, libelle, module, module_position, family, type, bydefault, perms, subperms, enabled) VALUES
(1001, 1, 'Read services', 'service', 10, 'products', 'r', 0, 'lire', NULL, '1'),
(1002, 1, 'Create/modify services', 'service', 10, 'products', 'w', 0, 'creer', NULL, '1'),
(1003, 1, 'Read prices services', 'service', 10, 'products', 'r', 0, 'service_advance', NULL, '1'),
(1004, 1, 'Read supplier prices', 'service', 10, 'products', 'r', 0, 'service_advance', NULL, '1'),
(1005, 1, 'Delete services', 'service', 10, 'products', 'd', 0, 'supprimer', NULL, '1');

-- ============================================
-- PERMISSÕES - Faturas (facture)
-- ============================================
INSERT IGNORE INTO llx_rights_def (id, entity, libelle, module, module_position, family, type, bydefault, perms, subperms, enabled) VALUES
(401, 1, 'Read customer invoices', 'facture', 10, 'accountancy', 'r', 0, 'lire', NULL, '1'),
(402, 1, 'Create and update customer invoices', 'facture', 10, 'accountancy', 'w', 0, 'creer', NULL, '1'),
(403, 1, 'Validate customer invoices', 'facture', 10, 'accountancy', 'd', 0, 'facture_advance', 'validate', '1'),
(404, 1, 'Send invoices by email', 'facture', 10, 'accountancy', 'd', 0, 'facture_advance', 'send', '1'),
(405, 1, 'Credit note', 'facture', 10, 'accountancy', 'd', 0, 'facture_advance', 'creditnote', '1'),
(406, 1, 'Send customer invoice payment', 'facture', 10, 'accountancy', 'd', 0, 'facture_advance', 'paid', '1'),
(407, 1, 'Delete customer invoices', 'facture', 10, 'accountancy', 'd', 0, 'supprimer', NULL, '1'),
(408, 1, 'Export invoices', 'facture', 10, 'accountancy', 'r', 0, 'export', NULL, '1');

-- ============================================
-- PERMISSÕES - Pedidos (commande)
-- ============================================
INSERT IGNORE INTO llx_rights_def (id, entity, libelle, module, module_position, family, type, bydefault, perms, subperms, enabled) VALUES
(351, 1, 'Read customer orders', 'commande', 10, 'commercial', 'r', 0, 'lire', NULL, '1'),
(352, 1, 'Create and update customer orders', 'commande', 10, 'commercial', 'w', 0, 'creer', NULL, '1'),
(353, 1, 'Validate customer orders', 'commande', 10, 'commercial', 'd', 0, 'order_advance', 'validate', '1'),
(354, 1, 'Send orders by email', 'commande', 10, 'commercial', 'd', 0, 'order_advance', 'send', '1'),
(355, 1, 'Close orders', 'commande', 10, 'commercial', 'd', 0, 'order_advance', 'close', '1'),
(356, 1, 'Cancel orders', 'commande', 10, 'commercial', 'd', 0, 'order_advance', 'cancel', '1'),
(357, 1, 'Delete orders', 'commande', 10, 'commercial', 'd', 0, 'supprimer', NULL, '1'),
(358, 1, 'Export orders', 'commande', 10, 'commercial', 'r', 0, 'export', NULL, '1');

-- ============================================
-- PERMISSÕES - Orçamentos (propale)
-- ============================================
INSERT IGNORE INTO llx_rights_def (id, entity, libelle, module, module_position, family, type, bydefault, perms, subperms, enabled) VALUES
(21, 1, 'Read commercial proposals', 'propale', 10, 'crm', 'r', 0, 'lire', NULL, '1'),
(22, 1, 'Create and update commercial proposals', 'propale', 10, 'crm', 'w', 0, 'creer', NULL, '1'),
(24, 1, 'Validate commercial proposals', 'propale', 10, 'crm', 'd', 0, 'propal_advance', 'validate', '1'),
(25, 1, 'Send commercial proposals to customers', 'propale', 10, 'crm', 'd', 0, 'propal_advance', 'send', '1'),
(26, 1, 'Close commercial proposals', 'propale', 10, 'crm', 'd', 0, 'propal_advance', 'close', '1'),
(27, 1, 'Delete commercial proposals', 'propale', 10, 'crm', 'd', 0, 'supprimer', NULL, '1'),
(28, 1, 'Exporting commercial proposals and attributes', 'propale', 10, 'crm', 'r', 0, 'export', NULL, '1'),
(29, 1, 'Reopen commercial proposals', 'propale', 10, 'crm', 'w', 0, 'propal_advance', 'reopen', '1');

-- ============================================
-- PERMISSÕES - Fornecedores (fournisseur)
-- ============================================
INSERT IGNORE INTO llx_rights_def (id, entity, libelle, module, module_position, family, type, bydefault, perms, subperms, enabled) VALUES
(701, 1, 'Read suppliers', 'fournisseur', 10, 'accountancy', 'r', 0, 'lire', NULL, '1'),
(702, 1, 'Create and update suppliers', 'fournisseur', 10, 'accountancy', 'w', 0, 'creer', NULL, '1'),
(703, 1, 'Delete suppliers', 'fournisseur', 10, 'accountancy', 'd', 0, 'supprimer', NULL, '1'),
(704, 1, 'Read supplier orders', 'fournisseur', 10, 'accountancy', 'r', 0, 'commande', 'lire', '1'),
(705, 1, 'Create supplier orders', 'fournisseur', 10, 'accountancy', 'w', 0, 'commande', 'creer', '1'),
(706, 1, 'Validate supplier orders', 'fournisseur', 10, 'accountancy', 'd', 0, 'commande', 'validate', '1'),
(707, 1, 'Close supplier orders', 'fournisseur', 10, 'accountancy', 'd', 0, 'commande', 'close', '1'),
(708, 1, 'Cancel supplier orders', 'fournisseur', 10, 'accountancy', 'd', 0, 'commande', 'cancel', '1'),
(709, 1, 'Read supplier invoices', 'fournisseur', 10, 'accountancy', 'r', 0, 'facture', 'lire', '1'),
(710, 1, 'Create supplier invoices', 'fournisseur', 10, 'accountancy', 'w', 0, 'facture', 'creer', '1'),
(711, 1, 'Validate supplier invoices', 'fournisseur', 10, 'accountancy', 'd', 0, 'facture', 'validate', '1'),
(712, 1, 'Pay supplier invoices', 'fournisseur', 10, 'accountancy', 'd', 0, 'facture', 'paid', '1'),
(713, 1, 'Delete supplier invoices', 'fournisseur', 10, 'accountancy', 'd', 0, 'facture', 'supprimer', '1');

-- ============================================
-- PERMISSÕES - Banco (banque)
-- ============================================
-- PERMISSÕES - Contabilidade (comptabilite)
-- ============================================
INSERT IGNORE INTO llx_rights_def (id, entity, libelle, module, module_position, family, type, bydefault, perms, subperms, enabled) VALUES
(95, 1, 'Lire CA, bilans, resultats', 'compta', 10, 'accountancy', 'r', 0, 'resultat', 'lire', '1');

-- ============================================
-- PERMISSÕES - Banco (banque)
-- ============================================
INSERT IGNORE INTO llx_rights_def (id, entity, libelle, module, module_position, family, type, bydefault, perms, subperms, enabled) VALUES
(501, 1, 'Read bank accounts', 'banque', 10, 'accountancy', 'r', 0, 'lire', NULL, '1'),
(502, 1, 'Create/modify bank accounts', 'banque', 10, 'accountancy', 'w', 0, 'creer', NULL, '1'),
(503, 1, 'Delete bank accounts', 'banque', 10, 'accountancy', 'd', 0, 'supprimer', NULL, '1'),
(504, 1, 'Read bank transactions', 'banque', 10, 'accountancy', 'r', 0, 'transaction', NULL, '1'),
(505, 1, 'Create/modify bank transactions', 'banque', 10, 'accountancy', 'w', 0, 'transaction', NULL, '1'),
(506, 1, 'Delete bank transactions', 'banque', 10, 'accountancy', 'd', 0, 'transaction', NULL, '1'),
(507, 1, 'Export bank transactions', 'banque', 10, 'accountancy', 'r', 0, 'export', NULL, '1');

-- ============================================
-- PERMISSÕES - Expedição (expedition)
-- ============================================
INSERT IGNORE INTO llx_rights_def (id, entity, libelle, module, module_position, family, type, bydefault, perms, subperms, enabled) VALUES
(901, 1, 'Read shipments', 'expedition', 10, 'commercial', 'r', 0, 'lire', NULL, '1'),
(902, 1, 'Create shipments', 'expedition', 10, 'commercial', 'w', 0, 'creer', NULL, '1'),
(903, 1, 'Validate shipments', 'expedition', 10, 'commercial', 'd', 0, 'expedition_advance', 'validate', '1'),
(904, 1, 'Send shipments by email', 'expedition', 10, 'commercial', 'd', 0, 'expedition_advance', 'send', '1'),
(905, 1, 'Close shipments', 'expedition', 10, 'commercial', 'd', 0, 'expedition_advance', 'close', '1'),
(906, 1, 'Delete shipments', 'expedition', 10, 'commercial', 'd', 0, 'supprimer', NULL, '1'),
(907, 1, 'Export shipments', 'expedition', 10, 'commercial', 'r', 0, 'export', NULL, '1');

-- ============================================
-- PERMISSÕES - Estoque (stock)
-- ============================================
INSERT IGNORE INTO llx_rights_def (id, entity, libelle, module, module_position, family, type, bydefault, perms, subperms, enabled) VALUES
(801, 1, 'Read stocks', 'stock', 10, 'products', 'r', 0, 'lire', NULL, '1'),
(802, 1, 'Create/modify stocks', 'stock', 10, 'products', 'w', 0, 'creer', NULL, '1'),
(803, 1, 'Delete stocks', 'stock', 10, 'products', 'd', 0, 'supprimer', NULL, '1'),
(804, 1, 'Read movement of stocks', 'stock', 10, 'products', 'r', 0, 'movement', NULL, '1'),
(805, 1, 'Create movement of stocks', 'stock', 10, 'products', 'w', 0, 'movement', NULL, '1');

-- ============================================
-- PERMISSÕES - Categorias (categorie)
-- ============================================
INSERT IGNORE INTO llx_rights_def (id, entity, libelle, module, module_position, family, type, bydefault, perms, subperms, enabled) VALUES
(601, 1, 'Read categories', 'categorie', 10, 'products', 'r', 0, 'lire', NULL, '1'),
(602, 1, 'Create/modify categories', 'categorie', 10, 'products', 'w', 0, 'creer', NULL, '1'),
(603, 1, 'Delete categories', 'categorie', 10, 'products', 'd', 0, 'supprimer', NULL, '1');

-- ============================================
-- PERMISSÕES - ECM
-- ============================================
INSERT IGNORE INTO llx_rights_def (id, entity, libelle, module, module_position, family, type, bydefault, perms, subperms, enabled) VALUES
(1101, 1, 'Read ECM', 'ecm', 10, 'technic', 'r', 0, 'lire', NULL, '1'),
(1102, 1, 'Create/modify ECM', 'ecm', 10, 'technic', 'w', 0, 'creer', NULL, '1'),
(1103, 1, 'Delete ECM', 'ecm', 10, 'technic', 'd', 0, 'supprimer', NULL, '1'),
(1104, 1, 'Upload ECM', 'ecm', 10, 'technic', 'w', 0, 'upload', NULL, '1'),
(1105, 1, 'Download ECM', 'ecm', 10, 'technic', 'r', 0, 'download', NULL, '1');

-- ============================================
-- PERMISSÕES - Agenda (agenda)
-- ============================================
INSERT IGNORE INTO llx_rights_def (id, entity, libelle, module, module_position, family, type, bydefault, perms, subperms, enabled) VALUES
(2401, 1, 'Read actions (events or tasks) of others', 'agenda', 10, 'technic', 'r', 0, 'allactions', NULL, '1'),
(2402, 1, 'Read actions (events or tasks) of others', 'agenda', 10, 'technic', 'r', 0, 'allactions', NULL, '1'),
(2411, 1, 'Read all actions (events or tasks)', 'agenda', 10, 'technic', 'r', 0, 'allactions', NULL, '1'),
(2412, 1, 'Read all actions (events or tasks)', 'agenda', 10, 'technic', 'r', 0, 'allactions', NULL, '1'),
(2414, 1, 'Export actions', 'agenda', 10, 'technic', 'r', 0, 'export', NULL, '1');

-- ============================================
-- PERMISSÕES - Workflow
-- ============================================
INSERT IGNORE INTO llx_rights_def (id, entity, libelle, module, module_position, family, type, bydefault, perms, subperms, enabled) VALUES
(2201, 1, 'Read workflow', 'workflow', 10, 'technic', 'r', 0, 'lire', NULL, '1'),
(2202, 1, 'Create/modify workflow', 'workflow', 10, 'technic', 'w', 0, 'creer', NULL, '1');

-- ============================================
-- PERMISSÕES - Tickets
-- ============================================
INSERT IGNORE INTO llx_rights_def (id, entity, libelle, module, module_position, family, type, bydefault, perms, subperms, enabled) VALUES
(2301, 1, 'Read ticket', 'ticket', 10, 'commercial', 'r', 0, 'lire', NULL, '1'),
(2302, 1, 'Create tickets', 'ticket', 10, 'commercial', 'w', 0, 'creer', NULL, '1'),
(2303, 1, 'Delete tickets', 'ticket', 10, 'commercial', 'd', 0, 'supprimer', NULL, '1'),
(2304, 1, 'Manage tickets', 'ticket', 10, 'commercial', 'w', 0, 'manage', NULL, '1'),
(2305, 1, 'Export ticket', 'ticket', 10, 'commercial', 'r', 0, 'export', NULL, '1'),
(2306, 1, 'See all tickets', 'ticket', 10, 'commercial', 'r', 0, 'readall', NULL, '1');

-- ============================================
-- PERMISSÕES - Intervenções (ficheinter)
-- ============================================
INSERT IGNORE INTO llx_rights_def (id, entity, libelle, module, module_position, family, type, bydefault, perms, subperms, enabled) VALUES
(1401, 1, 'Read interventions', 'ficheinter', 10, 'commercial', 'r', 0, 'lire', NULL, '1'),
(1402, 1, 'Create/modify interventions', 'ficheinter', 10, 'commercial', 'w', 0, 'creer', NULL, '1'),
(1403, 1, 'Delete interventions', 'ficheinter', 10, 'commercial', 'd', 0, 'supprimer', NULL, '1'),
(1404, 1, 'Validate interventions', 'ficheinter', 10, 'commercial', 'd', 0, 'ficheinter_advance', 'validate', '1'),
(1405, 1, 'Close interventions', 'ficheinter', 10, 'commercial', 'd', 0, 'ficheinter_advance', 'close', '1'),
(1406, 1, 'Export interventions', 'ficheinter', 10, 'commercial', 'r', 0, 'export', NULL, '1');

-- ============================================
-- CONCEDER PERMISSÕES AO ADMIN
-- ============================================
INSERT IGNORE INTO llx_user_rights (fk_user, fk_id) 
SELECT 1, r.id FROM llx_rights_def r WHERE r.entity = 1
AND r.id IN (
    121,122,125,126,281,282,283,286,
    31,32,33,34,35,36,38,39,
    1001,1002,1003,1004,1005,
    401,402,403,404,405,406,407,408,
    351,352,353,354,355,356,357,358,
    21,22,24,25,26,27,28,29,
    701,702,703,704,705,706,707,708,709,710,711,712,713,
    501,502,503,504,505,506,507,
    901,902,903,904,905,906,907,
    801,802,803,804,805,
    601,602,603,
    1101,1102,1103,1104,1105,
    2401,2402,2411,2412,2414,
    2201,2202,
    2301,2302,2303,2304,2305,2306,
    1401,1402,1403,1404,1405,1406
) AND r.id NOT IN (SELECT fk_id FROM llx_user_rights WHERE fk_user = 1);

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
-- FORNECEDOR (FOURNISSEUR)
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
echo "Módulos e configurações ativados com sucesso!"
echo "Permissões concedidas ao admin (id=1)"
echo "============================================"
echo ""