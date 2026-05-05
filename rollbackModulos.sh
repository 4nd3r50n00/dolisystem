#!/bin/bash

# =============================================================================
# Script de Rollback - Desativar Módulos do Dolibarr
# Restaura o sistema ao estado original (sem módulos ativados)
# Execute este ANTES do personalizaModulos.sh se precisar resetar
# =============================================================================

set -e

echo "============================================"
echo "ROLLBACK - DESATIVANDO MÓDULOS"
echo "============================================"

mariadb -u root -N dolibarr <<'EOSQL'
-- ============================================
-- DESATIVAR MÓDULOS (todas as ativações do personaliza)
-- ============================================
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_SOCIETE' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_PRODUCT' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_SERVICE' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_FACTURE' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_COMMANDE' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_PROPALE' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_FOURNISSEUR' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_BANQUE' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_COMPTABILITE' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_TAX' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_AGENDA' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_USER' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_EXPEDITION' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_STOCK' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_CATEGORIE' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_ECM' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_EXPORT' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_IMPORT' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_FCKEDITOR' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_WORKFLOW' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_TICKET' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_TICKET_TRIGGERS' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_PRODUCTBATCH' AND entity = 1;
UPDATE llx_const SET value = '0' WHERE name = 'MAIN_MODULE_FICHEINTER' AND entity = 1;

-- ============================================
-- REMOVER PERMISSÕES DO ADMIN (ID=1)
-- ============================================
DELETE FROM llx_user_rights WHERE fk_user = 1;

-- ============================================
-- REMOVER DEFINIÇÕES DE PERMISSÕES ADICIONADAS
-- ============================================
DELETE FROM llx_rights_def WHERE id IN (
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
    1401,1402,1403,1404,1405,1406,
    95
);
EOSQL

echo ""
echo "============================================"
echo "ROLLBACK CONCLUÍDO!"
echo "Todos os módulos foram desativados"
echo "Permissões removidas do admin"
echo "============================================"
echo ""
echo "Agora você pode ativar os módulos manualmente"
echo "via interface web do Dolibarr"
echo "e depois rodar o personalizaModulos.sh"
echo ""