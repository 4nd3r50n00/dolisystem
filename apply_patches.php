<?php
/**
 * Apply PIX-related patches to Dolibarr core files.
 * Called from custom.sh for idempotent re-application.
 */

$dolibarrDir = $argv[1] ?? '/var/www/dolibarr-23.0.2';

// ─── 1. account.class.php ───
$file = $dolibarrDir . '/htdocs/compta/bank/class/account.class.php';
if (is_file($file)) {
    $content = file_get_contents($file);

    // Patch 1: Add properties after public $rowid
    if (strpos($content, 'public $chave_pix;') === false) {
        $content = str_replace(
            "\tpublic \$rowid;\n\n\t/**\n\t * Account Label",
            "\tpublic \$rowid;\n\n\t/** PIX key */\n\tpublic \$chave_pix;\n\n\t/** PIX key type (CPF, CNPJ, phone, email, random) */\n\tpublic \$tipo_chave_pix;\n\n\t/**\n\t * Account Label",
            $content
        );
        echo "  [account.class.php] properties: OK\n";
    } else {
        echo "  [account.class.php] properties: already applied\n";
    }

    // Patch 2: Add fields in SELECT after ba.currency_code,
    if (strpos($content, 'ba.chave_pix') === false) {
        $content = str_replace(
            "\$sql .= \" ba.account_number, ba.fk_accountancy_journal, ba.currency_code,\";\n\t\t\$sql .= \" ba.min_allowed",
            "\$sql .= \" ba.account_number, ba.fk_accountancy_journal, ba.currency_code,\";\n\t\t\$sql .= \" ba.chave_pix, ba.tipo_chave_pix,\";\n\t\t\$sql .= \" ba.min_allowed",
            $content
        );
        echo "  [account.class.php] SELECT fields: OK\n";
    } else {
        echo "  [account.class.php] SELECT fields: already applied\n";
    }

    // Patch 3: Add assignments after account_currency_code
    if (strpos($content, '$this->chave_pix = $obj->chave_pix;') === false) {
        $content = str_replace(
            "\$this->account_currency_code = \$obj->currency_code;\n\n\t\t\t\t\$this->min_allowed    = \$obj->min_allowed;",
            "\$this->account_currency_code = \$obj->currency_code;\n\n\t\t\t\t\$this->chave_pix = \$obj->chave_pix;\n\t\t\t\t\$this->tipo_chave_pix = \$obj->tipo_chave_pix;\n\n\t\t\t\t\$this->min_allowed    = \$obj->min_allowed;",
            $content
        );
        echo "  [account.class.php] fetch assignments: OK\n";
    } else {
        echo "  [account.class.php] fetch assignments: already applied\n";
    }

    // Patch 4: Add columns in INSERT after ics_transfer
    $replace = "\$sql .= \", ics_transfer\";\n\t\t\$sql .= \", chave_pix\";\n\t\t\$sql .= \", tipo_chave_pix\";\n\t\t\$sql .= \") VALUES (\";";
    if (strpos($content, ', chave_pix') === false) {
        $content = str_replace($search, $replace, $content);
        echo "  [account.class.php] INSERT columns: OK\n";
    } else {
        echo "  [account.class.php] INSERT columns: already applied\n";
    }

    // Patch 2: Add VALUES after ics_transfer value
    $search = "\$sql .= \", '\" . \$this->db->escape(\$this->ics_transfer) . \"'\";\n\t\t\$sql .= \")\";";
    $replace = "\$sql .= \", '\" . \$this->db->escape(\$this->ics_transfer) . \"'\";\n\t\t\$sql .= \", \" . (!empty(\$this->chave_pix) ? \"'\" . \$this->db->escape(\$this->chave_pix) . \"'\" : \"null\");\n\t\t\$sql .= \", \" . (!empty(\$this->tipo_chave_pix) ? \"'\" . \$this->db->escape(\$this->tipo_chave_pix) . \"'\" : \"null\");\n\t\t\$sql .= \")\";";
    if (strpos($content, 'tipo_chave_pix) ?') === false) {
        $content = str_replace($search, $replace, $content);
        echo "  [account.class.php] INSERT VALUES: OK\n";
    } else {
        echo "  [account.class.php] INSERT VALUES: already applied\n";
    }

    // Patch 3: Add UPDATE SET after ics_transfer
    $search = "\$sql .= \",ics_transfer = '\" . \$this->db->escape(\$this->ics_transfer) . \"'\";\n\n\t\t\$sql .= \" WHERE rowid = \";";
    $replace = "\$sql .= \",ics_transfer = '\" . \$this->db->escape(\$this->ics_transfer) . \"'\";\n\t\t\$sql .= \",chave_pix = \" . (!empty(\$this->chave_pix) ? \"'\" . \$this->db->escape(\$this->chave_pix) . \"'\" : \"null\");\n\t\t\$sql .= \",tipo_chave_pix = \" . (!empty(\$this->tipo_chave_pix) ? \"'\" . \$this->db->escape(\$this->tipo_chave_pix) . \"'\" : \"null\");\n\n\t\t\$sql .= \" WHERE rowid = \";";
    if (strpos($content, ',chave_pix =') === false) {
        $content = str_replace($search, $replace, $content);
        echo "  [account.class.php] UPDATE SET: OK\n";
    } else {
        echo "  [account.class.php] UPDATE SET: already applied\n";
    }

    file_put_contents($file, $content);
}

// ─── 2. card.php: POST handling (create + update) ───
$file = $dolibarrDir . '/htdocs/compta/bank/card.php';
if (is_file($file)) {
    $content = file_get_contents($file);

    // Patch: Add chave_pix/tipo_chave_pix after each ics_transfer POST line
    $search = "\$object->ics_transfer = trim(GETPOST(\"ics_transfer\", 'alpha'));";
    $replace = "\$object->ics_transfer = trim(GETPOST(\"ics_transfer\", 'alpha'));\n\t\t\$object->chave_pix = trim(GETPOST(\"chave_pix\", 'alpha'));\n\t\t\$object->tipo_chave_pix = GETPOST(\"tipo_chave_pix\", 'alpha');";
    if (strpos($content, 'chave_pix = trim') === false) {
        $count = 0;
        $content = str_replace($search, $replace, $content, $count);
        echo "  [card.php] POST handling: OK ($count occurrences)\n";
    } else {
        echo "  [card.php] POST handling: already applied\n";
    }

    // Patch: CREATE form — add PIX fields after getFieldsToShow loop
    $search = "\t\t\tprint '</tr>';\n\t\t}\n\n\t\tif (isModEnabled('paymentbybanktransfer')) {";
    $replace = "\t\t\tprint '</tr>';\n\t\t}\n\n\t\tprint '<tr><td>'.\$langs->trans(\"ChavePix\").'</td>';\n\t\tprint '<td><input type=\"text\" class=\"flat minwidth200\" name=\"chave_pix\" value=\"'.(GETPOSTISSET('chave_pix') ? GETPOST('chave_pix', 'alpha') : \$object->chave_pix).'\"></td></tr>';\n\n\t\tprint '<tr><td>'.\$langs->trans(\"TipoChavePix\").'</td><td>';\n\t\tprint \$form->selectarray(\"tipo_chave_pix\", array('CPF' => 'CPF', 'CNPJ' => 'CNPJ', 'EMAIL' => \$langs->trans(\"TipoChavePixEMAIL\"), 'TELEFONE' => \$langs->trans(\"TipoChavePixTELEFONE\"), 'ALEATORIA' => \$langs->trans(\"TipoChavePixALEATORIA\")), (GETPOSTISSET('tipo_chave_pix') ? GETPOST('tipo_chave_pix', 'alpha') : \$object->tipo_chave_pix));\n\t\tprint '</td></tr>';\n\n\t\tif (isModEnabled('paymentbybanktransfer')) {";
    if (strpos($content, 'selectarray("tipo_chave_pix"') === false) {
        $content = str_replace($search, $replace, $content);
        echo "  [card.php] CREATE form fields: OK\n";
    } else {
        echo "  [card.php] CREATE form fields: already applied\n";
    }

    // Patch: EDIT form — add PIX fields before </table>
    $search = "\t\t\t\tif (\$mysoc->isInSEPA()) {\n\t\t\t\t\tprint '<tr><td>'.\$form->textwithpicto(\$langs->trans(\"SEPAXMLPlacePaymentTypeInformationInCreditTransfertransactionInformation\"), \$langs->trans(\"SEPAXMLPlacePaymentTypeInformationInCreditTransfertransactionInformationHelp\")).'</td>';\n\t\t\t\t\tprint '<td><input type=\"checkbox\" class=\"flat\" name=\"pti_in_ctti\"'. (\$object->pti_in_ctti ? ' checked ' : '') . '>';\n\t\t\t\t\tprint '</td></tr>';\n\t\t\t\t}\n\t\t\t}\n\n\t\t\tprint '</table>';";
    $replace = "\t\t\t\tif (\$mysoc->isInSEPA()) {\n\t\t\t\t\tprint '<tr><td>'.\$form->textwithpicto(\$langs->trans(\"SEPAXMLPlacePaymentTypeInformationInCreditTransfertransactionInformation\"), \$langs->trans(\"SEPAXMLPlacePaymentTypeInformationInCreditTransfertransactionInformationHelp\")).'</td>';\n\t\t\t\t\tprint '<td><input type=\"checkbox\" class=\"flat\" name=\"pti_in_ctti\"'. (\$object->pti_in_ctti ? ' checked ' : '') . '>';\n\t\t\t\t\tprint '</td></tr>';\n\t\t\t\t}\n\t\t\t}\n\n\t\t\tprint '<tr><td>'.\$langs->trans(\"ChavePix\").'</td>';\n\t\t\tprint '<td><input class=\"minwidth200 maxwidth200onsmartphone\" type=\"text\" class=\"flat\" name=\"chave_pix\" value=\"'.(GETPOSTISSET('chave_pix') ? GETPOST('chave_pix', 'alphanohtml') : \$object->chave_pix).'\"></td></tr>';\n\n\t\t\tprint '<tr><td>'.\$langs->trans(\"TipoChavePix\").'</td><td>';\n\t\t\tprint \$form->selectarray(\"tipo_chave_pix\", array('CPF' => 'CPF', 'CNPJ' => 'CNPJ', 'EMAIL' => \$langs->trans(\"TipoChavePixEMAIL\"), 'TELEFONE' => \$langs->trans(\"TipoChavePixTELEFONE\"), 'ALEATORIA' => \$langs->trans(\"TipoChavePixALEATORIA\")), (GETPOSTISSET('tipo_chave_pix') ? GETPOST('tipo_chave_pix', 'alphanohtml') : \$object->tipo_chave_pix));\n\t\t\tprint '</td></tr>';\n\n\t\t\tprint '</table>';";
    // Check if the EDIT-mode selectarray (with alphanohtml) already exists
    if (preg_match('/' . preg_quote('selectarray("tipo_chave_pix"', '/') . '.+' . preg_quote('alphanohtml', '/') . '/s', $content)) {
        echo "  [card.php] EDIT form fields: already applied\n";
    } else {
        $content = str_replace($search, $replace, $content);
        echo "  [card.php] EDIT form fields: OK\n";
    }

    // Patch: VIEW mode — display PIX data before BankAccountOwner
    $search = "\t\t\tif (isModEnabled('paymentbybanktransfer')) {\n\t\t\t\tif (getDolGlobalString(\"SEPA_USE_IDS\")) {\n\t\t\t\t\tprint '<tr><td>'.\$form->textwithpicto(\$langs->trans(\"IDS\"), \$langs->trans(\"IDS\").' ('.\$langs->trans(\"UsedFor\", \$langs->transnoentitiesnoconv(\"BankTransfer\")).')').'</td>';\n\t\t\t\t\tprint '<td>'.\$object->ics_transfer.'</td>';\n\t\t\t\t\tprint '</tr>';\n\t\t\t\t}\n\t\t\t\tif (\$mysoc->isInSEPA()) {\n\t\t\t\t\tprint '<tr><td>'.\$form->textwithpicto(\$langs->trans(\"SEPAXMLPlacePaymentTypeInformationInCreditTransfertransactionInformation\"), \$langs->trans(\"SEPAXMLPlacePaymentTypeInformationInCreditTransfertransactionInformationHelp\")).'</td><td>';\n\t\t\t\t\tprint(empty(\$object->pti_in_ctti) ? \$langs->trans(\"No\") : \$langs->trans(\"Yes\"));\n\t\t\t\t\tprint \"</td></tr>\\n\";\n\t\t\t\t}\n\t\t\t}\n\n\t\t\tprint '<tr><td>'.\$langs->trans(\"BankAccountOwner\").'</td><td>';";
    $replace = "\t\t\tif (isModEnabled('paymentbybanktransfer')) {\n\t\t\t\tif (getDolGlobalString(\"SEPA_USE_IDS\")) {\n\t\t\t\t\tprint '<tr><td>'.\$form->textwithpicto(\$langs->trans(\"IDS\"), \$langs->trans(\"IDS\").' ('.\$langs->trans(\"UsedFor\", \$langs->transnoentitiesnoconv(\"BankTransfer\")).')').'</td>';\n\t\t\t\t\tprint '<td>'.\$object->ics_transfer.'</td>';\n\t\t\t\t\tprint '</tr>';\n\t\t\t\t}\n\t\t\t\tif (\$mysoc->isInSEPA()) {\n\t\t\t\t\tprint '<tr><td>'.\$form->textwithpicto(\$langs->trans(\"SEPAXMLPlacePaymentTypeInformationInCreditTransfertransactionInformation\"), \$langs->trans(\"SEPAXMLPlacePaymentTypeInformationInCreditTransfertransactionInformationHelp\")).'</td><td>';\n\t\t\t\t\tprint(empty(\$object->pti_in_ctti) ? \$langs->trans(\"No\") : \$langs->trans(\"Yes\"));\n\t\t\t\t\tprint \"</td></tr>\\n\";\n\t\t\t\t}\n\t\t\t}\n\n\t\t\tif (!empty(\$object->chave_pix)) {\n\t\t\t\tprint '<tr><td>'.\$langs->trans(\"ChavePix\").'</td>';\n\t\t\t\tprint '<td>'.\$object->chave_pix.' ('.\$langs->trans(\"TipoChavePix\".\$object->tipo_chave_pix).')</td></tr>';\n\t\t\t}\n\n\t\t\tprint '<tr><td>'.\$langs->trans(\"BankAccountOwner\").'</td><td>';";
    $uniqueViewPattern = '!empty($object->chave_pix';
    if (strpos($content, $uniqueViewPattern) === false) {
        $content = str_replace($search, $replace, $content);
        echo "  [card.php] VIEW display: OK\n";
    } else {
        echo "  [card.php] VIEW display: already applied\n";
    }

    file_put_contents($file, $content);
}

echo "Done.\n";
