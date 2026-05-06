<?php
/* Copyright (C) 2009-2015 	Regis Houssin           <regis.houssin@inodbox.com>
 * Copyright (C) 2011-2022 	Laurent Destailleur     <eldy@users.sourceforge.net>
 * Copyright (C) 2024		MDW						<mdeweerd@users.noreply.github.com>
 * Copyright (C) 2024       Frédéric France         <frederic.france@free.fr>
 * Copyright (C) 2024       Charlene Benke          <charlene@patas-monkey.com>
 * Copyright (C) 2025       Marc de Lima Lucio      <marc-dll@user.noreply.github.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

// Need global variable $urllogo, $title and $titletruedolibarrversion to be defined by caller (like dol_loginfunction in security2.lib.php)
// Caller can also set 	$morelogincontent = array(['options']=>array('js'=>..., 'table'=>...);
// $titletruedolibarrversion must be defined

if (!defined('NOBROWSERNOTIF')) {
	define('NOBROWSERNOTIF', 1);
}
/**
 * @var Conf $conf
 * @var DoliDB $db
 * @var Translate $langs
 * @var User $user
 *
 * @var string $dolibarr_main_force_https
 *
 * @var string $captcha
 *
 * @var int<0,1> $dol_hide_leftmenu
 * @var int<0,1> $dol_hide_topmenu
 * @var int<0,1> $dol_no_mouse_hover
 * @var int<0,1> $dol_optimize_smallscreen
 * @var int<0,1> $dol_use_jmobile
 * @var string $focus_element
 * @var string $login
 * @var string $main_authentication
 * @var string $main_home
 * @var string $password
 * @var string $session_name
 * @var string $title
 * @var string $titletruedolibarrversion
 * @var string $urllogo
 * @var int<0,1> $forgetpasslink
 * @var string $morelogincontent
 * @var string $moreloginextracontent
 */
// Protection to avoid direct call of template
if (empty($conf) || !is_object($conf)) {
	print "Error, template page can't be called as URL";
	exit(1);
}

// DDOS protection
$size = (empty($_SERVER['CONTENT_LENGTH']) ? 0 : (int) $_SERVER['CONTENT_LENGTH']);
if ($size > 10000) {
	$langs->loadLangs(array("errors", "install"));
	httponly_accessforbidden('<center>'.$langs->trans("ErrorRequestTooLarge").'.<br><a href="'.DOL_URL_ROOT.'">'.$langs->trans("ClickHereToGoToApp").'</a></center>', 413, 1);
}

require_once DOL_DOCUMENT_ROOT.'/core/lib/functions2.lib.php';

'
@phan-var-force HookManager $hookmanager
@phan-var-force string $action
@phan-var-force string $captcha
@phan-var-force int<0,1> $dol_hide_leftmenu
@phan-var-force int<0,1> $dol_hide_topmenu
@phan-var-force int<0,1> $dol_no_mouse_hover
@phan-var-force int<0,1> $dol_optimize_smallscreen
@phan-var-force int<0,1> $dol_use_jmobile
@phan-var-force string $focus_element
@phan-var-force string $login
@phan-var-force string $main_authentication
@phan-var-force string $main_home
@phan-var-force string $password
@phan-var-force string $session_name
@phan-var-force string $titletruedolibarrversion
@phan-var-force string $urllogo
@phan-var-force int<0,1> $forgetpasslink
';

/**
 * @var HookManager $hookmanager
 * @var string $action
 * @var string $captcha
 * @var string $message
 * @var string $title
 */


/*
 * View
 */

header('Cache-Control: Public, must-revalidate');

if (GETPOST('dol_hide_topmenu')) {
	$conf->dol_hide_topmenu = 1;
}
if (GETPOST('dol_hide_leftmenu')) {
	$conf->dol_hide_leftmenu = 1;
}
if (GETPOST('dol_optimize_smallscreen')) {
	$conf->dol_optimize_smallscreen = 1;
}
if (GETPOST('dol_no_mouse_hover')) {
	$conf->dol_no_mouse_hover = 1;
}
if (GETPOST('dol_use_jmobile')) {
	$conf->dol_use_jmobile = 1;
}

// If we force to use jmobile, then we reenable javascript
if (!empty($conf->dol_use_jmobile)) {
	$conf->use_javascript_ajax = 1;
}

$php_self = empty($php_self) ? dol_escape_htmltag($_SERVER['PHP_SELF']) : $php_self;
if (!empty($_SERVER["QUERY_STRING"]) && dol_escape_htmltag($_SERVER["QUERY_STRING"])) {
	$php_self .= '?'.dol_escape_htmltag($_SERVER["QUERY_STRING"]);
}
if (!preg_match('/mainmenu=/', $php_self)) {
	$php_self .= (preg_match('/\?/', $php_self) ? '&' : '?').'mainmenu=home';
}
if (preg_match('/'.preg_quote('core/modules/oauth', '/').'/', $php_self)) {
	$php_self = DOL_URL_ROOT.'/index.php?mainmenu=home';
}
$php_self = preg_replace('/(\?|&amp;|&)action=[^&]+/', '\1', $php_self);
$php_self = preg_replace('/(\?|&amp;|&)actionlogin=[^&]+/', '\1', $php_self);
$php_self = preg_replace('/(\?|&amp;|&)afteroauthloginreturn=[^&]+/', '\1', $php_self);
$php_self = preg_replace('/(\?|&amp;|&)username=[^&]*/', '\1', $php_self);
$php_self = preg_replace('/(\?|&amp;|&)entity=\d+/', '\1', $php_self);
$php_self = preg_replace('/(\?|&amp;|&)massaction=[^&]+/', '\1', $php_self);
$php_self = preg_replace('/(\?|&amp;|&)token=[^&]+/', '\1', $php_self);
$php_self = preg_replace('/(&amp;)+/', '&amp;', $php_self);

// Javascript code on logon page only to detect user tz, dst_observed, dst_first, dst_second
$arrayofjs = array(
	'/core/js/dst.js'.(empty($conf->dol_use_jmobile) ? '' : '?version='.urlencode(DOL_VERSION))
);

// We display application title
$application = constant('DOL_APPLICATION_TITLE');
$applicationcustom = getDolGlobalString('MAIN_APPLICATION_TITLE');
if ($applicationcustom) {
	$application = (preg_match('/^\+/', $applicationcustom) ? $application : '').$applicationcustom;
}

// We define login title
if ($applicationcustom) {
	$titleofloginpage = $langs->trans('Login').' '.$application;
} else {
	$titleofloginpage = $langs->trans('Login');
}
// Title of HTML page must have pattern ' @ (?:Doli[a-zA-Z]+ |)(\\d+)\\.(\\d+)\\.([^\\s]+)' to be detected as THE login page by webviews.
$titleofloginpage .= ' @ '.$titletruedolibarrversion; // $titletruedolibarrversion is defined by dol_loginfunction in security2.lib.php. We must keep the @, some tools use it to know it is login page and find true dolibarr version.

$disablenofollow = 1;
if (!preg_match('/'.constant('DOL_APPLICATION_TITLE').'/', $title)) {
	$disablenofollow = 0;
}
if (getDolGlobalString('MAIN_OPTIMIZEFORTEXTBROWSER')) {
	$disablenofollow = 0;
}

// If OpenID Connect is set as an authentication
if (getDolGlobalInt('MAIN_AUTHENTICATION_OIDC_ON', 0) > 0 && isset($conf->file->main_authentication) && preg_match('/openid_connect/', $conf->file->main_authentication)) {
	// Set a cookie to transfer rollback page information
	$prefix = dol_getprefix('');
	if (empty($_COOKIE["DOL_rollback_url_$prefix"])) {
		dolSetCookie('DOL_rollback_url_'.$prefix, $_SERVER['REQUEST_URI'], time() + 3600);	// $_SERVER["REQUEST_URI"] is for example /mydolibarr/mypage.php
	}

	// Auto redirect if OpenID Connect is the only authentication
	if ($conf->file->main_authentication === 'openid_connect') {
		// Avoid redirection hell
		if (empty(GETPOST('openid_mode'))) {
			dol_include_once('/core/lib/openid_connect.lib.php');
			header("Location: " . openid_connect_get_url(), true, 302);
		} elseif (!empty($_SESSION['dol_loginmesg'])) {
			// Show login error without the login form
			print '<div class="center login_main_message"><div class="error">' . dol_escape_htmltag($_SESSION['dol_loginmesg']) . '</div></div>';
		}
		// We shouldn't continue executing this page
		exit();
	}
}

top_htmlhead('', $titleofloginpage, 0, 0, $arrayofjs, array(), 1, $disablenofollow);
?>
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
            background: linear-gradient(
                120deg, 
                transparent, 
                rgba(167,243,208,0.15), 
                transparent
            );
            animation: shine 4s infinite;
        }
    }
    @keyframes shine {
        0% { left: -100%; }
        20% { left: 100%; }
        100% { left: 100%; }
    }
</style>
<?php

$helpcenterlink = getDolGlobalString('MAIN_HELPCENTER_LINKTOUSE');

$colorbackhmenu1 = '60,70,100'; // topmenu
if (!isset($conf->global->THEME_ELDY_TOPMENU_BACK1)) {
	$conf->global->THEME_ELDY_TOPMENU_BACK1 = $colorbackhmenu1;
}
$colorbackhmenu1 = getDolUserString('THEME_ELDY_ENABLE_PERSONALIZED') ? getDolUserString('THEME_ELDY_TOPMENU_BACK1', $colorbackhmenu1) : getDolGlobalString('THEME_ELDY_TOPMENU_BACK1', $colorbackhmenu1);
$colorbackhmenu1 = implode(',', colorStringToArray($colorbackhmenu1)); // Normalize value to 'x,y,z'

print "<!-- BEGIN PHP TEMPLATE LOGIN.TPL.PHP -->\n";

if (getDolGlobalString('ADD_UNSPLASH_LOGIN_BACKGROUND')) {
	// For example $conf->global->ADD_UNSPLASH_LOGIN_BACKGROUND = 'https://source.unsplash.com/random'?>
	<body class="body bodylogin bg-[#0a0a0d] min-h-screen flex items-center justify-center p-4 overflow-hidden relative">
    <div class="absolute inset-0 bg-gradient-to-tr from-emerald-900/10 via-black to-blue-900/10 animate-gradient-x -z-10"></div>
    <div class="absolute top-[-10%] left-[-10%] w-[40%] h-[40%] bg-emerald-500/5 blur-[120px] rounded-full"></div>
    <div class="absolute bottom-[-10%] right-[-10%] w-[40%] h-[40%] bg-blue-500/5 blur-[120px] rounded-full"></div>
	<?php
} else {
	?>
	<body class="body bodylogin bg-[#0a0a0d] min-h-screen flex items-center justify-center p-4 overflow-hidden relative">
    <div class="absolute inset-0 bg-gradient-to-tr from-emerald-900/10 via-black to-blue-900/10 animate-gradient-x -z-10"></div>
	<?php
}
?>

<?php if (empty($conf->dol_use_jmobile)) { ?>
<script>
$(document).ready(function () {
	/* Set focus on correct field */
	<?php if ($focus_element) {
		?>$('#<?php echo $focus_element; ?>').focus(); <?php
	} ?>		// Warning to use this only on visible element
});
</script>
<?php } ?>

<div class="flex flex-col items-center">
<div class="w-full">



<form id="login" name="login" method="post" action="<?php echo $php_self; ?>">

<input type="hidden" name="token" value="<?php echo newToken(); ?>" />
<input type="hidden" name="actionlogin" id="actionlogin" value="login">
<input type="hidden" name="loginfunction" id="loginfunction" value="loginfunction" />
<input type="hidden" name="backtopage" value="<?php echo GETPOST('backtopage'); ?>" />
<!-- Add fields to store and send local user information. This fields are filled by the core/js/dst.js -->
<input type="hidden" name="tz" id="tz" value="" />
<input type="hidden" name="tz_string" id="tz_string" value="" />
<input type="hidden" name="dst_observed" id="dst_observed" value="" />
<input type="hidden" name="dst_first" id="dst_first" value="" />
<input type="hidden" name="dst_second" id="dst_second" value="" />
<input type="hidden" name="screenwidth" id="screenwidth" value="" />
<input type="hidden" name="screenheight" id="screenheight" value="" />
<input type="hidden" name="dol_hide_topmenu" id="dol_hide_topmenu" value="<?php echo $dol_hide_topmenu; ?>" />
<input type="hidden" name="dol_hide_leftmenu" id="dol_hide_leftmenu" value="<?php echo $dol_hide_leftmenu; ?>" />
<input type="hidden" name="dol_optimize_smallscreen" id="dol_optimize_smallscreen" value="<?php echo $dol_optimize_smallscreen; ?>" />
<input type="hidden" name="dol_no_mouse_hover" id="dol_no_mouse_hover" value="<?php echo $dol_no_mouse_hover; ?>" />
<input type="hidden" name="dol_use_jmobile" id="dol_use_jmobile" value="<?php echo $dol_use_jmobile; ?>" />



<!-- Title with version -->
<div class="center text-3d-container" tabindex="-1">
    <div class="animate-fade-in-up">
        <h1 class="text-3d text-5xl md:text-6xl font-black bg-gradient-to-tr from-emerald-400 via-white to-violet-500 bg-clip-text text-transparent tracking-tighter mb-2 pb-2 shine-effect">
            Anderson Informática
        </h1>
        <p class="text-gray-400 text-sm font-medium tracking-widest uppercase mb-8 opacity-60">
            Sistemas de Gestão
        </p>
    </div>
</div>



<div class="glass-panel w-full max-w-sm mx-auto animate-fade-in-up" style="animation-delay: 0.1s">
<div class="hidden">
<img alt="" src="<?php echo $urllogo; ?>" id="img_logo" />
</div>

<br>

<div id="login_right">

<div class="w-full" title="<?php echo $langs->trans("EnterLoginDetail"); ?>">

<!-- Login -->
<?php if (!isset($conf->file->main_authentication) || $conf->file->main_authentication != 'googleoauth') { ?>
<div class="space-y-4">
    <!-- Login -->
    <div class="relative group">
        <label for="username" class="sr-only"><?php echo $langs->trans("Login"); ?></label>
        <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
            <span class="fa fa-user text-emerald-500/50 group-focus-within:text-emerald-400 transition-colors"></span>
        </div>
        <input type="text" id="username" placeholder="<?php echo $langs->trans("Login"); ?>" name="username" class="input-modern pl-11" value="<?php echo dol_escape_htmltag($login); ?>" tabindex="1" autofocus="autofocus" autocapitalize="off" autocomplete="on" />
    </div>

    <!-- Password -->
    <div class="relative group mt-4">
        <label for="password" class="sr-only"><?php echo $langs->trans("Password"); ?></label>
        <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
            <span class="fa fa-key text-emerald-500/50 group-focus-within:text-emerald-400 transition-colors"></span>
        </div>
        <input type="password" id="password" placeholder="<?php echo $langs->trans("Password"); ?>" name="password" class="input-modern pl-11 pr-12" value="<?php echo dol_escape_htmltag($password); ?>" tabindex="2" autocomplete="<?php echo !getDolGlobalString('MAIN_LOGIN_ENABLE_PASSWORD_AUTOCOMPLETE') ? 'off' : 'on'; ?>" />
        <span class="absolute inset-y-0 right-0 pr-4 flex items-center cursor-pointer text-gray-500 hover:text-emerald-400 transition-colors" onclick="const p = document.getElementById('password'); p.type = p.type === 'password' ? 'text' : 'password'; this.querySelector('span').classList.toggle('fa-eye'); this.querySelector('span').classList.toggle('fa-eye-slash');">
            <span class="fa fa-eye"></span>
        </span>
    </div>
</div>
<?php } ?>


<?php
if (!empty($captcha)) {
	// Add a variable param to force not using cache (jmobile)
	$php_self = preg_replace('/[&\?]time=(\d+)/', '', $php_self); // Remove param time
	if (preg_match('/\?/', $php_self)) {
		$php_self .= '&time='.dol_print_date(dol_now(), 'dayhourlog');
	} else {
		$php_self .= '?time='.dol_print_date(dol_now(), 'dayhourlog');
	}

	// List of directories where we can find captcha handlers
	$dirModCaptcha = array_merge(array('main' => '/core/modules/security/captcha/'), (isset($conf->modules_parts['captcha']) && is_array($conf->modules_parts['captcha'])) ? $conf->modules_parts['captcha'] : array());
	$fullpathclassfile = '';
	foreach ($dirModCaptcha as $dir) {
		$fullpathclassfile = dol_buildpath($dir."modCaptcha".ucfirst($captcha).'.class.php', 0, 2);
		if ($fullpathclassfile) {
			break;
		}
	}

	if ($fullpathclassfile) {
		include_once $fullpathclassfile;
		$captchaobj = null;

		// Charging the numbering class
		$classname = "modCaptcha".ucfirst($captcha);
		if (class_exists($classname)) {
			/** @var ModeleCaptcha $captchaobj */
			$captchaobj = new $classname($db, $conf, $langs, null);
			'@phan-var-force ModeleCaptcha $captchaobj';

			if (is_object($captchaobj) && method_exists($captchaobj, 'getCaptchaCodeForForm')) {
				print $captchaobj->getCaptchaCodeForForm($php_self); // @phan-suppress-current-line PhanUndeclaredMethod
			} else {
				print 'Error, the captcha handler '.get_class($captchaobj).' does not have any method getCaptchaCodeForForm()';
			}
		} else {
			print 'Error, the captcha handler class '.$classname.' was not found after the include';
		}
	} else {
		print 'Error, the captcha handler '.$captcha.' has no class file found modCaptcha'.ucfirst($captcha);
	}
}

if (!empty($morelogincontent)) {
	if (is_array($morelogincontent)) {
		foreach ($morelogincontent as $format => $option) {
			if ($format == 'table') {
				echo '<!-- Option by hook -->';
				echo $option;
			}
		}
	} else {
		echo '<!-- Option by hook -->';
		echo $morelogincontent;
	}
}

?>

</div>

</div> <!-- end div login_right -->

</div> <!-- end div login_line1 -->


<div id="login_line2" style="clear: both">


<!-- Button Connection -->
<?php if (!isset($conf->file->main_authentication) || $conf->file->main_authentication != 'googleoauth') { ?>
<div class="mt-10 text-center">
    <input type="submit" class="btn-primary cursor-pointer px-12" value="<?php echo $langs->trans('Connection'); ?>" tabindex="5" />
</div>
<?php } ?>


<?php
if (isset($conf->file->main_authentication) && $conf->file->main_authentication == 'googleoauth') {
	$forgetpasslink = '';
}

if ($forgetpasslink || $helpcenterlink) {
	$moreparam = '';
	if ($dol_hide_topmenu) {
		$moreparam .= (strpos($moreparam, '?') === false ? '?' : '&').'dol_hide_topmenu='.$dol_hide_topmenu;
	}
	if ($dol_hide_leftmenu) {
		$moreparam .= (strpos($moreparam, '?') === false ? '?' : '&').'dol_hide_leftmenu='.$dol_hide_leftmenu;
	}
	if ($dol_no_mouse_hover) {
		$moreparam .= (strpos($moreparam, '?') === false ? '?' : '&').'dol_no_mouse_hover='.$dol_no_mouse_hover;
	}
	if ($dol_use_jmobile) {
		$moreparam .= (strpos($moreparam, '?') === false ? '?' : '&').'dol_use_jmobile='.$dol_use_jmobile;
	}

	echo '<br>';
	echo '<div class="flex flex-col items-center gap-3 mt-6 border-t border-white/5 pt-6">';
	if ($forgetpasslink) {
		$url = DOL_URL_ROOT.'/user/passwordforgotten.php'.$moreparam;
		if (getDolGlobalString('MAIN_PASSWORD_FORGOTLINK')) {
			$url = getDolGlobalString('MAIN_PASSWORD_FORGOTLINK');
		}
		echo '<a class="text-xs text-emerald-400/70 hover:text-emerald-400 transition-colors uppercase font-bold tracking-widest" href="'.dol_escape_htmltag($url).'">';
		echo $langs->trans('PasswordForgotten');
		echo '</a>';
	}

	if ($helpcenterlink) {
		echo '<a class="text-xs text-emerald-400/70 hover:text-emerald-400 transition-colors uppercase font-bold tracking-widest" href="'.dol_escape_htmltag($helpcenterlink).'" target="_blank" rel="noopener noreferrer">';
		echo $langs->trans('NeedHelpCenter');
		echo '</a>';
	}
	echo '</div>';
}

if (getDolGlobalInt('MAIN_AUTHENTICATION_OIDC_ON', 0) > 0 && isset($conf->file->main_authentication) && preg_match('/openid/', $conf->file->main_authentication)) {
	dol_include_once('/core/lib/openid_connect.lib.php');
	$langs->load("users");

	print '<div class="center" style="margin-top: 20px; margin-bottom: 10px">';

	if (!getDolGlobalString("MAIN_AUTHENTICATION_OPENID_URL")) {
		$url = openid_connect_get_url();
	} else {
		$url = getDolGlobalString('MAIN_AUTHENTICATION_OPENID_URL').'&state=' . openid_connect_get_state();
	}

	if (!empty($url)) {
		print '<a class="alogin" href="'.$url.'">';
		print '<div class="loginbuttonexternal">';
		print $langs->trans("LoginUsingOpenID");
		print '</div>';
		print '</a>';
	} else {
		$langs->load("errors");
		print '<div class="loginbuttonexternal">';
		print '<span class="warning">'.$langs->trans("ErrorOpenIDSetupNotComplete", 'MAIN_AUTHENTICATION_OPENID_URL').'</span>';
		print '</div>';
	}

	print '</div>';
}

if (isset($conf->file->main_authentication) && preg_match('/google/', $conf->file->main_authentication) && strpos($conf->browser->ua, 'DoliDroid') === false) {
	$langs->load("users");

	echo '<div class="center" style="margin-top: 20px; margin-bottom: 10px">';

	/*global $dolibarr_main_url_root;

	// Define $urlwithroot
	$urlwithouturlroot = preg_replace('/'.preg_quote(DOL_URL_ROOT, '/').'$/i', '', trim($dolibarr_main_url_root));
	$urlwithroot = $urlwithouturlroot.DOL_URL_ROOT; // This is to use external domain name found into config file
	//$urlwithroot=DOL_MAIN_URL_ROOT;					// This is to use same domain name than current

	//$shortscope = 'userinfo_email,userinfo_profile';
	$shortscope = 'openid,email,profile';	// For openid connect

	$oauthstateanticsrf = bin2hex(random_bytes(128/8));
	$_SESSION['oauthstateanticsrf'] = $shortscope.'-'.$oauthstateanticsrf;
	$urltorenew = $urlwithroot.'/core/modules/oauth/google_oauthcallback.php?shortscope='.$shortscope.'&state=forlogin-'.$shortscope.'-'.$oauthstateanticsrf;

	//$url = $urltorenew;
	 */

	print '<input type="hidden" name="beforeoauthloginredirect" id="beforeoauthloginredirect" value="">';
	print '<a class="alogin" href="#" onclick="console.log(\'Set beforeoauthloginredirect value\'); jQuery(\'#beforeoauthloginredirect\').val(\'google\'); $(this).closest(\'form\').submit(); return false;">';
	print '<div class="loginbuttonexternal">';
	print img_picto('', 'google', 'class="pictofixedwidth"');
	print $langs->trans("LoginWith", "Google");
	print '</div>';
	print '</a>';
	print '</div>';
}

?>

</div> <!-- end login table / glass-panel -->


</form>


<?php
$message = '';
// Show error message if defined
if (!empty($_SESSION['dol_loginmesg'])) {
	$message = $_SESSION['dol_loginmesg'];	// By default this is an error message
}
if (!empty($message)) {
	if (!empty($conf->use_javascript_ajax)) {
		if (preg_match('/<!-- warning -->/', $message)) {	// if it contains this comment, this is a warning message
			$message = str_replace('<!-- warning -->', '', $message);
			dol_htmloutput_mesg($message, array(), 'warning');
		} else {
			dol_htmloutput_mesg($message, array(), 'error');
		}
		print '<script>
			$(document).ready(function() {
				$(".jnotify-container").addClass("jnotify-container-login");
			});
		</script>';
	} else {
		?>
		<div class="center login_main_message">
		<?php
		if (preg_match('/<!-- warning -->/', $message)) {	// if it contains this comment, this is a warning message
			$message = str_replace('<!-- warning -->', '', $message);
			print '<div class="warning" role="alert">';
		} else {
			print '<div class="error" role="alert">';
		}
		print dol_escape_htmltag($message);
		print '</div>'; ?>
		</div>
		<?php
	}
}

// Add commit strip
if (getDolGlobalString('MAIN_EASTER_EGG_COMMITSTRIP')) {
	include_once DOL_DOCUMENT_ROOT.'/core/lib/geturl.lib.php';
	if (substr($langs->defaultlang, 0, 2) == 'fr') {
		$resgetcommitstrip = getURLContent("https://www.commitstrip.com/fr/feed/");
	} else {
		$resgetcommitstrip = getURLContent("https://www.commitstrip.com/en/feed/");
	}
	if ($resgetcommitstrip && $resgetcommitstrip['http_code'] == '200') {
		if (LIBXML_VERSION < 20900) {
			// Avoid load of external entities (security problem).
			// Required only if LIBXML_VERSION < 20900
			// @phan-suppress-next-line PhanDeprecatedFunctionInternal
			libxml_disable_entity_loader(true);
		}

		$xml = simplexml_load_string($resgetcommitstrip['content'], 'SimpleXMLElement', LIBXML_NOCDATA | LIBXML_NONET);
		// @phan-suppress-next-line PhanPluginUnknownObjectMethodCall
		$little = $xml->channel->item[0]->children('content', true);
		print preg_replace('/width="650" height="658"/', '', $little->encoded);
	}
}

?>

<?php if ($main_home) {
	?>
	<div class="center login_main_home paddingtopbottom <?php echo !getDolGlobalString('MAIN_LOGIN_BACKGROUND') ? '' : ' backgroundsemitransparent boxshadow'; ?>" style="max-width: 70%">
	<?php echo $main_home; ?>
	</div><br>
	<?php
}
?>

<!-- authentication mode = <?php echo $main_authentication ?> -->
<!-- cookie name used for this session = <?php echo $session_name ?> -->
<!-- urlfrom in this session = <?php echo isset($_SESSION["urlfrom"]) ? $_SESSION["urlfrom"] : ''; ?> -->

<!-- Common footer is not used for login page, this is same than footer but inside login tpl -->

<?php

print getDolGlobalString('MAIN_HTML_FOOTER');

if (!empty($morelogincontent) && is_array($morelogincontent)) {
	foreach ($morelogincontent as $format => $option) {
		if ($format == 'js') {
			echo "\n".'<!-- Javascript by hook -->';
			echo $option."\n";
		}
	}
} elseif (!empty($moreloginextracontent)) {
	echo '<!-- Javascript by hook -->';
	echo $moreloginextracontent;
}

// Can add extra content
$parameters = array();
$dummyobject = new stdClass();
$hookmanager->executeHooks('getLoginPageExtraContent', $parameters, $dummyobject, $action);
print $hookmanager->resPrint;

?>


</div>
</div><!-- end of center / tailwind flex -->


</body>
</html>
<!-- END PHP TEMPLATE -->
