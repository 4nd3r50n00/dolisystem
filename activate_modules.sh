#!/bin/bash

# =============================================================================
# Script de Ativação de Módulos Dolibarr
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "ATIVANDO MÓDULOS DOLIBARR"
echo "============================================"

mariadb -u root -N dolibarr <<EOF
-- Módulos principais
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_SOCIETE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_PRODUCT', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_SERVICE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_FACTURE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_COMMANDE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_PROPALE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_FOURNISSEUR', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_BANQUE', '1', 1, 'chaine', 0);
INSERT IGNORE INTO llx_const (name, value, entity, type, visible) VALUES ('MAIN_MODULE_COMPTA', '1', 1, 'chaine', 0);
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
EOF

echo "Módulos ativados com sucesso!"
echo ""