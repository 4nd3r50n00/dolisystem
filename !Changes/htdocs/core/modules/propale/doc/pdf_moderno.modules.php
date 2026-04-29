<?php
/* Copyright (C) 2025 Your Name <your.email@example.com>
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
 * along with this program. If not, see https://www.gnu.org/licenses/.
 * or see https://www.gnu.org/
 */

/**
 *	\file       htdocs/core/modules/propale/doc/pdf_moderno.modules.php
 *	\ingroup    propale
 *	\brief      File of Class to generate PDF proposal with Moderno template
 */

require_once DOL_DOCUMENT_ROOT.'/core/modules/propale/modules_propale.php';
require_once DOL_DOCUMENT_ROOT.'/product/class/product.class.php';
require_once DOL_DOCUMENT_ROOT.'/core/lib/company.lib.php';
require_once DOL_DOCUMENT_ROOT.'/core/lib/functions2.lib.php';
require_once DOL_DOCUMENT_ROOT.'/core/lib/pdf.lib.php';


/**
 *	Class to generate PDF proposal Moderno
 */
class pdf_moderno extends ModelePDFPropales
{
	/**
	 * @var DoliDB Database handler
	 */
	public $db;

	/**
	 * @var int The environment ID when using a multicompany module
	 */
	public $entity;

	/**
	 * @var string model name
	 */
	public $name;

	/**
	 * @var string model description (short text)
	 */
	public $description;

	/**
	 * @var int	Save the name of generated file as the main doc when generating a doc with this template
	 */
	public $update_main_doc_field;

	/**
	 * @var string document type
	 */
	public $type;

	/**
	 * Dolibarr version of the loaded document
	 * @var string Version, possible values are: 'development', 'experimental', 'dolibarr', 'dolibarr_deprecated' or a version string like 'x.y.z'''
	 */
	public $version = 'dolibarr';


	/**
	 *	Constructor
	 *
	 *  @param		DoliDB		$db      Database handler
	 */
	public function __construct($db)
	{
		global $langs, $mysoc;

		// Translations
		$langs->loadLangs(array("main", "bills"));

		$this->db = $db;
		$this->name = "moderno";
		$this->description = $langs->trans('DocModelModernoDescription');
		$this->update_main_doc_field = 1;

		// Dimension page
		$this->type = 'pdf';
		$formatarray = pdf_getFormat();
		$this->page_largeur = $formatarray['width'];
		$this->page_hauteur = $formatarray['height'];
		$this->format = array($this->page_largeur, $this->page_hauteur);
		$this->marge_gauche = getDolGlobalInt('MAIN_PDF_MARGIN_LEFT', 10);
		$this->marge_droite = getDolGlobalInt('MAIN_PDF_MARGIN_RIGHT', 10);
		$this->marge_haute = getDolGlobalInt('MAIN_PDF_MARGIN_TOP', 10);
		$this->marge_basse = getDolGlobalInt('MAIN_PDF_MARGIN_BOTTOM', 10);
		$this->corner_radius = getDolGlobalInt('MAIN_PDF_FRAME_CORNER_RADIUS', 2);
		$this->option_logo = 1;
		$this->option_tva = 1;
		$this->option_modereg = 1;
		$this->option_condreg = 1;
		$this->option_multilang = 1;
		$this->option_escompte = 0;
		$this->option_credit_note = 0;
		$this->option_freetext = 1;
		$this->option_draft_watermark = 1;
		$this->watermark = '';

		// Colors for modern design
		$this->primary_color = array(41, 128, 185);      // Modern blue
		$this->secondary_color = array(236, 240, 241);   // Light gray
		$this->accent_color = array(52, 73, 94);          // Dark slate
		$this->text_color = array(44, 62, 80);          // Dark text
		$this->light_bg = array(248, 249, 250);          // Very light background

		// Define position of columns
		$this->posxdesc = $this->marge_gauche + 1;
		if (getDolGlobalInt('PRODUCT_USE_UNITS')) {
			$this->posxtva = 90;
			$this->posxup = 113;
			$this->posxqty = 131;
			$this->posxunit = 148;
		} else {
			$this->posxtva = 100;
			$this->posxup = 125;
			$this->posxqty = 146;
			$this->posxunit = 162;
		}
		$this->posxdiscount = 162;
		$this->postotalht = 174;
		if (getDolGlobalString('MAIN_GENERATE_DOCUMENTS_WITHOUT_VAT') || getDolGlobalString('MAIN_GENERATE_DOCUMENTS_WITHOUT_VAT_COLUMN')) {
			$this->posxtva = $this->posxup;
		}
		$this->posxpicture = $this->posxtva; // reclaimed space since no photos are used
		if ($this->page_largeur < 210) {
			$this->posxpicture -= 20;
			$this->posxtva -= 20;
			$this->posxup -= 20;
			$this->posxqty -= 20;
			$this->posxunit -= 20;
			$this->posxdiscount -= 20;
			$this->postotalht -= 20;
		}

		$this->tva = array();
		$this->tva_array = array();
		$this->localtax1 = array();
		$this->localtax2 = array();
		$this->atleastoneratenotnull = 0;
		$this->atleastonediscount = 0;

		if ($mysoc === null) {
			dol_syslog(get_class($this).'::__construct() Global $mysoc should not be null.'. getCallerInfoString(), LOG_ERR);
			return;
		}

		$this->emetteur = $mysoc;
		if (empty($this->emetteur->country_code)) {
			$this->emetteur->country_code = substr($langs->defaultlang, -2);
		}
	}

	// phpcs:disable PEAR.NamingConventions.ValidFunctionName.ScopeNotCamelCaps
	/**
	 *  Function to build pdf onto disk
	 *
	 *  @param		Propal		$object				Object to generate
	 *  @param		?Translate	$outputlangs		Lang output object
	 *  @param		string		$srctemplatepath	Full path of source filename for generator using a template file
	 *  @param		int<0,1>	$hidedetails		Do not show line details
	 *  @param		int<0,1>	$hidedesc			Do not show desc
	 *  @param		int<0,1>	$hideref			Do not show ref
	 *  @return		int<-1,1>						1 if OK, <=0 if KO
	 */
	public function write_file($object, $outputlangs, $srctemplatepath = '', $hidedetails = 0, $hidedesc = 0, $hideref = 0)
	{
		// phpcs:enable
		global $user, $langs, $conf, $mysoc, $db, $hookmanager, $nblines;

		dol_syslog("write_file outputlangs->defaultlang=".(is_object($outputlangs) ? $outputlangs->defaultlang : 'null'));

		if (!is_object($outputlangs)) {
			$outputlangs = $langs;
		}
		if (getDolGlobalString('MAIN_USE_FPDF')) {
			$outputlangs->charset_output = 'ISO-8859-1';
		}

		// Load translation files required by page
		$langfiles = array("main", "dict", "companies", "bills", "propal", "products", "compta");
		$outputlangs->loadLangs($langfiles);

		global $outputlangsbis;
		$outputlangsbis = null;
		if (getDolGlobalString('PDF_USE_ALSO_LANGUAGE_CODE') && $outputlangs->defaultlang != getDolGlobalString('PDF_USE_ALSO_LANGUAGE_CODE')) {
			$outputlangsbis = new Translate('', $conf);
			$outputlangsbis->setDefaultLang(getDolGlobalString('PDF_USE_ALSO_LANGUAGE_CODE'));
			$outputlangsbis->loadLangs($langfiles);
		}

		// Show Draft Watermark
		if ($object->statut == $object::STATUS_DRAFT && getDolGlobalString('PROPALE_DRAFT_WATERMARK')) {
			$this->watermark = getDolGlobalString('PROPALE_DRAFT_WATERMARK');
		}

		$nblines = count($object->lines);

		// Loop on each lines to detect if there is at least one image to show
		$realpatharray = array();
		$this->atleastonephoto = false;
		if (getDolGlobalString('MAIN_GENERATE_PROPOSALS_WITH_PICTURE')) {
			$objphoto = new Product($this->db);

			for ($i = 0; $i < $nblines; $i++) {
				if (empty($object->lines[$i]->fk_product)) {
					continue;
				}

				$objphoto->fetch($object->lines[$i]->fk_product);
				$pdir = array();
				if (getDolGlobalInt('PRODUCT_USE_OLD_PATH_FOR_PHOTO')) {
					$pdir[0] = get_exdir($objphoto->id, 2, 0, 0, $objphoto, 'product').$objphoto->id."/photos/";
					$pdir[1] = get_exdir(0, 0, 0, 0, $objphoto, 'product').dol_sanitizeFileName($objphoto->ref).'/';
				} else {
					$pdir[0] = get_exdir(0, 0, 0, 0, $objphoto, 'product');
					$pdir[1] = get_exdir($objphoto->id, 2, 0, 0, $objphoto, 'product').$objphoto->id."/photos/";
				}

				$arephoto = false;
				$realpath = '';
				foreach ($pdir as $midir) {
					if (!$arephoto) {
						$entity = $objphoto->entity;
						if ($entity !== null && $conf->entity != $entity) {
							$dir = $conf->product->multidir_output[$entity].'/'.$midir;
						} else {
							$dir = $conf->product->dir_output.'/'.$midir;
						}
						foreach ($objphoto->liste_photos($dir, 1) as $key => $obj) {
							if (!getDolGlobalInt('CAT_HIGH_QUALITY_IMAGES')) {
								if ($obj['photo_vignette']) {
									$filename = $obj['photo_vignette'];
								} else {
									$filename = $obj['photo'];
								}
							} else {
								$filename = $obj['photo'];
							}

							$realpath = $dir.$filename;
							$arephoto = true;
							$this->atleastonephoto = true;
						}
					}
				}

				if ($realpath && $arephoto) {
					$realpatharray[$i] = $realpath;
				}
			}
		}

		if (count($realpatharray) == 0) {
			$this->posxpicture = $this->posxtva;
		}

		if ($conf->propal->multidir_output[$conf->entity]) {
			$object->fetch_thirdparty();

			$deja_regle = 0;

			// Definition of $dir and $file
			if ($object->specimen) {
				$dir = $conf->propal->multidir_output[$conf->entity];
				$file = $dir."/SPECIMEN.pdf";
			} else {
				$objectref = dol_sanitizeFileName($object->ref);
				$dir = $conf->propal->multidir_output[$object->entity ?? $conf->entity]."/".$objectref;
				$file = $dir."/".$objectref.".pdf";
			}

			if (!file_exists($dir)) {
				if (dol_mkdir($dir) < 0) {
					$this->error = $langs->transnoentities("ErrorCanNotCreateDir", $dir);
					return 0;
				}
			}

			if (file_exists($dir)) {
				// Add pdfgeneration hook
				if (!is_object($hookmanager)) {
					include_once DOL_DOCUMENT_ROOT.'/core/class/hookmanager.class.php';
					$hookmanager = new HookManager($this->db);
				}
				$hookmanager->initHooks(array('pdfgeneration'));
				$parameters = array('file' => $file, 'object' => $object, 'outputlangs' => $outputlangs);
				global $action;
				$reshook = $hookmanager->executeHooks('beforePDFCreation', $parameters, $object, $action);

				// Set nblines with the new content of lines after hook
				$nblines = count($object->lines);

				// Create pdf instance
				$pdf = pdf_getInstance($this->format);
				$default_font_size = pdf_getPDFFontSize($outputlangs);
				$pdf->setAutoPageBreak(true, 0);

				if (class_exists('TCPDF')) {
					$pdf->setPrintHeader(false);
					$pdf->setPrintFooter(false);
				}
				$pdf->SetFont(pdf_getPDFFont($outputlangs));
				// Set path to the background PDF File
				if (getDolGlobalString('MAIN_ADD_PDF_BACKGROUND')) {
					$logodir = $conf->mycompany->dir_output;
					if (!empty($conf->mycompany->multidir_output[$object->entity ?? $conf->entity])) {
						$logodir = $conf->mycompany->multidir_output[$object->entity ?? $conf->entity];
					}
					$pagecount = $pdf->setSourceFile($logodir.'/' . getDolGlobalString('MAIN_ADD_PDF_BACKGROUND'));
					$tplidx = $pdf->importPage(1);
				}

				$pdf->Open();
				$pagenb = 0;
				$pdf->SetDrawColor(128, 128, 128);

				$pdf->SetTitle($outputlangs->convToOutputCharset($object->ref));
				$pdf->SetSubject($outputlangs->transnoentities("PdfCommercialProposalTitle"));
				$pdf->SetCreator("Dolibarr ".DOL_VERSION);
				$pdf->SetAuthor($outputlangs->convToOutputCharset($user->getFullName($outputlangs)));
				$pdf->SetKeyWords($outputlangs->convToOutputCharset($object->ref)." ".$outputlangs->transnoentities("PdfCommercialProposalTitle")." ".$outputlangs->convToOutputCharset($object->thirdparty->name));
				if (getDolGlobalString('MAIN_DISABLE_PDF_COMPRESSION')) {
					$pdf->SetCompression(false);
				}

				$pdf->SetMargins($this->marge_gauche, $this->marge_haute, $this->marge_droite);

				// Set $this->atleastonediscount if you have at least one discount
				for ($i = 0; $i < $nblines; $i++) {
					if ($object->lines[$i]->remise_percent) {
						$this->atleastonediscount++;
					}
				}
				if (empty($this->atleastonediscount)) {
					$delta = ($this->postotalht - $this->posxdiscount);
					$this->posxpicture += $delta;
					$this->posxtva += $delta;
					$this->posxup += $delta;
					$this->posxqty += $delta;
					$this->posxunit += $delta;
					$this->posxdiscount += $delta;
				}

				// New page
				$pdf->AddPage();
				if (!empty($tplidx)) {
					$pdf->useTemplate($tplidx);
				}
				$pagenb++;

				$heightforinfotot = 40;
				$heightforsignature = !getDolGlobalString('PROPAL_DISABLE_SIGNATURE') ? 60 : 0; // 60mm reserved: 4mm label + 40mm box + 16mm margin/footer gap
				$heightforfreetext = getDolGlobalInt('MAIN_PDF_FREETEXT_HEIGHT', 5);
				$heightforfooter = $this->marge_basse + 8;
				if (getDolGlobalString('MAIN_GENERATE_DOCUMENTS_SHOW_FOOT_DETAILS')) {
					$heightforfooter += 6;
				}

				$top_shift = $this->_pagehead($pdf, $object, 1, $outputlangs, $outputlangsbis);
				$pdf->SetFont('', '', $default_font_size - 1);
				$pdf->MultiCell(0, 3, '');
				$pdf->SetTextColor(0, 0, 0);

				$tab_top = 95 + $top_shift;
				$tab_top_newpage = (!getDolGlobalInt('MAIN_PDF_DONOTREPEAT_HEAD') ? 42 + $top_shift : 10);

				// Incoterm
				$height_incoterms = 0;
				if (isModEnabled('incoterm')) {
					$desc_incoterms = $object->getIncotermsForPDF();
					if ($desc_incoterms) {
						$tab_top -= 2;

						$pdf->SetFont('', '', $default_font_size - 1);
						$pdf->writeHTMLCell(190, 3, $this->posxdesc - 1, $tab_top - 1, dol_htmlentitiesbr($desc_incoterms), 0, 1);
						$nexY = $pdf->GetY();
						$height_incoterms = $nexY - $tab_top;

						$pdf->SetDrawColor(192, 192, 192);
						$pdf->RoundedRect($this->marge_gauche, $tab_top - 1, $this->page_largeur - $this->marge_gauche - $this->marge_droite, $height_incoterms + 3, $this->corner_radius, '1234', 'D');

						$tab_top = $nexY + 6;
						$height_incoterms += 4;
					}
				}

				// Displays notes
				$notetoshow = empty($object->note_public) ? '' : $object->note_public;
				if (getDolGlobalString('MAIN_ADD_SALE_REP_SIGNATURE_IN_NOTE')) {
					if (is_object($object->thirdparty)) {
						$salereparray = $object->thirdparty->getSalesRepresentatives($user);
						$salerepobj = new User($this->db);
						$salerepobj->fetch($salereparray[0]['id']);
						if (!empty($salerepobj->signature)) {
							$notetoshow = dol_concatdesc($notetoshow, $salerepobj->signature);
						}
					}
				}
				$extranote = $this->getExtrafieldsInHtml($object, $outputlangs);
				if (!empty($extranote)) {
					$notetoshow = dol_concatdesc((string) $notetoshow, $extranote);
				}
				if (getDolGlobalString('MAIN_ADD_CREATOR_IN_NOTE') && $object->user_author_id > 0) {
					$tmpuser = new User($this->db);
					$tmpuser->fetch($object->user_author_id);

					$creator_info = $langs->trans("CaseFollowedBy").' '.$tmpuser->getFullName($langs);
					if ($tmpuser->email) {
						$creator_info .= ',  '.$langs->trans("EMail").': '.$tmpuser->email;
					}
					if ($tmpuser->office_phone) {
						$creator_info .= ', '.$langs->trans("Phone").': '.$tmpuser->office_phone;
					}

					$notetoshow = dol_concatdesc((string) $notetoshow, $creator_info);
				}

				if ($notetoshow) {
					$tab_top -= 2;

					$substitutionarray = pdf_getSubstitutionArray($outputlangs, null, $object);
					complete_substitutions_array($substitutionarray, $outputlangs, $object);
					$notetoshow = make_substitutions($notetoshow, $substitutionarray, $outputlangs);
					$notetoshow = convertBackOfficeMediasLinksToPublicLinks($notetoshow);

					$pdf->SetFont('', '', $default_font_size - 1);
					$pdf->writeHTMLCell(190, 3, $this->posxdesc - 1, $tab_top - 1, dol_htmlentitiesbr($notetoshow), 0, 1);
					$nexY = $pdf->GetY();
					$height_note = $nexY - $tab_top;

					$pdf->SetDrawColor(192, 192, 192);
					$pdf->RoundedRect($this->marge_gauche, $tab_top - 1, $this->page_largeur - $this->marge_gauche - $this->marge_droite, $height_note + 2, $this->corner_radius, '1234', 'D');

					$tab_top = $nexY + 6;
				}

				$this->_tableau($pdf, $tab_top, $this->page_hauteur - $tab_top - $heightforfooter, 1, $outputlangs, 0, $object->multicurrency_code);

				$iniY = $tab_top + 13;
				$curY = $tab_top + 13;

				// Draw the "Bridge" lines from the bottom of the blue header (tab_top + 10) to the start of items (tab_top + 13)
				$pdf->SetLineStyle(array('dash' => '1,1', 'color' => array(100, 100, 100)));
				$bridgeS = $tab_top + 10;
				$bridgeE = $tab_top + 13;
				$pdf->line($this->posxtva - 0.5, $bridgeS, $this->posxtva - 0.5, $bridgeE);
				if (!getDolGlobalString('MAIN_GENERATE_DOCUMENTS_WITHOUT_VAT') && !getDolGlobalString('MAIN_GENERATE_DOCUMENTS_WITHOUT_VAT_COLUMN')) {
					$pdf->line($this->posxup - 0.5, $bridgeS, $this->posxup - 0.5, $bridgeE);
				}
				$pdf->line($this->posxqty - 0.5, $bridgeS, $this->posxqty - 0.5, $bridgeE);
				if (getDolGlobalInt('PRODUCT_USE_UNITS') && $this->posxunit < $this->posxdiscount) {
					$pdf->line($this->posxunit - 0.5, $bridgeS, $this->posxunit - 0.5, $bridgeE);
				}
				$pdf->line($this->posxdiscount - 0.5, $bridgeS, $this->posxdiscount - 0.5, $bridgeE);
				$pdf->line($this->postotalht - 0.5, $bridgeS, $this->postotalht - 0.5, $bridgeE);
				$nexY = $tab_top + 13;

				// Loop on each lines
				for ($i = 0; $i < $nblines; $i++) {
					$curY = $nexY;
					$pdf->SetFont('', '', $default_font_size - 1);
					$pdf->SetTextColor(0, 0, 0);

					// Define size of image if we need it
					$imglinesize = array();
					if (!empty($realpatharray[$i])) {
						$imglinesize = pdf_getSizeForImage($realpatharray[$i]);
					}

					$pdf->setTopMargin($tab_top_newpage);
					$pageposbefore = $pdf->getPage();

					$showpricebeforepagebreak = 1;
					$posYAfterImage = 0;
					$posYAfterDescription = 0;

					// We start with Photo of product line
					if (isset($imglinesize['width']) && isset($imglinesize['height']) && ($curY + $imglinesize['height']) > ($this->page_hauteur - ($heightforfooter + $heightforfreetext + $heightforsignature + $heightforinfotot))) {
						$pdf->AddPage('', '', true);
						if (!empty($tplidx)) {
							$pdf->useTemplate($tplidx);
						}
						if (!getDolGlobalInt('MAIN_PDF_DONOTREPEAT_HEAD')) {
							$this->_pagehead($pdf, $object, 0, $outputlangs);
						}
						$pdf->setPage($pageposbefore + 1);

						$curY = $tab_top_newpage;

						if (getDolGlobalString('MAIN_PDF_DATA_ON_FIRST_PAGE')) {
							$showpricebeforepagebreak = 1;
						} else {
							$showpricebeforepagebreak = 0;
						}
					}

					if (isset($imglinesize['width']) && isset($imglinesize['height'])) {
						$curX = $this->posxpicture - 1;
						$pdf->Image($realpatharray[$i], $curX + (($this->posxtva - $this->posxpicture - $imglinesize['width']) / 2), $curY, $imglinesize['width'], $imglinesize['height'], '', '', '', 2, 300);
						$posYAfterImage = $curY + $imglinesize['height'];
					}

					// Description of product line
					$curX = $this->posxdesc - 1;

					$pdf->startTransaction();
					$pdf->SetFont('', 'B', $default_font_size - 1);
					$label = $object->lines[$i]->label;
					if (empty($label) && !empty($object->lines[$i]->fk_product)) {
						$prod = new Product($this->db);
						$prod->fetch($object->lines[$i]->fk_product);
						$label = $prod->label;
					}
					$pdf->writeHTMLCell($this->posxtva - $this->posxdesc, 4, $curX, $curY, "<b>".dol_strtoupper($label)."</b>", 0, 1);
					$curY_after_title = $pdf->GetY();
					$pdf->SetFont('', '', $default_font_size - 1);
					pdf_writelinedesc($pdf, $object, $i, $outputlangs, $this->posxtva - $this->posxdesc, 3, $curX, $curY_after_title, 1, 0);
					$pageposafter = $pdf->getPage();
					if ($pageposafter > $pageposbefore) {
						$pdf->rollbackTransaction(true);
						$pageposafter = $pageposbefore;
						$pdf->setPageOrientation('', true, $heightforfooter);
						pdf_writelinedesc($pdf, $object, $i, $outputlangs, $this->posxtva - $this->posxdesc, 3, $curX, $curY, $hideref, $hidedesc);

						$pageposafter = $pdf->getPage();
						$posyafter = $pdf->GetY();
						if ($posyafter > ($this->page_hauteur - ($heightforfooter + $heightforfreetext + $heightforsignature + $heightforinfotot))) {
							if ($i == ($nblines - 1)) {
								$pdf->AddPage('', '', true);
								if (!empty($tplidx)) {
									$pdf->useTemplate($tplidx);
								}
								if (!getDolGlobalInt('MAIN_PDF_DONOTREPEAT_HEAD')) {
									$this->_pagehead($pdf, $object, 0, $outputlangs);
								}
								$pdf->setPage($pageposafter + 1);
							}
						} else {
							if (getDolGlobalString('MAIN_PDF_DATA_ON_FIRST_PAGE')) {
								$showpricebeforepagebreak = 1;
							} else {
								$showpricebeforepagebreak = 0;
							}
						}
					} else {
						$pdf->commitTransaction();
					}
					$posYAfterDescription = $pdf->GetY();

					$nexY = $pdf->GetY();
					$pageposafter = $pdf->getPage();

					$pdf->setPage($pageposbefore);
					$pdf->setTopMargin($this->marge_haute);

					if ($pageposafter > $pageposbefore && empty($showpricebeforepagebreak)) {
						$pdf->setPage($pageposafter);
						$curY = $tab_top_newpage;
					}

					$pdf->SetFont('', '', $default_font_size - 1);

					// VAT Rate
					if (!getDolGlobalString('MAIN_GENERATE_DOCUMENTS_WITHOUT_VAT') && !getDolGlobalString('MAIN_GENERATE_DOCUMENTS_WITHOUT_VAT_COLUMN')) {
						$vat_rate = pdf_getlinevatrate($object, $i, $outputlangs, $hidedetails);
						$pdf->SetXY($this->posxtva, $curY);
						$pdf->MultiCell($this->posxup - $this->posxtva, 3, $vat_rate, 0, 'C');
					}

					// Unit price before discount
					$up_excl_tax = pdf_getlineupexcltax($object, $i, $outputlangs, $hidedetails);
					$pdf->SetXY($this->posxup, $curY);
					$pdf->MultiCell($this->posxqty - $this->posxup, 3, $up_excl_tax, 0, 'C', false);

					// Quantity
					$qty = pdf_getlineqty($object, $i, $outputlangs, $hidedetails);
					$pdf->SetXY($this->posxqty, $curY);
					$pdf->MultiCell($this->posxunit - $this->posxqty, 4, $qty, 0, 'C');

					// Unit
					if (getDolGlobalInt('PRODUCT_USE_UNITS')) {
						$unit = pdf_getlineunit($object, $i, $outputlangs, $hidedetails);
						$pdf->SetXY($this->posxunit, $curY);
						$pdf->MultiCell($this->posxdiscount - $this->posxunit, 4, $unit, 0, 'C');
					}

					// Discount on line
					$pdf->SetXY($this->posxdiscount, $curY);
					if ($object->lines[$i]->remise_percent) {
						$remise_percent = pdf_getlineremisepercent($object, $i, $outputlangs, $hidedetails);
						$pdf->MultiCell($this->postotalht - $this->posxdiscount, 3, $remise_percent, 0, 'C');
					}

					// Total HT line
					$total_excl_tax = pdf_getlinetotalexcltax($object, $i, $outputlangs, $hidedetails);
					$pdf->SetXY($this->postotalht, $curY);
					$pdf->MultiCell($this->page_largeur - $this->marge_droite - $this->postotalht, 3, $total_excl_tax, 0, 'C', false);

					// Vertical dotted dividers for the row
					$pdf->SetLineStyle(array('dash' => '1,1', 'color' => array(100, 100, 100)));
					$pdf->line($this->posxtva - 0.5, $curY, $this->posxtva - 0.5, $nexY);
					if (!getDolGlobalString('MAIN_GENERATE_DOCUMENTS_WITHOUT_VAT') && !getDolGlobalString('MAIN_GENERATE_DOCUMENTS_WITHOUT_VAT_COLUMN')) {
						$pdf->line($this->posxup - 0.5, $curY, $this->posxup - 0.5, $nexY);
					}
					$pdf->line($this->posxqty - 0.5, $curY, $this->posxqty - 0.5, $nexY);
					$pdf->line($this->posxunit - 0.5, $curY, $this->posxunit - 0.5, $nexY);
					if (getDolGlobalInt('PRODUCT_USE_UNITS')) {
						$pdf->line($this->posxunit - 0.5, $curY, $this->posxunit - 0.5, $nexY);
					}
					if ($this->atleastonediscount) {
						$pdf->line($this->posxdiscount - 0.5, $curY, $this->posxdiscount - 0.5, $nexY);
						$pdf->line($this->postotalht - 0.5, $curY, $this->postotalht - 0.5, $nexY);
					}
					$pdf->SetLineStyle(array('dash' => 0));

					// Collecte des totaux par valeur de tva
					if (isModEnabled("multicurrency") && $object->multicurrency_tx != 1) {
						$tvaligne = $object->lines[$i]->multicurrency_total_tva;
					} else {
						$tvaligne = $object->lines[$i]->total_tva;
					}

					$localtax1ligne = $object->lines[$i]->total_localtax1;
					$localtax2ligne = $object->lines[$i]->total_localtax2;
					$localtax1_rate = $object->lines[$i]->localtax1_tx;
					$localtax2_rate = $object->lines[$i]->localtax2_tx;
					$localtax1_type = $object->lines[$i]->localtax1_type;
					$localtax2_type = $object->lines[$i]->localtax2_type;

					$vatrate = (string) $object->lines[$i]->tva_tx;

					if ((!isset($localtax1_type) || $localtax1_type == '' || !isset($localtax2_type) || $localtax2_type == '')
					&& (!empty($localtax1_rate) || !empty($localtax2_rate))) {
						$localtaxtmp_array = getLocalTaxesFromRate($vatrate, 0, $object->thirdparty, $mysoc);
						$localtax1_type = isset($localtaxtmp_array[0]) ? $localtaxtmp_array[0] : '';
						$localtax2_type = isset($localtaxtmp_array[2]) ? $localtaxtmp_array[2] : '';
					}

					if ($localtax1_type && $localtax1ligne != 0) {
						if (empty($this->localtax1[$localtax1_type][$localtax1_rate])) {
							$this->localtax1[$localtax1_type][$localtax1_rate] = $localtax1ligne;
						} else {
							$this->localtax1[$localtax1_type][$localtax1_rate] += $localtax1ligne;
						}
					}
					if ($localtax2_type && $localtax2ligne != 0) {
						if (empty($this->localtax2[$localtax2_type][$localtax2_rate])) {
							$this->localtax2[$localtax2_type][$localtax2_rate] = $localtax2ligne;
						} else {
							$this->localtax2[$localtax2_type][$localtax2_rate] += $localtax2ligne;
						}
					}

					if (($object->lines[$i]->info_bits & 0x01) == 0x01) {
						$vatrate .= '*';
					}

					if (!isset($this->tva[$vatrate])) {
						$this->tva[$vatrate] = 0;
					}
					$this->tva[$vatrate] += $tvaligne;
					$vatcode = $object->lines[$i]->vat_src_code;
					if (empty($this->tva_array[$vatrate.($vatcode ? ' ('.$vatcode.')' : '')]['amount'])) {
						$this->tva_array[$vatrate.($vatcode ? ' ('.$vatcode.')' : '')]['amount'] = 0;
					}
					$this->tva_array[$vatrate.($vatcode ? ' ('.$vatcode.')' : '')] = array('vatrate' => $vatrate, 'vatcode' => $vatcode, 'amount' => $this->tva_array[$vatrate.($vatcode ? ' ('.$vatcode.')' : '')]['amount'] + $tvaligne);

					if ($posYAfterImage > $posYAfterDescription) {
						$nexY = $posYAfterImage;
					}

					// Vertical dotted dividers for the row (up to nexY, avoiding overlap with padding junction)
					$pdf->SetLineStyle(array('dash' => '1,1', 'color' => array(100, 100, 100)));
					$pdf->line($this->posxtva - 0.5, $curY, $this->posxtva - 0.5, $nexY);
					if (!getDolGlobalString('MAIN_GENERATE_DOCUMENTS_WITHOUT_VAT') && !getDolGlobalString('MAIN_GENERATE_DOCUMENTS_WITHOUT_VAT_COLUMN')) {
						$pdf->line($this->posxup - 0.5, $curY, $this->posxup - 0.5, $nexY);
					}
					$pdf->line($this->posxqty - 0.5, $curY, $this->posxqty - 0.5, $nexY);
					$pdf->line($this->posxunit - 0.5, $curY, $this->posxunit - 0.5, $nexY);
					$pdf->line($this->posxdiscount - 0.5, $curY, $this->posxdiscount - 0.5, $nexY);
					$pdf->line($this->postotalht - 0.5, $curY, $this->postotalht - 0.5, $nexY);

					// Horizontal line between items
					if (getDolGlobalString('MAIN_PDF_DASH_BETWEEN_LINES') && $i < ($nblines - 1)) {
						$pdf->SetLineStyle(array('dash' => '1,1', 'color' => array(80, 80, 80)));
						$pdf->line($this->marge_gauche, $nexY, $this->page_largeur - $this->marge_droite, $nexY);
					}

					// Padding vertical lines (the 2mm gap)
					$pdf->SetLineStyle(array('dash' => '1,1', 'color' => array(100, 100, 100)));
					$pdf->line($this->posxtva - 0.5, $nexY, $this->posxtva - 0.5, $nexY + 2);
					if (!getDolGlobalString('MAIN_GENERATE_DOCUMENTS_WITHOUT_VAT') && !getDolGlobalString('MAIN_GENERATE_DOCUMENTS_WITHOUT_VAT_COLUMN')) {
						$pdf->line($this->posxup - 0.5, $nexY, $this->posxup - 0.5, $nexY + 2);
					}
					$pdf->line($this->posxqty - 0.5, $nexY, $this->posxqty - 0.5, $nexY + 2);
					$pdf->line($this->posxunit - 0.5, $nexY, $this->posxunit - 0.5, $nexY + 2);
					$pdf->line($this->posxdiscount - 0.5, $nexY, $this->posxdiscount - 0.5, $nexY + 2);
					$pdf->line($this->postotalht - 0.5, $nexY, $this->postotalht - 0.5, $nexY + 2);
					$pdf->SetLineStyle(array('dash' => 0));

					$nexY += 2;
					$nexY_for_padding = $nexY;

					// Detect if some page were added automatically and output _tableau for past pages
					while ($pagenb < $pageposafter) {
						$pdf->setPage($pagenb);
						if ($pagenb == 1) {
							$this->_tableau($pdf, $tab_top, $this->page_hauteur - $tab_top - $heightforfooter, 0, $outputlangs, 0, 1, $object->multicurrency_code);
						} else {
							$this->_tableau($pdf, $tab_top_newpage, $this->page_hauteur - $tab_top_newpage - $heightforfooter, 0, $outputlangs, 1, 1, $object->multicurrency_code);
						}
						$this->_pagefoot($pdf, $object, $outputlangs, 1);
						$pagenb++;
						$pdf->setPage($pagenb);
						$pdf->setPageOrientation('', true, 0);
						if (!getDolGlobalInt('MAIN_PDF_DONOTREPEAT_HEAD')) {
							$this->_pagehead($pdf, $object, 0, $outputlangs);
						}
						if (!empty($tplidx)) {
							$pdf->useTemplate($tplidx);
						}
					}
					if (isset($object->lines[$i + 1]->pagebreak) && $object->lines[$i + 1]->pagebreak) {
						if ($pagenb == 1) {
							$this->_tableau($pdf, $tab_top, $this->page_hauteur - $tab_top - $heightforfooter, 0, $outputlangs, 0, 1, $object->multicurrency_code);
						} else {
							$this->_tableau($pdf, $tab_top_newpage, $this->page_hauteur - $tab_top_newpage - $heightforfooter, 0, $outputlangs, 1, 1, $object->multicurrency_code);
						}
						$this->_pagefoot($pdf, $object, $outputlangs, 1);
						$pdf->AddPage();
						if (!empty($tplidx)) {
							$pdf->useTemplate($tplidx);
						}
						$pagenb++;
						if (!getDolGlobalInt('MAIN_PDF_DONOTREPEAT_HEAD')) {
							$this->_pagehead($pdf, $object, 0, $outputlangs);
						}
					}
				}

				// Fill blank space with vertical dotted lines until the bottom of the table square
				$lastY = (isset($nexY_for_padding) ? $nexY_for_padding : $pdf->GetY());
				$bottomlasttab = $this->page_hauteur - $heightforinfotot - $heightforfreetext - $heightforsignature - $heightforfooter + 1;
				if ($lastY < $bottomlasttab) {
					$pdf->SetLineStyle(array('dash' => '1,1', 'color' => array(100, 100, 100)));
					$pdf->line($this->posxtva - 0.5, $lastY, $this->posxtva - 0.5, $bottomlasttab - 1);
					if (!getDolGlobalString('MAIN_GENERATE_DOCUMENTS_WITHOUT_VAT') && !getDolGlobalString('MAIN_GENERATE_DOCUMENTS_WITHOUT_VAT_COLUMN')) {
						$pdf->line($this->posxup - 0.5, $lastY, $this->posxup - 0.5, $bottomlasttab - 1);
					}
					$pdf->line($this->posxqty - 0.5, $lastY, $this->posxqty - 0.5, $bottomlasttab - 1);
					if (getDolGlobalInt('PRODUCT_USE_UNITS') && $this->posxunit < $this->posxdiscount) {
						$pdf->line($this->posxunit - 0.5, $lastY, $this->posxunit - 0.5, $bottomlasttab - 1);
					}
					$pdf->line($this->posxdiscount - 0.5, $lastY, $this->posxdiscount - 0.5, $bottomlasttab - 1);
					$pdf->line($this->postotalht - 0.5, $lastY, $this->postotalht - 0.5, $bottomlasttab - 1);
					$pdf->SetLineStyle(array('dash' => 0));
				}

				// Show square
				if ($pagenb == 1) {
					$this->_tableau($pdf, $tab_top, $this->page_hauteur - $tab_top - $heightforinfotot - $heightforfreetext - $heightforsignature - $heightforfooter, 0, $outputlangs, 0, 0, $object->multicurrency_code);
					$bottomlasttab = $this->page_hauteur - $heightforinfotot - $heightforfreetext - $heightforsignature - $heightforfooter + 1;
				} else {
					$this->_tableau($pdf, $tab_top_newpage, $this->page_hauteur - $tab_top_newpage - $heightforinfotot - $heightforfreetext - $heightforsignature - $heightforfooter, 0, $outputlangs, 1, 0, $object->multicurrency_code);
					$bottomlasttab = $this->page_hauteur - $heightforinfotot - $heightforfreetext - $heightforsignature - $heightforfooter + 1;
				}

				// Affiche zone infos
				$posy_info = $this->_tableau_info($pdf, $object, $bottomlasttab, $outputlangs);

				// Affiche zone totaux
				$posy_tot = $this->_tableau_tot($pdf, $object, 0, $bottomlasttab, $outputlangs);

				$posy = max($posy_info, $posy_tot);

				// Customer signature area
				if (!getDolGlobalString('PROPAL_DISABLE_SIGNATURE')) {
					$posy = $this->_signature_area($pdf, $object, $posy, $outputlangs);

					$ysign = round($this->page_hauteur - 60, 2); // Matches box_y in _signature_area
					$keywords = $outputlangs->convToOutputCharset($object->ref)." ".$outputlangs->transnoentities("PdfCommercialProposalTitle")." ".$outputlangs->convToOutputCharset($object->thirdparty->name);
					$pdf->SetKeyWords($keywords." PAGESIGN=".$pdf->getPage()." YSIGN=".$ysign);
				}

				// Pied de page
				$this->_pagefoot($pdf, $object, $outputlangs);
				if (method_exists($pdf, 'AliasNbPages')) {
					$pdf->AliasNbPages();
				}

				// Add terms to sale
				$termsofsalefilename = getDolGlobalString('MAIN_INFO_PROPAL_TERMSOFSALE');
				if (getDolGlobalInt('MAIN_PDF_ADD_TERMSOFSALE_PROPAL') && $termsofsalefilename) {
					$termsofsale = $conf->propal->dir_output.'/'.$termsofsalefilename;
					if (!empty($conf->propal->multidir_output[$object->entity ?? $conf->entity])) {
						$termsofsale = $conf->propal->multidir_output[$object->entity ?? $conf->entity].'/'.$termsofsalefilename;
					}
					if (file_exists($termsofsale) && is_readable($termsofsale)) {
						$pagecount = $pdf->setSourceFile($termsofsale);
						for ($i = 1; $i <= $pagecount; $i++) {
							$tplIdx = $pdf->importPage($i);
							if ($tplIdx !== false) {
								$s = $pdf->getTemplatesize($tplIdx);
								$pdf->AddPage($s['h'] > $s['w'] ? 'P' : 'L');
								$pdf->useTemplate($tplIdx);
							} else {
								setEventMessages(null, array($termsofsale.' cannot be added, probably protected PDF'), 'warnings');
							}
						}
					}
				}

				//If propal merge product PDF is active
				if (getDolGlobalString('PRODUIT_PDF_MERGE_PROPAL')) {
					require_once DOL_DOCUMENT_ROOT.'/product/class/propalmergepdfproduct.class.php';

					$already_merged = array();
					foreach ($object->lines as $line) {
						if (!empty($line->fk_product) && !(in_array($line->fk_product, $already_merged))) {
							$filetomerge = new Propalmergepdfproduct($this->db);

							if (getDolGlobalInt('MAIN_MULTILANGS')) {
								$filetomerge->fetch_by_product($line->fk_product, $outputlangs->defaultlang);
							} else {
								$filetomerge->fetch_by_product($line->fk_product);
							}

							$already_merged[] = $line->fk_product;

							$product = new Product($this->db);
							$product->fetch($line->fk_product);

							if ($product->entity != $conf->entity) {
								$entity_product_file = $product->entity;
							} else {
								$entity_product_file = $conf->entity;
							}

							if (count($filetomerge->lines) > 0) {
								foreach ($filetomerge->lines as $linefile) {
									$filetomerge_dir = null;
									if (!empty($linefile->id) && !empty($linefile->file_name)) {
										if (getDolGlobalInt('PRODUCT_USE_OLD_PATH_FOR_PHOTO')) {
											if (isModEnabled("product")) {
												$filetomerge_dir = $conf->product->multidir_output[$entity_product_file ?? $conf->entity].'/'.get_exdir($product->id, 2, 0, 0, $product, 'product').$product->id."/photos";
											} elseif (isModEnabled("service")) {
												$filetomerge_dir = $conf->service->multidir_output[$entity_product_file ?? $conf->entity].'/'.get_exdir($product->id, 2, 0, 0, $product, 'product').$product->id."/photos";
											}
										} else {
											if (isModEnabled("product")) {
												$filetomerge_dir = $conf->product->multidir_output[$entity_product_file ?? $conf->entity].'/'.get_exdir(0, 0, 0, 0, $product, 'product');
											} elseif (isModEnabled("service")) {
												$filetomerge_dir = $conf->service->multidir_output[$entity_product_file ?? $conf->entity].'/'.get_exdir(0, 0, 0, 0, $product, 'product');
											}
										}

										dol_syslog(get_class($this).':: upload_dir='.$filetomerge_dir, $filetomerge_dir === null ? LOG_ERR : LOG_DEBUG);
										if ($filetomerge_dir === null) {
											continue;
										}

										$infile = $filetomerge_dir.'/'.$linefile->file_name;
										if (file_exists($infile) && is_readable($infile)) {
											$pagecount = $pdf->setSourceFile($infile);
											for ($i = 1; $i <= $pagecount; $i++) {
												$tplIdx = $pdf->importPage($i);
												if ($tplIdx !== false) {
													$s = $pdf->getTemplatesize($tplIdx);
													$pdf->AddPage($s['h'] > $s['w'] ? 'P' : 'L');
													$pdf->useTemplate($tplIdx);
												} else {
													setEventMessages(null, array($infile.' cannot be added, probably protected PDF'), 'warnings');
												}
											}
										}
									}
								}
							}
						}
					}
				}

				$pdf->Close();

				$pdf->Output($file, 'F');

				//Add pdfgeneration hook
				$hookmanager->initHooks(array('pdfgeneration'));
				$parameters = array('file' => $file, 'object' => $object, 'outputlangs' => $outputlangs);
				global $action;
				$reshook = $hookmanager->executeHooks('afterPDFCreation', $parameters, $this, $action);
				$this->warnings = $hookmanager->warnings;
				if ($reshook < 0) {
					$this->error = $hookmanager->error;
					$this->errors = $hookmanager->errors;
					dolChmod($file);
					return -1;
				}

				dolChmod($file);

				$this->result = array('fullpath' => $file);

				return 1;
			} else {
				$this->error = $langs->trans("ErrorCanNotCreateDir", $dir);
				return 0;
			}
		} else {
			$this->error = $langs->trans("ErrorConstantNotDefined", "PROP_OUTPUTDIR");
			return 0;
		}
	}

	// phpcs:disable PEAR.NamingConventions.ValidFunctionName.ScopeNotCamelCaps
	/**
	 *  Show payments table
	 *
	 *  @param	TCPDF		$pdf            Object PDF
	 *  @param  Propal		$object         Object proposal
	 *  @param  float		$posy           Position y in PDF
	 *  @param  Translate	$outputlangs    Object langs for output
	 *  @return int             			Return integer <0 if KO, >0 if OK
	 */
	protected function _tableau_versements(&$pdf, $object, $posy, $outputlangs)
	{
		// phpcs:enable
		return 1;
	}

	// phpcs:disable PEAR.NamingConventions.ValidFunctionName.ScopeNotCamelCaps
	/**
	 *   Show miscellaneous information (payment mode, payment term, ...)
	 *
	 *   @param		TCPDF		$pdf     		Object PDF
	 *   @param		Propal		$object			Object to show
	 *   @param		float		$posy			Y
	 *   @param		Translate	$outputlangs	Langs object
	 *   @return	float
	 */
	protected function _tableau_info(&$pdf, $object, $posy, $outputlangs)
	{
		// phpcs:enable
		global $conf, $mysoc;
		$default_font_size = pdf_getPDFFontSize($outputlangs);

		$pdf->SetFont('', '', $default_font_size - 1);

		$diffsizetitle = getDolGlobalInt('PDF_DIFFSIZE_TITLE', 3);

		$posxval = 52;
		if (getDolGlobalString('MAIN_PDF_DELIVERY_DATE_TEXT')) {
			$displaydate = "daytext";
		} else {
			$displaydate = "day";
		}

		// Show shipping date
		if (!empty($object->delivery_date)) {
			$outputlangs->load("sendings");
			$pdf->SetFont('', 'B', $default_font_size - $diffsizetitle);
			$pdf->SetXY($this->marge_gauche, $posy);
			$titre = $outputlangs->transnoentities("DateDeliveryPlanned").':';
			$pdf->MultiCell(80, 4, $titre, 0, 'L');
			$pdf->SetFont('', '', $default_font_size - $diffsizetitle);
			$pdf->SetXY($posxval, $posy);
			$dlp = dol_print_date($object->delivery_date, $displaydate, false, $outputlangs, true);
			$pdf->MultiCell(80, 4, $dlp, 0, 'L');

			$posy = $pdf->GetY() + 1;
		} elseif ($object->availability_code || $object->availability) {
			$pdf->SetFont('', 'B', $default_font_size - $diffsizetitle);
			$pdf->SetXY($this->marge_gauche, $posy);
			$titre = $outputlangs->transnoentities("AvailabilityPeriod").':';
			$pdf->MultiCell(80, 4, $titre, 0, 'L');
			$pdf->SetTextColor(0, 0, 0);
			$pdf->SetFont('', '', $default_font_size - $diffsizetitle);
			$pdf->SetXY($posxval, $posy);
			$lib_availability = ($outputlangs->transnoentities("AvailabilityType".$object->availability_code) != 'AvailabilityType'.$object->availability_code) ? $outputlangs->transnoentities("AvailabilityType".$object->availability_code) : $outputlangs->convToOutputCharset($object->availability);
			$lib_availability = str_replace('\n', "\n", $lib_availability);
			$pdf->MultiCell(80, 4, $lib_availability, 0, 'L');

			$posy = $pdf->GetY() + 1;
		}

		// Show delivery mode
		if (!getDolGlobalString('PROPOSAL_PDF_HIDE_DELIVERYMODE') && $object->shipping_method_id > 0) {
			$outputlangs->load("sendings");

			$shipping_method_id = $object->shipping_method_id;
			if (getDolGlobalString('SOCIETE_ASK_FOR_SHIPPING_METHOD') && !empty($this->emetteur->shipping_method_id)) {
				$shipping_method_id = $this->emetteur->shipping_method_id;
			}
			$shipping_method_code = dol_getIdFromCode($this->db, (string) $shipping_method_id, 'c_shipment_mode', 'rowid', 'code');
			$shipping_method_label = dol_getIdFromCode($this->db, (string) $shipping_method_id, 'c_shipment_mode', 'rowid', 'libelle');

			$pdf->SetFont('', 'B', $default_font_size - $diffsizetitle);
			$pdf->SetXY($this->marge_gauche, $posy);
			$titre = $outputlangs->transnoentities("SendingMethod").':';
			$pdf->MultiCell(43, 4, $titre, 0, 'L');

			$pdf->SetFont('', '', $default_font_size - $diffsizetitle);
			$pdf->SetXY($posxval, $posy);
			$lib_condition_paiement = ($outputlangs->transnoentities("SendingMethod".strtoupper($shipping_method_code)) != "SendingMethod".strtoupper($shipping_method_code)) ? $outputlangs->trans("SendingMethod".strtoupper($shipping_method_code)) : $shipping_method_label;
			$lib_condition_paiement = str_replace('\n', "\n", $lib_condition_paiement);
			$pdf->MultiCell(67, 4, $lib_condition_paiement, 0, 'L');

			$posy = $pdf->GetY() + 1;
		}

		// Show payments conditions
		if (!getDolGlobalString('PROPOSAL_PDF_HIDE_PAYMENTTERM') && $object->cond_reglement_code) {
			$pdf->SetFont('', 'B', $default_font_size - $diffsizetitle);
			$pdf->SetXY($this->marge_gauche, $posy);
			$titre = $outputlangs->transnoentities("PaymentConditions").':';
			$pdf->MultiCell(43, 4, $titre, 0, 'L');

			$pdf->SetFont('', '', $default_font_size - $diffsizetitle);
			$pdf->SetXY($posxval, $posy);
			$lib_condition_paiement = $outputlangs->transnoentities("PaymentCondition".$object->cond_reglement_code) != 'PaymentCondition'.$object->cond_reglement_code ? $outputlangs->transnoentities("PaymentCondition".$object->cond_reglement_code) : $outputlangs->convToOutputCharset($object->cond_reglement_doc ? $object->cond_reglement_doc : $object->cond_reglement_label);
			$lib_condition_paiement = str_replace('\n', "\n", $lib_condition_paiement);
			if ($object->deposit_percent > 0) {
				$lib_condition_paiement = str_replace('__DEPOSIT_PERCENT__', $object->deposit_percent, $lib_condition_paiement);
			}
			$pdf->MultiCell(67, 4, $lib_condition_paiement, 0, 'L');

			$posy = $pdf->GetY() + 3;
		}

		if (!getDolGlobalString('PROPOSAL_PDF_HIDE_PAYMENTMODE')) {
			// Show payment mode
			if ($object->mode_reglement_code
			&& $object->mode_reglement_code != 'CHQ'
			&& $object->mode_reglement_code != 'VIR') {
				$pdf->SetFont('', 'B', $default_font_size - $diffsizetitle);
				$pdf->SetXY($this->marge_gauche, $posy);
				$titre = $outputlangs->transnoentities("PaymentMode").':';
				$pdf->MultiCell(80, 5, $titre, 0, 'L');
				$pdf->SetFont('', '', $default_font_size - $diffsizetitle);
				$pdf->SetXY($posxval, $posy);
				$lib_mode_reg = $outputlangs->transnoentities("PaymentType".$object->mode_reglement_code) != 'PaymentType'.$object->mode_reglement_code ? $outputlangs->transnoentities("PaymentType".$object->mode_reglement_code) : $outputlangs->convToOutputCharset($object->mode_reglement);
				$pdf->MultiCell(80, 5, $lib_mode_reg, 0, 'L');

				$posy = $pdf->GetY() + 2;
			}

			// Show payment mode CHQ
			if (empty($object->mode_reglement_code) || $object->mode_reglement_code == 'CHQ') {
				if (getDolGlobalInt('FACTURE_CHQ_NUMBER')) {
					if (getDolGlobalInt('FACTURE_CHQ_NUMBER') > 0) {
						$account = new Account($this->db);
						$account->fetch(getDolGlobalInt('FACTURE_CHQ_NUMBER'));

						$pdf->SetXY($this->marge_gauche, $posy);
						$pdf->SetFont('', 'B', $default_font_size - $diffsizetitle);
						$pdf->MultiCell(100, 3, $outputlangs->transnoentities('PaymentByChequeOrderedTo', $account->owner_name), 0, 'L', false);
						$posy = $pdf->GetY() + 1;

						if (!getDolGlobalString('MAIN_PDF_HIDE_CHQ_ADDRESS')) {
							$pdf->SetXY($this->marge_gauche, $posy);
							$pdf->SetFont('', '', $default_font_size - $diffsizetitle);
							$pdf->MultiCell(100, 3, $outputlangs->convToOutputCharset($account->owner_address), 0, 'L', false);
							$posy = $pdf->GetY() + 2;
						}
					}
					if (getDolGlobalInt('FACTURE_CHQ_NUMBER') == -1) {
						$pdf->SetXY($this->marge_gauche, $posy);
						$pdf->SetFont('', 'B', $default_font_size - $diffsizetitle);
						$pdf->MultiCell(100, 3, $outputlangs->transnoentities('PaymentByChequeOrderedTo', $this->emetteur->name), 0, 'L', false);
						$posy = $pdf->GetY() + 1;

						if (!getDolGlobalString('MAIN_PDF_HIDE_CHQ_ADDRESS')) {
							$pdf->SetXY($this->marge_gauche, $posy);
							$pdf->SetFont('', '', $default_font_size - $diffsizetitle);
							$pdf->MultiCell(100, 3, $outputlangs->convToOutputCharset($this->emetteur->getFullAddress()), 0, 'L', false);
							$posy = $pdf->GetY() + 2;
						}
					}
				}
			}

			// If payment mode not forced or forced to VIR, show payment with BAN
			if (empty($object->mode_reglement_code) || $object->mode_reglement_code == 'VIR') {
				if (!empty($object->fk_account) || !empty($object->fk_bank) || getDolGlobalInt('FACTURE_RIB_NUMBER')) {
					$bankid = (empty($object->fk_account) ? getDolGlobalInt('FACTURE_RIB_NUMBER') : $object->fk_account);
					if (!empty($object->fk_bank) && $object->fk_bank > 0) {
						$bankid = $object->fk_bank;
					}
					$account = new Account($this->db);
					$account->fetch((int) $bankid);

					$curx = $this->marge_gauche;
					$cury = $posy;

					$posy = pdf_bank($pdf, $outputlangs, $curx, $cury, $account, 0, $default_font_size);

					$posy += 2;
				}
			}
		}

		return $posy;
	}

	// phpcs:disable PEAR.NamingConventions.ValidFunctionName.ScopeNotCamelCaps
	/**
	 *	Show total to pay
	 *
	 *	@param	TCPDF		$pdf            Object PDF
	 *	@param  Propal		$object         Object propal
	 *	@param  float		$deja_regle     Amount already paid
	 *	@param	float		$posy			Start position
	 *	@param	Translate	$outputlangs	Object langs
	 *  @param  Translate	$outputlangsbis	Object lang for output bis
	 *	@return float						Position for continuation
	 */
	protected function _tableau_tot(&$pdf, $object, $deja_regle, $posy, $outputlangs, $outputlangsbis = null)
	{
		// phpcs:enable
		global $mysoc;

		$default_font_size = pdf_getPDFFontSize($outputlangs);

		$tab2_top = $posy;
		$tab2_hl = 4;
		$pdf->SetFont('', '', $default_font_size - 1);

		// Total table
		$col1x = 100;
		$col2x = $this->postotalht;
		if ($this->page_largeur < 210) {
			$col1x -= 20;
			$col2x -= 20;
		}
		$largcol2 = ($this->page_largeur - $this->marge_droite - $col2x);

		$useborder = 0;
		$index = 0;

		// Get Total HT
		$total_ht = (isModEnabled("multicurrency") && $object->multicurrency_tx != 1 ? $object->multicurrency_total_ht : $object->total_ht);

		// Total discount
		$total_discount_on_lines = 0;
		$multicurrency_total_discount_on_lines = 0;
		foreach ($object->lines as $i => $line) {
			$resdiscount = pdfGetLineTotalDiscountAmount($object, $i, $outputlangs, 2);
			$multicurrency_resdiscount = pdfGetLineTotalDiscountAmount($object, $i, $outputlangs, 2, 1);

			$total_discount_on_lines += (is_numeric($resdiscount) ? $resdiscount : 0);
			$multicurrency_total_discount_on_lines += (is_numeric($multicurrency_resdiscount) ? $multicurrency_resdiscount : 0);
			if ($line->total_ht < 0) {
				$total_discount_on_lines += -$line->total_ht;
				$multicurrency_total_discount_on_lines += -$line->multicurrency_total_ht;
			}
		}

		if ($total_discount_on_lines > 0) {
			// Show total NET before discount
			$pdf->SetFillColor(255, 255, 255);
			$pdf->SetXY($col1x, $tab2_top);
			$pdf->MultiCell($col2x - $col1x, $tab2_hl, $outputlangs->transnoentities("TotalHTBeforeDiscount").(is_object($outputlangsbis) ? ' / '.$outputlangsbis->transnoentities("TotalHTBeforeDiscount") : ''), 0, 'L', true);
			$pdf->SetXY($col2x, $tab2_top);

			$total_before_discount_to_show = ((isModEnabled("multicurrency") && $object->multicurrency_tx != 1) ? ($object->multicurrency_total_ht + $multicurrency_total_discount_on_lines) : ($object->total_ht + $total_discount_on_lines));
			$pdf->MultiCell($largcol2, $tab2_hl, price($total_before_discount_to_show, 0, $outputlangs), 0, 'R', true);

			$index++;

			$pdf->SetFillColor(255, 255, 255);
			$pdf->SetXY($col1x, $tab2_top + $tab2_hl);
			$pdf->MultiCell($col2x - $col1x, $tab2_hl, $outputlangs->transnoentities("TotalDiscount").(is_object($outputlangsbis) ? ' / '.$outputlangsbis->transnoentities("TotalDiscount") : ''), 0, 'L', true);
			$pdf->SetXY($col2x, $tab2_top + $tab2_hl);

			$total_discount_to_show = ((isModEnabled("multicurrency") && $object->multicurrency_tx != 1) ? $multicurrency_total_discount_on_lines : $total_discount_on_lines);
			$pdf->MultiCell($largcol2, $tab2_hl, price($total_discount_to_show, 0, $outputlangs), 0, 'R', true);

			$index++;
		}

		// Total HT
		$pdf->SetFillColor(255, 255, 255);
		$pdf->SetXY($col1x, $tab2_top + $tab2_hl * $index);
		$pdf->MultiCell($col2x - $col1x, $tab2_hl, $outputlangs->transnoentities("TotalHT"), 0, 'L', true);

		$total_ht = ((isModEnabled("multicurrency") && isset($object->multicurrency_tx) && $object->multicurrency_tx != 1) ? $object->multicurrency_total_ht : $object->total_ht);
		$pdf->SetXY($col2x, $tab2_top + $tab2_hl * $index);
		$pdf->MultiCell($largcol2, $tab2_hl, price($total_ht + (!empty($object->remise) ? $object->remise : 0), 0, $outputlangs), 0, 'R', true);

		// Show VAT by rates and total
		$pdf->SetFillColor(248, 248, 248);

		$total_ttc = (isModEnabled("multicurrency") && $object->multicurrency_tx != 1) ? $object->multicurrency_total_ttc : $object->total_ttc;

		$this->atleastoneratenotnull = 0;
		if (!getDolGlobalString('MAIN_GENERATE_DOCUMENTS_WITHOUT_VAT')) {
			$tvaisnull = (!empty($this->tva) && count($this->tva) == 1 && isset($this->tva['0.000']) && is_float($this->tva['0.000']));
			if (getDolGlobalString('MAIN_GENERATE_DOCUMENTS_WITHOUT_VAT_IFNULL') && $tvaisnull) {
			} else {
				//Local tax 1 before VAT
				foreach ($this->localtax1 as $localtax_type => $localtax_rate) {
					if (in_array((string) $localtax_type, array('1', '3', '5'))) {
						continue;
					}

					foreach ($localtax_rate as $tvakey => $tvaval) {
						if ($tvakey != 0) {
							$index++;
							$pdf->SetXY($col1x, $tab2_top + $tab2_hl * $index);

							$tvacompl = '';
							if (preg_match('/\*/', $tvakey)) {
								$tvakey = str_replace('*', '', $tvakey);
								$tvacompl = " (".$outputlangs->transnoentities("NonPercuRecuperable").")";
							}
							$totalvat = $outputlangs->transcountrynoentities("TotalLT1", $mysoc->country_code).' ';

							if (getDolGlobalString('PDF_LOCALTAX1_LABEL_IS_CODE_OR_RATE') == 'nocodenorate') {
								$pdf->MultiCell($col2x - $col1x, $tab2_hl, $totalvat, 0, 'L', true);
							} elseif (getDolGlobalString('PDF_LOCALTAX1_LABEL_IS_CODE_OR_RATE') == 'code') {
								$pdf->MultiCell($col2x - $col1x, $tab2_hl, $totalvat.$localtax_type, 0, 'L', true);
							} else {
								$pdf->MultiCell($col2x - $col1x, $tab2_hl, $totalvat.$tvakey.$tvacompl, 0, 'L', true);
							}

							$pdf->SetXY($col2x, $tab2_top + $tab2_hl * $index);
							$pdf->MultiCell($largcol2, $tab2_hl, price($tvaval, 0, $outputlangs), 0, 'R', true);
						}
					}
				}

				// VAT
				foreach ($this->tva_array as $tvakey => $tvaval) {
					$index++;
					$pdf->SetXY($col1x, $tab2_top + $tab2_hl * $index);

					$tvacompl = '';
					if (preg_match('/\*/', $tvaval['vatrate'])) {
						$tvaval['vatrate'] = str_replace('*', '', $tvaval['vatrate']);
						$tvacompl = " (".$outputlangs->transnoentities("NonPercuRecuperable").")";
					}
					if (getDolGlobalString('MAIN_GENERATE_DOCUMENTS_WITHOUT_VAT_COLUMN') == 'yes') {
						$pdf->MultiCell($col2x - $col1x, $tab2_hl, $outputlangs->transnoentities("TotalVAT").$tvacompl, 0, 'L', true);
					} else {
						$pdf->MultiCell($col2x - $col1x, $tab2_hl, $outputlangs->transnoentities("TotalVAT").($tvaval['vatcode'] ? ' ('.$tvaval['vatcode'].')' : '').$tvacompl, 0, 'L', true);
					}

					$pdf->SetXY($col2x, $tab2_top + $tab2_hl * $index);
					$pdf->MultiCell($largcol2, $tab2_hl, price($tvaval['amount'], 0, $outputlangs), 0, 'R', true);
				}

				//Local tax 2 after VAT
				foreach ($this->localtax2 as $localtax_type => $localtax_rate) {
					if (in_array((string) $localtax_type, array('1', '3', '5'))) {
						continue;
					}

					foreach ($localtax_rate as $tvakey => $tvaval) {
						if ($tvakey != 0) {
							$index++;
							$pdf->SetXY($col1x, $tab2_top + $tab2_hl * $index);

							$tvacompl = '';
							if (preg_match('/\*/', $tvakey)) {
								$tvakey = str_replace('*', '', $tvakey);
								$tvacompl = " (".$outputlangs->transnoentities("NonPercuRecuperable").")";
							}
							$totalvat = $outputlangs->transcountrynoentities("TotalLT2", $mysoc->country_code).' ';

							if (getDolGlobalString('PDF_LOCALTAX2_LABEL_IS_CODE_OR_RATE') == 'nocodenorate') {
								$pdf->MultiCell($col2x - $col1x, $tab2_hl, $totalvat, 0, 'L', true);
							} elseif (getDolGlobalString('PDF_LOCALTAX2_LABEL_IS_CODE_OR_RATE') == 'code') {
								$pdf->MultiCell($col2x - $col1x, $tab2_hl, $totalvat.$localtax_type, 0, 'L', true);
							} else {
								$pdf->MultiCell($col2x - $col1x, $tab2_hl, $totalvat.$tvakey.$tvacompl, 0, 'L', true);
							}

							$pdf->SetXY($col2x, $tab2_top + $tab2_hl * $index);
							$pdf->MultiCell($largcol2, $tab2_hl, price($tvaval, 0, $outputlangs), 0, 'R', true);
						}
					}
				}

				// Total TTC
				$index++;
				$pdf->SetXY($col1x, $tab2_top + $tab2_hl * $index);
				$pdf->SetTextColor($this->text_color[0], $this->text_color[1], $this->text_color[2]);
				$pdf->SetFont('', 'B', $default_font_size);
				$pdf->MultiCell($col2x - $col1x, $tab2_hl, $outputlangs->transnoentities("TotalTTC").(is_object($outputlangsbis) ? ' / '.$outputlangsbis->transnoentities("TotalTTC") : ''), 0, 'L', true);

				$pdf->SetXY($col2x, $tab2_top + $tab2_hl * $index);
				$pdf->MultiCell($largcol2, $tab2_hl, price($total_ttc, 0, $outputlangs), 0, 'R', true);

				$pdf->SetTextColor(0, 0, 0);
				$pdf->SetFont('', '', $default_font_size - 1);

				// Show multicurrency
				if (isModEnabled("multicurrency") && $object->multicurrency_tx != 1) {
					$index++;
					$pdf->SetXY($col1x, $tab2_top + $tab2_hl * $index);
					$pdf->MultiCell($col2x - $col1x, $tab2_hl, $outputlangs->transnoentities("TotalHT").' ('.$outputlangs->transnoentities("Currency".$object->multicurrency_code).')', 0, 'L', true);
					$pdf->SetXY($col2x, $tab2_top + $tab2_hl * $index);
					$pdf->MultiCell($largcol2, $tab2_hl, price($object->multicurrency_total_ht, 0, $outputlangs), 0, 'R', true);

					$index++;
					$pdf->SetXY($col1x, $tab2_top + $tab2_hl * $index);
					$pdf->MultiCell($col2x - $col1x, $tab2_hl, $outputlangs->transnoentities("TotalVAT").' ('.$outputlangs->transnoentities("Currency".$object->multicurrency_code).')', 0, 'L', true);
					$pdf->SetXY($col2x, $tab2_top + $tab2_hl * $index);
					$pdf->MultiCell($largcol2, $tab2_hl, price($object->multicurrency_total_tva, 0, $outputlangs), 0, 'R', true);

					$index++;
					$pdf->SetXY($col1x, $tab2_top + $tab2_hl * $index);
					$pdf->MultiCell($col2x - $col1x, $tab2_hl, $outputlangs->transnoentities("TotalTTC").' ('.$outputlangs->transnoentities("Currency".$object->multicurrency_code).')', 0, 'L', true);
					$pdf->SetXY($col2x, $tab2_top + $tab2_hl * $index);
					$pdf->MultiCell($largcol2, $tab2_hl, price($object->multicurrency_total_ttc, 0, $outputlangs), 0, 'R', true);
				}
			}
		}

		$pdf->SetTextColor(0, 0, 0);

		return ($tab2_top + ($tab2_hl * $index));
	}

	// phpcs:disable PEAR.NamingConventions.ValidFunctionName.ScopeNotCamelCaps
	/**
	 *  Function to show the header of the document
	 *
	 *  @param	TCPDF		$pdf            Object PDF
	 *  @param  Propal		$object         Object to show
	 *  @param  int			$showaddress    0=no, 1=yes
	 *  @param  Translate	$outputlangs    Object langs for output
	 *  @param  Translate	$outputlangsbis Object langs for output bis
	 *  @return float                       Height of header
	 */
	protected function _pagehead(&$pdf, $object, $showaddress, $outputlangs, $outputlangsbis = null)
	{
		// phpcs:enable
		global $conf, $langs, $mysoc;

		$default_font_size = pdf_getPDFFontSize($outputlangs);

		pdf_pagehead($pdf, $outputlangs, $this->page_hauteur);

		$pdf->SetTextColor($this->text_color[0], $this->text_color[1], $this->text_color[2]);
		$pdf->SetFont('', 'B', $default_font_size + 4);

		$posx = $this->page_largeur - $this->marge_droite - 100;
		$posy = $this->marge_haute;

		// 1. Draw Blue Header Box (Only Top Corners Rounded: 1001 = TR, BR, BL, TL)
		$pdf->RoundedRect($this->marge_gauche, $this->marge_haute, $this->page_largeur - $this->marge_gauche - $this->marge_droite, 35, $this->corner_radius, '1001', 'F', null, $this->primary_color);

		$pdf->SetTextColor(255, 255, 255);
		$posx = $this->page_largeur - $this->marge_droite - 100;
		$posy = $this->marge_haute + 10;

		// 2. Logo (Centered inside blue box)
		$logo = $conf->mycompany->dir_output.'/logos/'.$mysoc->logo;
		if ($mysoc->logo && is_readable($logo)) {
			$height = 22; // Ideal height for centered logo
			$sizes = pdf_getSizeForImage($logo);
			if ($sizes['height'] > 0) {
				$w = $sizes['width'] * ($height / $sizes['height']);
				$logo_x = ($this->page_largeur - $w) / 2;
				$pdf->Image($logo, $logo_x, $this->marge_haute + 6.5, 0, $height);
			}
		}

		// 3. Title and Ref (Single line at the bottom left of blue box)
		$pdf->SetFont('', 'B', 8);
		$pdf->SetTextColor(255, 255, 255);
		$pdf->SetXY($this->marge_gauche + 1, $this->marge_haute + 30);
		$text = dol_strtoupper($outputlangs->transnoentities("Proposal"))." ".$object->ref;
		$pdf->MultiCell($this->page_largeur - $this->marge_gauche - $this->marge_droite - 2, 4, $text, 0, 'L');

		// 4. Date (Top Right of blue box)
		$pdf->SetFont('', 'B', 8);
		$pdf->SetXY($posx, $this->marge_haute + 5);
		$pdf->MultiCell(100, 4, dol_strtoupper($outputlangs->transnoentities("Date")).": ".dol_print_date($object->date, "day", false, $outputlangs, true), 0, 'R');

		// 5. Validity Date (Bottom Right of blue box)
		$posy_bottom = $this->marge_haute + 30;
		$pdf->SetXY($posx, $posy_bottom);
		$pdf->MultiCell(100, 4, dol_strtoupper($outputlangs->transnoentities("DateEndPropal")).": ".dol_print_date($object->fin_validite, "day", false, $outputlangs, true), 0, 'R');

		$pdf->SetTextColor($this->text_color[0], $this->text_color[1], $this->text_color[2]);

		if ($showaddress == 1) {
			$posx = $this->page_largeur - $this->marge_droite - 100;
			$posy = $this->marge_haute + 38;

			$pdf->SetXY($posx, $posy);
			$pdf->SetFont('', 'B', 14);
			$pdf->SetTextColor($this->primary_color[0], $this->primary_color[1], $this->primary_color[2]);
			$pdf->MultiCell(100, 5, "Cliente", 0, 'R');
			$posy = $pdf->GetY();

			$pdf->SetXY($posx, $posy);
			$pdf->SetFont('', '', 12);
			$pdf->SetTextColor($this->text_color[0], $this->text_color[1], $this->text_color[2]);

			$carac_client = pdf_build_address($outputlangs, $this->emetteur, $object->thirdparty, '', 0, 'target', $object);
			$carac_client = $outputlangs->convToOutputCharset($carac_client);
			$pdf->MultiCell(100, 5, $object->thirdparty->name, 0, 'R');
			$posy = $pdf->GetY();

			$pdf->SetXY($posx, $posy);
			$pdf->MultiCell(100, 5, $carac_client, 0, 'R');
		}

		$pdf->SetTextColor(0, 0, 0);
		return 0;
	}

	// phpcs:disable PEAR.NamingConventions.ValidFunctionName.ScopeNotCamelCaps
	/**
	 *   Show table framework for lines
	 *
	 *   @param	TCPDF		$pdf     		Object PDF
	 *   @param	float		$posy			Position y
	 *   @param	float		$cabinetY		Height
	 *   @param	int			$showdetails	Show details (default=1)
	 *   @param   Translate	$outputlangs    Object langs
	 *   @param	int			$defaultFontSize	Font size
	 *   @param   int         $multicurrency    Is multicurrency (0/No, 1/Yes)
	 *   @return	void
	 */
	protected function _tableau(&$pdf, $posy, $cabinetY, $showdetails, $outputlangs, $defaultFontSize = 0, $multicurrency = 0, $currency = '')
	{
		// phpcs:enable
		global $conf;

		$default_font_size = pdf_getPDFFontSize($outputlangs);

		$pdf->SetTextColor(0, 0, 0);
		$pdf->SetFont('', '', $default_font_size - 1);

		$pdf->SetFillColor($this->light_bg[0], $this->light_bg[1], $this->light_bg[2]);

		$pdf->RoundedRect($this->marge_gauche, $posy, $this->page_largeur - $this->marge_gauche - $this->marge_droite, $cabinetY, $this->corner_radius, '1234', 'D');

		$pdf->SetDrawColor($this->secondary_color[0], $this->secondary_color[1], $this->secondary_color[2]);

		$pdf->SetFillColor($this->primary_color[0], $this->primary_color[1], $this->primary_color[2]);
		$pdf->RoundedRect($this->marge_gauche, $posy, $this->page_largeur - $this->marge_gauche - $this->marge_droite, 10, $this->corner_radius, '1001', 'F');

		$pdf->SetFont('', 'B', $default_font_size);
		$pdf->SetTextColor(255, 255, 255);

		$pdf->SetXY($this->posxdesc, $posy + 1);
		$pdf->MultiCell($this->posxtva - $this->posxdesc, 9, "ITEM", 0, 'L');

		$pdf->SetLineStyle(array('dash' => '1,1', 'color' => array(255, 255, 255)));
		$pdf->line($this->posxtva - 0.5, $posy, $this->posxtva - 0.5, $posy + 10);

		if (!getDolGlobalString('MAIN_GENERATE_DOCUMENTS_WITHOUT_VAT') && !getDolGlobalString('MAIN_GENERATE_DOCUMENTS_WITHOUT_VAT_COLUMN')) {
			$pdf->SetXY($this->posxtva, $posy + 1);
			$pdf->MultiCell($this->posxup - $this->posxtva, 9, "ICMS / IMPOSTO", 0, 'C');
			$pdf->line($this->posxup - 0.5, $posy, $this->posxup - 0.5, $posy + 10);
		}

		$pdf->SetXY($this->posxup, $posy + 1);
		$pdf->MultiCell($this->posxqty - $this->posxup, 9, dol_strtoupper($outputlangs->transnoentities("PriceUHT")), 0, 'C');
		$pdf->line($this->posxqty - 0.5, $posy, $this->posxqty - 0.5, $posy + 10);

		$pdf->SetXY($this->posxqty, $posy + 1);
		$pdf->MultiCell($this->posxunit - $this->posxqty, 9, dol_strtoupper($outputlangs->transnoentities("Qty")), 0, 'C');
		$pdf->line($this->posxunit - 0.5, $posy, $this->posxunit - 0.5, $posy + 10);

		if (getDolGlobalInt('PRODUCT_USE_UNITS') && $this->posxunit < $this->posxdiscount) {
			$pdf->SetXY($this->posxunit, $posy + 1);
			$pdf->MultiCell($this->posxdiscount - $this->posxunit, 9, dol_strtoupper($outputlangs->transnoentities("Unit")), 0, 'C');
		}
		$pdf->line($this->posxdiscount - 0.5, $posy, $this->posxdiscount - 0.5, $posy + 10);

		if ($this->atleastonediscount) {
			$pdf->SetXY($this->posxdiscount, $posy + 1);
			$pdf->MultiCell($this->postotalht - $this->posxdiscount, 9, dol_strtoupper($outputlangs->transnoentities("Reduction")), 0, 'C');
		}
		$pdf->line($this->postotalht - 0.5, $posy, $this->postotalht - 0.5, $posy + 10);

		$pdf->SetXY($this->postotalht, $posy + 0.5);
		$pdf->MultiCell($this->page_largeur - $this->marge_droite - $this->postotalht, 4, "TOTAL GERAL\nS/ IMPOSTOS", 0, 'C');

		$pdf->SetLineStyle(array('dash' => 0));

		$pdf->SetTextColor(0, 0, 0);
	}

	// phpcs:disable PEAR.NamingConventions.ValidFunctionName.ScopeNotCamelCaps
	/**
	 *  Show footer of page
	 *
	 *  @param	TCPDF		$pdf            Object PDF
	 *  @param  Propal		$object         Object to show
	 *  @param  Translate	$outputlangs    Object langs for output
	 *  @param	int			$hidefreetext	1=Hide free text
	 *  @return	int							Return height of bottom margin including footer text
	 */
	protected function _pagefoot(&$pdf, $object, $outputlangs, $hidefreetext = 0)
	{
		// phpcs:enable
		$showdetails = getDolGlobalInt('MAIN_GENERATE_DOCUMENTS_SHOW_FOOT_DETAILS', 0);
		return pdf_pagefoot($pdf, $outputlangs, 'PROPOSAL_FREE_TEXT', $this->emetteur, $this->marge_basse, $this->marge_gauche, $this->page_hauteur, $object, $showdetails, $hidefreetext, $this->page_largeur, $this->watermark);
	}

	// phpcs:disable PEAR.NamingConventions.ValidFunctionName.ScopeNotCamelCaps
	/**
	 *   Show signature area
	 *
	 *   @param	TCPDF		$pdf            Object PDF
	 *   @param  Propal		$object         Object to show
	 *   @param  float		$posy           Position y
	 *   @param  Translate	$outputlangs    Object langs
	 *   @return float                       Return new posy
	 */
	protected function _signature_area(&$pdf, $object, $posy, $outputlangs)
	{
		// phpcs:enable
		global $conf, $mysoc;

		// Y coordinates calculated from page height to match onlineSign.php (yforimgstart = page_height - 60)
		$box_y = $this->page_hauteur - 60;   // e.g. 297 - 60 = 237mm for A4 — matches onlineSign.php
		$label_y = $box_y - 4;               // 4mm above the box

		$box_width = 112;
		$posx_sig = ($this->page_largeur - $box_width) / 2; // = (210 - 112) / 2 = 49mm, matches xforimgstart

		// Text above signature box
		$pdf->SetFont('', '', 5);
		$pdf->SetTextColor($this->text_color[0], $this->text_color[1], $this->text_color[2]);
		$pdf->SetXY($posx_sig, $label_y);
		$pdf->MultiCell($box_width, 4, "ASSINATURA DO CLIENTE", 0, 'C');

		// Signature Box at fixed Y=237mm matching rubrica placement
		$pdf->SetDrawColor($this->secondary_color[0], $this->secondary_color[1], $this->secondary_color[2]);
		$pdf->RoundedRect($posx_sig, $box_y, $box_width, 40, $this->corner_radius, '1234', 'D');

		$posy = $box_y + 42;

		$pdf->SetTextColor(0, 0, 0);

		return $posy;
	}

	/**
	 *    getExtrafieldsInHtml
	 *
	 *    @param    Propal        $object        Object proposal
	 *    @param    Translate    $outputlangs    Object langs
	 *    @return   string                            HTML code
	 */
	public function getExtrafieldsInHtml($object, $outputlangs, $params = [])
	{
		global $conf, $langs, $db;

		$output = '';
		if (!isModEnabled('extrafields')) {
			return $output;
		}

		$object->fetch_optionals();

		$line = $object;
		$line->fetch_optionals($line->id);

		if (!empty($line->array_options)) {
			foreach ($line->array_options as $key => $value) {
				if (!empty($value)) {
					$output .= $line->show_optionals($line->extrafields, $outputlangs, array('class' => 'table_%(class)s'), $key);
				}
			}
		}

		return $output;
	}
}
