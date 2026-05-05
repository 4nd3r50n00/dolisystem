#!/bin/bash

# =============================================================================
# Script de Correção de Tabelas do Dolibarr
# Criar tabelas faltantes
# =============================================================================

set -e

echo "============================================"
echo "CORREÇÃO DE TABELAS - DOLIBARR"
echo "============================================"

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

echo "Tabelas verificadas/criadas com sucesso!"

echo ""
echo "============================================"
echo "Correção concluída!"
echo "============================================"