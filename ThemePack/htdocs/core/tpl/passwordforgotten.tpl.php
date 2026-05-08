<?php
/**
 * Página de teste - Esqueci a Senha com tema dark
 * Similar ao estilo do login.tpl.php
 */

// NOLOGIN e main.inc.php já são definidos pelo arquivo que inclui este template
require_once DOL_DOCUMENT_ROOT.'/core/lib/functions2.lib.php';

$langs->loadLangs(array('errors', 'users', 'companies'));

$action = GETPOST('action', 'aZ09');
$username = GETPOST('username', 'alphanohtml');
$message = '';

// Simular processamento
if ($action == 'buildnewpassword' && $username) {
    $message = '<div class="bg-emerald-500/20 border border-emerald-500/30 text-emerald-200 px-4 py-3 rounded-xl mb-4">
        Se houver uma conta com este usuário/e-mail, um link de recuperação foi enviado.
    </div>';
}

$titleofpage = $langs->trans('SendNewPassword');
$application = constant('DOL_APPLICATION_TITLE');
$applicationcustom = getDolGlobalString('MAIN_APPLICATION_TITLE');
if ($applicationcustom) {
    $application = (preg_match('/^\+/', $applicationcustom) ? $application : '').$applicationcustom;
}
$titleofloginpage = $langs->trans('SendNewPassword');

// Logo - mesmo padrao do login.tpl.php
if (empty($urllogo)) {
    $urllogo = DOL_URL_ROOT.'/theme/modern_dark/img/logo_white.png';
    $logosmall = getDolGlobalString('MAIN_INFO_SOCIETE_LOGO_SMALL');
    if ($logosmall) {
        $urllogo = DOL_URL_ROOT.'/viewimage.php?modulepart=mycompany&entity='.$conf->entity.'&file='.urlencode('logos/thumbs/'.$logosmall);
    } else {
        $logo = getDolGlobalString('MAIN_INFO_SOCIETE_LOGO');
        if ($logo) {
            $urllogo = DOL_URL_ROOT.'/viewimage.php?modulepart=mycompany&entity='.$conf->entity.'&file='.urlencode('logos/'.$logo);
        }
    }
}

// Nome da empresa para footer
$companyname = '';
if (is_object($mysoc) && !empty($mysoc->name)) {
    $companyname = $mysoc->name;
} elseif ($applicationcustom) {
    $companyname = $application;
}

?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?php echo $titleofpage; ?></title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    colors: {
                        emerald: {
                            50: '#ecfdf5',
                            100: '#d1fae5',
                            200: '#a7f3d0',
                            300: '#6ee7b7',
                            400: '#34d399',
                            500: '#10b981',
                            600: '#059669',
                            700: '#047857',
                            800: '#065f46',
                            900: '#064e3b',
                        },
                    },
                    animation: {
                        'gradient-x': 'gradient-x 15s ease infinite',
                        'fade-in-up': 'fadeInUp 0.8s ease-out forwards',
                    },
                    keyframes: {
                        'gradient-x': {
                            '0%, 100%': { 'background-size': '200% 200%', 'background-position': 'left center' },
                            '50%': { 'background-size': '200% 200%', 'background-position': 'right center' },
                        },
                        'fadeInUp': {
                            '0%': { opacity: '0', transform: 'translateY(10px)' },
                            '100%': { opacity: '1', transform: 'translateY(0)' },
                        }
                    }
                }
            }
        }
    </script>
    <style type="text/tailwindcss">
        @layer components {
            .glass-panel {
                @apply bg-white/5 backdrop-blur-xl border border-white/10 shadow-2xl rounded-3xl p-8;
            }
            .input-modern {
                @apply bg-black/20 border border-white/10 rounded-xl px-4 py-3 text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 transition-all w-full;
            }
            .btn-primary {
                @apply bg-emerald-600 hover:bg-emerald-500 text-white font-bold py-2.5 px-8 rounded-xl transition-all shadow-lg hover:shadow-emerald-500/20 active:scale-95;
            }
            .text-3d {
                text-shadow: 
                    0 1px 0 #047857, 
                    0 2px 0 #065f46, 
                    0 3px 0 #5b21b6, 
                    0 4px 0 #4c1d95, 
                    0 5px 10px rgba(0,0,0,0.5);
                @apply transition-transform duration-500;
            }
            .text-3d-container:hover .text-3d {
                transform: perspective(500px) rotateX(5deg) scale(1.02);
            }
            .shine-effect {
                @apply relative overflow-hidden;
            }
            .shine-effect::after {
                content: '';
                @apply absolute top-0 -left-full w-full h-full;
                background: linear-gradient(120deg, transparent, rgba(167,243,208,0.15), transparent);
                animation: shine 4s infinite;
            }
        }
        @keyframes shine {
            0% { left: -100%; }
            20% { left: 100%; }
            100% { left: 100%; }
        }
        body {
            background: #0a0a0d;
        }
    </style>
</head>
<body class="min-h-screen flex items-center justify-center p-4 overflow-hidden relative">
    <!-- Background gradient -->
    <div class="absolute inset-0 bg-gradient-to-tr from-emerald-900/10 via-black to-blue-900/10 animate-gradient-x -z-10"></div>
    
    <!-- Animated orbs -->
    <div class="absolute top-1/4 left-1/4 w-96 h-96 bg-emerald-500/10 rounded-full blur-3xl animate-pulse"></div>
    <div class="absolute bottom-1/4 right-1/4 w-96 h-96 bg-blue-500/10 rounded-full blur-3xl animate-pulse" style="animation-delay: 1s;"></div>

    <div class="w-full max-w-md">
<!-- Logo/Title -->
<div class="text-center mb-8 text-3d-container">
<div class="animate-fade-in-up">
<img src="<?php echo $urllogo; ?>" alt="" class="mx-auto mb-4" style="max-height: 80px;" />
</div>
</div>

        <!-- Glass Panel -->
        <div class="glass-panel shine-effect">
            <h2 class="text-2xl font-semibold text-white mb-6 text-center">
                <i class="fas fa-key mr-2 text-emerald-400"></i>
                Recuperar acesso
            </h2>

            <?php if ($message) { echo $message; } ?>

            <form method="POST" action="">
                <input type="hidden" name="token" value="<?php echo newToken(); ?>">
                <input type="hidden" name="action" value="buildnewpassword">

                <div class="mb-6">
                    <label for="username" class="block text-gray-300 text-sm font-medium mb-2">
                        <i class="fas fa-user mr-2 text-emerald-400"></i>
                        Usuário
                    </label>
                    <input type="text" 
                           id="username" 
                           name="username" 
                           class="input-modern"
                           placeholder="<?php echo $langs->trans('LoginOrEmail'); ?>"
                           value="<?php echo dol_escape_htmltag($username); ?>"
                           autocomplete="on"
                           required>
                </div>

                <!-- CAPTCHA -->
                <div class="mb-6">
                    <label class="block text-gray-300 text-sm font-medium mb-2">
                        <i class="fas fa-shield-alt mr-2 text-emerald-400"></i>
                        Código de segurança
                    </label>
                    <div class="bg-white/5 rounded-xl p-3 border border-white/10">
                        <?php
                        $captcha = getDolGlobalString('MAIN_SECURITY_ENABLECAPTCHA_HANDLER', 'standard');
                        $captcha_php_self = $_SERVER['PHP_SELF'].'?time='.dol_print_date(dol_now(), 'dayhourlog');
                        $dirModCaptcha = array_merge(array('main' => '/core/modules/security/captcha/'), ((isset($conf->modules_parts['captcha']) && is_array($conf->modules_parts['captcha'])) ? $conf->modules_parts['captcha'] : array()));
                        $fullpathclassfile = '';
                        foreach ($dirModCaptcha as $dir) {
                            $fullpathclassfile = dol_buildpath($dir."modCaptcha".ucfirst($captcha).'.class.php', 0, 2);
                            if ($fullpathclassfile) break;
                        }
                        if ($fullpathclassfile) {
                            include_once $fullpathclassfile;
                            $classname = "modCaptcha".ucfirst($captcha);
                            if (class_exists($classname)) {
                                $captchaobj = new $classname($db, $conf, $langs, $user);
                                if (is_object($captchaobj) && method_exists($captchaobj, 'getCaptchaCodeForForm')) {
                                    print $captchaobj->getCaptchaCodeForForm($captcha_php_self);
                                }
                            }
                        }
                        ?>
                    </div>
                </div>

                <button type="submit" class="btn-primary w-full flex items-center justify-center gap-2">
                    <i class="fas fa-paper-plane"></i>
                    Recuperar acesso
                </button>
            </form>

            <!-- Back to Login -->
            <div class="mt-6 text-center">
                <a href="<?php echo DOL_URL_ROOT; ?>/index.php" 
                   class="text-gray-400 hover:text-emerald-400 transition-colors text-sm">
                    <i class="fas fa-arrow-left mr-1"></i>
                    Voltar para Login
                </a>
            </div>
        </div>

        <!-- Footer -->
        <div class="text-center mt-8">
            <p class="text-gray-500 text-xs">
                &copy; <?php echo date('Y'); ?> <?php echo dol_escape_htmltag($companyname); ?>
            </p>
        </div>
    </div>
</body>
</html>