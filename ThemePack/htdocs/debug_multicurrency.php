<?php
define('NOLIBDB', 1);
define('NOLOGIN', 1);
define('NOCSRFCHECK', 1);
define('NOIPCHECK', 1);
require 'main.inc.php';

echo "Multi-currency module enabled: " . (isModEnabled('multicurrency') ? 'Yes' : 'No') . "\n";
if (isModEnabled('multicurrency')) {
    $sql = "SELECT rowid, code, name, symbol FROM " . MAIN_DB_PREFIX . "multicurrency WHERE entity = " . $conf->entity;
    $res = $db->query($sql);
    while ($row = $db->fetch_array($res)) {
        echo "Currency: " . $row['code'] . " | Name: " . $row['name'] . " | Symbol: " . $row['symbol'] . "\n";
    }
}

echo "MAIN_MONEY_CODE from conf: " . $conf->currency . "\n";
echo "MAIN_MONEY_CODE from database: " . getDolGlobalString('MAIN_MONEY_CODE') . "\n";
