# Passo a Passo — Dolibarr ERP & CRM

**Versão:** 23.0.2 | **PHP:** 8.4 | **Banco:** MariaDB 11.8+

---

## 1. Instalação Automática

### 1.1 Executar autoinstall.sh

```bash
cd /root/dolisystem
./autoinstall.sh install
```

O script oferece menu interativo com dois modos de banco:

| Modo | Descrição |
|------|-----------|
| **Local** | MariaDB no próprio servidor — cria banco e usuário automaticamente |
| **Remoto** | Banco em servidor separado — escolhe criar novo ou conectar a existente |

O que o script faz:
- Instala PHP 8.4 + módulos
- Instala e configura MariaDB (modo local) ou testa conectividade (modo remoto)
- Configura Apache com headers de segurança + CSP para Tailwind CSS CDN
- Baixa Dolibarr 23.0.2 para `/var/www/dolibarr-23.0.2`
- Configura timezone `America/Sao_Paulo` (OS + php.ini)
- Configura permissões
- Configura firewall (UFW)
- Gera `.dolibarr_db_credentials` com dados de conexão

### 1.2 Finalizar via Navegador

1. Abra: `http://<IP>/install/`
2. Siga o instalador web
3. Se banco remoto já existe, escolha **"Conectar a banco existente"** — o instalador não destrói dados
4. Anote a senha do admin

### 1.3 Pós-Instalação

```bash
rm -rf /var/www/dolibarr-23.0.2/htdocs/install/
touch /var/www/dolibarr-23.0.2/htdocs/documents/install.lock
chown www-data:www-data /var/www/dolibarr-23.0.2/htdocs/documents/install.lock
```

---

## 2. Customização (ThemePack + Anti-Fingerprinting)

### 2.1 Executar custom.sh

```bash
cd /root/dolisystem
./custom.sh
```

> **Importante:** `custom.sh` só deve rodar DEPOIS do `install.php`. Se rodar antes, o SQL é pulado automaticamente (SKIP_SQL guard), mas os arquivos são copiados — rode novamente após o install.

O script faz:
- Copia ~547 arquivos do ThemePack para a instalação Dolibarr
- Aplica anti-fingerprinting (remove referências ao Dolibarr no HTML)
- Configura tema `modern_dark` como padrão
- Ativa modelos PDF master
- Configura PDF: logo 13mm altura, molduras com cantos arredondados
- Insere configurações no banco (via `MYSQL_PWD`, nunca `-p` na CLI)
- Se banco remoto detectado, instala temporariamente `default-mysql-client`, executa SQL, remove o cliente
- Reinicia Apache no final

### 2.2 O que o Anti-Fingerprinting Remove

| Alvo | Ação |
|------|------|
| Meta author em `main.inc.php` | `Dolibarr Development Team` → `getDolGlobalString('MAIN_APPLICATION_TITLE', '')` |
| "Powered by Dolibarr" | Bloco removido via range sed com `}` como delimitador |
| Comentários JS "Includes JS of Dolibarr" | Comentários removidos (padrão longo primeiro) |
| Favicon padrão | Substituído por pixel transparente |
| Logo fallback | Removido |

### 2.3 Arquivos Copiados (ThemePack)

| Categoria | Arquivos |
|-----------|----------|
| Modelos PDF | `pdf_master_order`, `pdf_master_bill`, `pdf_master_propal`, `pdf_master_inter` |
| Libs PHP | `company.lib.php` (SVG logo), `functions.lib.php` (ícones moeda FA) |
| Templates | `login.tpl.php`, `passwordforgotten.tpl.php` |
| Tema | `modern_dark/` completo, `custom.css.php` |
| Traduções | `pt_BR/*.lang` (70 arquivos), `en_US/propal.lang` |
| Outros | `paiement.php`, `onlineSign.php`, `expedition/card.php` |

### 2.4 Mapeamento Moeda → Ícone FontAwesome

Adicionado em `functions.lib.php`: BRL→dollar-sign, EUR→euro-sign, GBP→pound-sign, RUB→ruble-sign, TRY→lira-sign, JPY→yen-sign, multicurrency→coins.

### 2.5 Configurações Padrão de PDF

| Constante | Valor | Descrição |
|-----------|-------|-----------|
| `MAIN_DOCUMENTS_LOGO_HEIGHT` | `13` (mm) | Altura do logo nos PDFs (padrão Dolibarr: 20mm). Logo 6:1 fica ~80mm largura |
| `MAIN_PDF_FRAME_CORNER_RADIUS` | `1` | Molduras com cantos arredondados (0=quadrado, 1=sutil, 2=médio, 3=pronunciado) |

---

## 3. Ativação de Módulos

```bash
cd /root/dolisystem
./activate_modules_v2.sh
```

Ativa módulos Dolibarr via banco de dados (sem interface web).

---

## 4. Comandos de Gestão

```bash
./autoinstall.sh status     # Ver status dos serviços
./autoinstall.sh restart    # Reiniciar Apache + MariaDB
./autoinstall.sh backup     # Backup manual do banco
./autoinstall.sh update     # Atualizar (download + backup automático)
```

---

## 5. Servidor de Banco Remoto (Configuração Manual)

Se o modo "Remoto → Criar novo banco" do `autoinstall.sh` não for usado:

```bash
# No servidor DB
mariadb -u root <<EOF
CREATE DATABASE dolibarr CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'dolibarr_app'@'<IP_DO_SERVIDOR_APP>' IDENTIFIED BY 'SenhaForte123!';
GRANT ALL PRIVILEGES ON dolibarr.* TO 'dolibarr_app'@'<IP_DO_SERVIDOR_APP>';
FLUSH PRIVILEGES;
EOF
```

> **Nunca use `'%'` como host do usuário** — sempre o IP específico do servidor App.

---

## 6. Shared Hosting (InfinityFree)

Sem shell — apenas FTP + phpMyAdmin.

| Item | Detalhe |
|------|---------|
| Prefixo DB | `llxhq_` (não `llx_`) |
| SQL | Importar `migrate_customizations_llxhq.sql` no phpMyAdmin |
| ThemePack | Upload via FTP para paths correspondentes |
| Anti-fingerprinting | Aplicar sed **localmente antes do upload** |
| Logo | FTP para `documents/mycompany/logos/` + SQL INSERT para `MAIN_INFO_SOCIETE_LOGO` / `LOGO_SMALL` / `LOGO_MINI` |

---

## 7. Estrutura de Arquivos

```
/var/www/dolibarr-23.0.2/
├── htdocs/
│   ├── conf/            # Configurações (protegido)
│   ├── documents/       # Arquivos uploadados + install.lock
│   └── theme/
│       └── modern_dark/ # Tema customizado
/root/dolisystem/
├── autoinstall.sh       # Instalação (ex-startup_v2)
├── custom.sh            # Customização + anti-fingerprinting (ex-migrate_v2)
├── activate_modules_v2.sh
├── migrate_customizations_llxhq.sql
├── ThemePack/           # Arquivos fonte copiados pelo custom.sh
├── startup.md           # v1 arquivado (referência)
├── migrate_customizations.md  # v1 arquivado
└── activate_modules.md  # v1 arquivado
```

---

## 8. Troubleshooting

| Problema | Solução |
|----------|---------|
| HTTP 500 após custom.sh | `perl -pi -e` no `main.inc.php:1685` pode ter falhado — verifique `php -l /var/www/dolibarr-23.0.2/htdocs/main.inc.php` |
| Banco remoto inacessível | `nc -zv -w5 <DB_HOST> 3306` ou `timeout 5 bash -c "echo > /dev/tcp/<DB_HOST>/3306"` |
| Página branca | `tail /var/log/apache2/error.log` |
| Permissão negada | `chown -R www-data:www-data /var/www/dolibarr-23.0.2` |
| Tabela em falta | Verificar se `custom.sh` rodou após `install.php` (SKIP_SQL guard) |

### Fix manual do meta author (se necessário)

```bash
sed -i "1685s/.*/\tprint '<meta name=\"author\" content=\"'.getDolGlobalString('MAIN_APPLICATION_TITLE', '').'\">' .\"\\\\n\";/" /var/www/dolibarr-23.0.2/htdocs/main.inc.php && systemctl restart apache2
```

> Prefira `perl -pi -e` ao invés de `sed` para strings PHP com aspas — sed quebrou duas vezes neste caso.
