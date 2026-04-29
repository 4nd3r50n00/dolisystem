<?php
include 'conf/conf.php';
$conn = new mysqli($dolibarr_main_db_host, $dolibarr_main_db_user, 'dolcrypt:AES-256-CTR:7f0effbdd9cb65cd:zj0EHlVcJgQysECvHw==', $dolibarr_main_db_name);

echo "--- LLX_CONST ---\n";
$res = $conn->query("SELECT name, value FROM llx_const WHERE name IN ('MAIN_MONEY_CODE', 'MAIN_MONEY_SYMBOL', 'MAIN_INFO_SOCIETE_COUNTRY', 'MAIN_INFO_SOCIETE_CURRENCY')");
while ($row = $res->fetch_assoc()) {
    echo $row['name'] . " = " . $row['value'] . "\n";
}

echo "\n--- LLX_SOCIETE (Entity 1) ---\n";
$res = $conn->query("SELECT rowid, nom, canvas, fk_pays, parent, fk_multicurrency FROM llx_societe LIMIT 1");
while ($row = $res->fetch_assoc()) {
    print_r($row);
}
