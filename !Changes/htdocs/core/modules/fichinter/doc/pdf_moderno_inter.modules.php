<?php
/* Copyright (C) 2024 Your Name <your.email@example.com>
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

/**
 *	\file       htdocs/core/modules/fichinter/doc/pdf_moderno_inter.modules.php
 *	\ingroup    ficheinter
 *	\brief      File of Class to build interventions documents with model Moderno
 */
require_once DOL_DOCUMENT_ROOT.'/core/modules/fichinter/modules_fichinter.php';
require_once DOL_DOCUMENT_ROOT.'/core/lib/company.lib.php';
require_once DOL_DOCUMENT_ROOT.'/core/lib/pdf.lib.php';
require_once DOL_DOCUMENT_ROOT.'/core/lib/date.lib.php';
require_once DOL_DOCUMENT_ROOT.'/core/lib/functions2.lib.php';


/**
 *	Class to build interventions documents with model Moderno
 */
class pdf_moderno_inter extends ModelePDFFicheinter
{
	/**
	 * @var DoliDB Database handler
	 */
	public $db;

	/**
	 * @var string model name
	 */
	public $name;

	/**
	 * @var string model description (short text)
	 */
	public $description;

	/**
	 * @var int     Save the name of generated file as the main doc when generating a doc with this template
	 */
	public $update_main_doc_field;

	/**
	 * @var string document type
	 */
	public $type;

	/**
	 * Dolibarr version of the loaded document
	 * @var string Version, possible values are: 'development', 'experimental', 'dolibarr', 'dolibarr_deprecated' or a version string like 'x.y.z'''|'development'|'dolibarr'|'experimental'
	 */
	public $version = 'dolibarr';

	public $primary_color = array(67, 144, 220); // #4390dc
	public $text_color = array(255, 255, 255);
	public $light_bg = array(248, 248, 248);


	/**
	 *	Constructor
	 *
	 *  @param		DoliDB		$db      Database handler
	 */
	public function __construct($db)
	{
		global $langs, $mysoc;

		$this->db = $db;
		$this->name = 'moderno_inter';
		$this->description = $langs->trans("DocModelModernoDescription");
		$this->update_main_doc_field = 1; // Save the name of generated file as the main doc when generating a doc with this template

		// Page size for A4 format
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
		$this->option_logo = 1; // Display logo
		$this->option_tva = 0; // Manage the vat option FACTURE_TVAOPTION
		$this->option_modereg = 0; // Display payment mode
		$this->option_condreg = 0; // Display payment terms
		$this->option_multilang = 1; // Available in several languages
		$this->option_draft_watermark = 1; // Support add of a watermark on drafts
		$this->watermark = '';

		// Define position of columns
		$this->posxdesc = $this->marge_gauche + 1;

		if ($mysoc === null) {
			dol_syslog(get_class($this).'::__construct() Global $mysoc should not be null.'. getCallerInfoString(), LOG_ERR);
			return;
		}

		// Get source company
		$this->emetteur = $mysoc;
		if (empty($this->emetteur->country_code)) {
			$this->emetteur->country_code = substr($langs->defaultlang, -2); // By default, if not defined
		}
	}

	/**
	 *  Function to build pdf onto disk
	 *
	 *  @param		Fichinter		$object				Object to generate
	 *  @param		Translate		$outputlangs		Lang output object
	 *  @param		string			$srctemplatepath	Full path of source filename for generator using a template file
	 *  @param		int<0,1>		$hidedetails		Do not show line details
	 *  @param		int<0,1>		$hidedesc			Do not show desc
	 *  @param		int<0,1>		$hideref			Do not show ref
	 *  @return		int<-1,1>							1=OK,<=0 => KO
	 */
	public function write_file($object, $outputlangs, $srctemplatepath = '', $hidedetails = 0, $hidedesc = 0, $hideref = 0)
	{
		global $user, $langs, $conf, $mysoc, $db, $hookmanager;

		if (!is_object($outputlangs)) {
			$outputlangs = $langs;
		}
		// For backward compatibility with FPDF, force output charset to ISO, because FPDF expect text to be encoded in ISO
		if (getDolGlobalString('MAIN_USE_FPDF')) {
			$outputlangs->charset_output = 'ISO-8859-1';
		}

		// Load traductions files required by page
		$outputlangs->loadLangs(array("main", "interventions", "dict", "companies", "compta"));

		// Show Draft Watermark
		if ($object->status == $object::STATUS_DRAFT && (getDolGlobalString('FICHINTER_DRAFT_WATERMARK'))) {
			$this->watermark = getDolGlobalString('FICHINTER_DRAFT_WATERMARK');
		}

		if ($conf->ficheinter->dir_output) {
			$object->fetch_thirdparty();

			// Definition of $dir and $file
			if ($object->specimen) {
				$dir = $conf->ficheinter->dir_output;
				$file = $dir."/SPECIMEN.pdf";
			} else {
				$objectref = dol_sanitizeFileName($object->ref);
				$dir = $conf->ficheinter->dir_output."/".$objectref;
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
				$reshook = $hookmanager->executeHooks('beforePDFCreation', $parameters, $object, $action); // Note that $action and $object may have been modified by some hooks

				// Create pdf instance
				$pdf = pdf_getInstance($this->format);
				$default_font_size = pdf_getPDFFontSize($outputlangs); // Must be after pdf_getInstance
				$heightforinfotot = 60; // Height reserved to output the info and total part
				$heightforfreetext = getDolGlobalInt('MAIN_PDF_FREETEXT_HEIGHT', 5); // Height reserved to output the free text on last page
				$heightforfooter = $this->marge_basse + 8; // Height reserved to output the footer (value include bottom margin)
				if (getDolGlobalString('MAIN_GENERATE_DOCUMENTS_SHOW_FOOT_DETAILS')) {
					$heightforfooter += 6;
				}
				$pdf->setAutoPageBreak(true, 0);

				if (class_exists('TCPDF')) {
					$pdf->setPrintHeader(false);
					$pdf->setPrintFooter(false);
				}
				$pdf->SetFont(pdf_getPDFFont($outputlangs));
				// Set path to the background PDF File
				if (getDolGlobalString('MAIN_ADD_PDF_BACKGROUND')) {
					$pdf->setSourceFile($conf->mycompany->dir_output.'/' . getDolGlobalString('MAIN_ADD_PDF_BACKGROUND'));
					$tplidx = $pdf->importPage(1);
				}

				$pdf->Open();
				$pagenb = 0;
				$pdf->SetDrawColor(128, 128, 128);

				$pdf->SetTitle($outputlangs->convToOutputCharset($object->ref));
				$pdf->SetSubject($outputlangs->transnoentities("InterventionCard"));
				$pdf->SetCreator("Dolibarr ".DOL_VERSION);
				$pdf->SetAuthor($outputlangs->convToOutputCharset($user->getFullName($outputlangs)));
				$pdf->SetKeyWords($outputlangs->convToOutputCharset($object->ref)." ".$outputlangs->transnoentities("InterventionCard"));
				if (getDolGlobalString('MAIN_DISABLE_PDF_COMPRESSION')) {
					$pdf->SetCompression(false);
				}

				$pdf->SetMargins($this->marge_gauche, $this->marge_haute, $this->marge_droite); // Left, Top, Right

				// New page
				$pdf->AddPage();
				if (!empty($tplidx)) {
					$pdf->useTemplate($tplidx);
				}
				$pagenb++;
				$this->_pagehead($pdf, $object, 1, $outputlangs);
				$pdf->SetFont('', '', $default_font_size - 1);
				$pdf->SetTextColor(0, 0, 0);

				$tab_top = 100;
				$tab_top_newpage = (!getDolGlobalInt('MAIN_PDF_DONOTREPEAT_HEAD') ? 42 : 10);

				$tab_height = $this->page_hauteur - $tab_top - $heightforfooter - $heightforfreetext;

				// Display notes
				$notetoshow = empty($object->note_public) ? '' : $object->note_public;
				if ($notetoshow) {
					$substitutionarray = pdf_getSubstitutionArray($outputlangs, null, $object);
					complete_substitutions_array($substitutionarray, $outputlangs, $object);
					$notetoshow = make_substitutions($notetoshow, $substitutionarray, $outputlangs);
					$notetoshow = convertBackOfficeMediasLinksToPublicLinks($notetoshow);

					$pdf->SetFont('', '', $default_font_size - 1);
					$pdf->writeHTMLCell(190, 3, $this->posxdesc - 1, $tab_top, dol_htmlentitiesbr($notetoshow), 0, 1);
					$nexY = $pdf->GetY();
					$height_note = $nexY - $tab_top;

					// Rect takes a length in 3rd parameter
					$pdf->SetDrawColor(192, 192, 192);
					$pdf->RoundedRect($this->marge_gauche, $tab_top - 1, $this->page_largeur - $this->marge_gauche - $this->marge_droite, $height_note + 2, $this->corner_radius, '1111', 'D');

					$tab_height -= $height_note;
					$tab_top = $nexY + 6;
				} else {
					$height_note = 0;
				}

				$curY = $tab_top + 7;
				$nexY = $tab_top + 7;

				// Table Header
				$pdf->SetXY($this->marge_gauche, $tab_top);
				$pdf->SetFillColor($this->primary_color[0], $this->primary_color[1], $this->primary_color[2]);
				$pdf->RoundedRect($this->marge_gauche, $tab_top, $this->page_largeur - $this->marge_gauche - $this->marge_droite, 7, $this->corner_radius, '1111', 'F');
				
				$title_table = dol_strtoupper($outputlangs->transnoentities("Description"));
				$pdf->SetFont('', 'B', $default_font_size);

				// Shadow for Table Header (Subtle 0.15mm offset)
				$pdf->SetXY($this->marge_gauche + 0.15, $tab_top + 0.15);
				$pdf->SetTextColor(0, 0, 0);
				$pdf->MultiCell(190, 7, $title_table, 0, 'C', false, 1, '', '', true, 0, false, true, 7, 'M');
				
				// Main Text for Table Header
				$pdf->SetXY($this->marge_gauche, $tab_top);
				$pdf->SetTextColor(255, 255, 255);
				$pdf->MultiCell(190, 7, $title_table, 0, 'C', false, 1, '', '', true, 0, false, true, 7, 'M');
				
				$pdf->SetTextColor(0, 0, 0);
				$pdf->SetFont('', '', $default_font_size - 1);

				$pdf->SetXY($this->marge_gauche, $tab_top + 7);
				$text = $object->description;
				if ($object->duration > 0) {
					$totaltime = convertSecondToTime($object->duration, 'all', getDolGlobalString('MAIN_DURATION_OF_WORKDAY'));
					$text .= ($text ? ' - ' : '').$langs->trans("Total").": ".$totaltime;
				}
				$desc = dol_htmlentitiesbr($text, 1);

				$pdf->writeHTMLCell(180, 3, $this->posxdesc - 1, $tab_top + 8, $outputlangs->convToOutputCharset($desc), 0, 1);
				$nexY = $pdf->GetY() + 2;

				$pdf->SetLineStyle(array('dash' => '1,1', 'color' => array(100, 100, 100)));
				$pdf->line($this->marge_gauche, $nexY, $this->page_largeur - $this->marge_droite, $nexY);
				$pdf->SetLineStyle(array('dash' => 0));

				$nblines = count($object->lines);

				// Loop on each lines
				for ($i = 0; $i < $nblines; $i++) {
					$objectligne = $object->lines[$i];

					$valide = empty($objectligne->id) ? 0 : $objectligne->fetch($objectligne->id);
					if ($valide > 0 || $object->specimen) {
						$curY = $nexY;
						$pdf->SetFont('', '', $default_font_size - 1); // Into loop to work with multipage
						$pdf->SetTextColor(0, 0, 0);

						$pdf->setTopMargin($tab_top_newpage);
						$pdf->setPageOrientation('', true, $heightforfooter + $heightforfreetext + $heightforinfotot); // The only function to edit the bottom margin of current page to set it.
						$pageposbefore = $pdf->getPage();

						// Description of product line
						$curX = $this->posxdesc - 1;

						// Description of product line
						if (!getDolGlobalString('FICHINTER_DATE_WITHOUT_HOUR')) {
							$txt = $outputlangs->transnoentities("Date")." : ".dol_print_date($objectligne->datei, 'dayhour', false, $outputlangs, true);
						} else {
							$txt = $outputlangs->transnoentities("Date")." : ".dol_print_date($objectligne->datei, 'day', false, $outputlangs, true);
						}

						if ($objectligne->duration > 0) {
							$txt .= " - ".$outputlangs->transnoentities("Duration")." : ".convertSecondToTime($objectligne->duration);
						}
						$txt = '<strong>'.dol_htmlentitiesbr($txt, 1, $outputlangs->charset_output).'</strong>';
						$desc = dol_htmlentitiesbr($objectligne->desc, 1);

						$pdf->startTransaction();
						$pdf->writeHTMLCell(0, 0, $curX, $curY + 1, dol_concatdesc($txt, $desc), 0, 1, false);
						$pageposafter = $pdf->getPage();
						if ($pageposafter > $pageposbefore) {	// There is a pagebreak
							$pdf->rollbackTransaction(true);
							$pdf->setPageOrientation('', true, $heightforfooter); // The only function to edit the bottom margin of current page to set it.
							$pdf->writeHTMLCell(0, 0, $curX, $curY, dol_concatdesc($txt, $desc), 0, 1, false);
							$pageposafter = $pdf->getPage();
							$posyafter = $pdf->GetY();
							if ($posyafter > ($this->page_hauteur - ($heightforfooter + $heightforfreetext + $heightforinfotot))) {	// There is no space left for total+free text
								if ($i == ($nblines - 1)) {	// No more lines, and no space left to show total, so we create a new page
									$pdf->AddPage('', '', true);
									if (!empty($tplidx)) {
										$pdf->useTemplate($tplidx);
									}
									if (!getDolGlobalInt('MAIN_PDF_DONOTREPEAT_HEAD')) {
										$this->_pagehead($pdf, $object, 0, $outputlangs);
									}
									$pdf->setPage($pageposafter + 1);
								}
							}
						} else { // No pagebreak
							$pdf->commitTransaction();
						}

						$nexY = $pdf->GetY() + 2;
						$pageposafter = $pdf->getPage();
						$pdf->setPage($pageposbefore);
						$pdf->setTopMargin($this->marge_haute);
						$pdf->setPageOrientation('', true, 0); // The only function to edit the bottom margin of current page to set it.

						// We suppose that a too long description is moved completely on next page
						if ($pageposafter > $pageposbefore) {
							$pdf->setPage($pageposafter);
							$curY = $tab_top_newpage;
						}

						$pdf->SetFont('', '', $default_font_size - 1); // We reposition the default font

						// Detect if some page were added automatically and output _tableau for past pages
						while ($pagenb < $pageposafter) {
							$pdf->setPage($pagenb);
							if ($pagenb == 1) {
								$this->_tableau($pdf, $tab_top, $this->page_hauteur - $tab_top - $heightforfooter, 0, $outputlangs, 0, 1, $object);
							} else {
								$this->_tableau($pdf, $tab_top_newpage, $this->page_hauteur - $tab_top_newpage - $heightforfooter, 0, $outputlangs, 1, 1, $object);
							}
							$this->_pagefoot($pdf, $object, $outputlangs, 1);
							$pagenb++;
							$pdf->setPage($pagenb);
							$pdf->setPageOrientation('', true, 0); // The only function to edit the bottom margin of current page to set it.
							if (!getDolGlobalInt('MAIN_PDF_DONOTREPEAT_HEAD')) {
								$this->_pagehead($pdf, $object, 0, $outputlangs);
							}
							if (!empty($tplidx)) {
								$pdf->useTemplate($tplidx);
							}
						}
						
						// Dotted line after each intervention line
						if ($i < ($nblines - 1)) {
							$pdf->SetLineStyle(array('dash' => '1,1', 'color' => array(100, 100, 100)));
							$pdf->line($this->marge_gauche, $nexY, $this->page_largeur - $this->marge_droite, $nexY);
							$pdf->SetLineStyle(array('dash' => 0));
						}
					}
				}

				// Show square
				if ($pagenb == 1) {
					$this->_tableau($pdf, $tab_top, $this->page_hauteur - $tab_top - $heightforinfotot - $heightforfreetext - $heightforfooter, 0, $outputlangs, 0, 0, $object);
				} else {
					$this->_tableau($pdf, $tab_top_newpage, $this->page_hauteur - $tab_top_newpage - $heightforinfotot - $heightforfreetext - $heightforfooter, 0, $outputlangs, 1, 0, $object);
				}

				$this->_pagefoot($pdf, $object, $outputlangs);
				if (method_exists($pdf, 'AliasNbPages')) {
					$pdf->AliasNbPages();
				}

				$pdf->Close();
				$pdf->Output($file, 'F');

				dolChmod($file);
				$this->result = array('fullpath' => $file);

				return 1;
			} else {
				$this->error = $langs->trans("ErrorCanNotCreateDir", $dir);
				return 0;
			}
		} else {
			$this->error = $langs->trans("ErrorConstantNotDefined", "FICHEINTER_OUTPUTDIR");
			return 0;
		}
	}

	/**
	 *   Show table for lines
	 *
	 *   @param		TCPDF		$pdf     		Object PDF
	 *   @param		float|int	$tab_top		Top position of table
	 *   @param		float|int	$tab_height		Height of table (rectangle)
	 *   @param		int			$nexY			Y
	 *   @param		Translate	$outputlangs	Langs object
	 *   @param		int			$hidetop		Hide top bar of array
	 *   @param		int			$hidebottom		Hide bottom bar of array
	 *   @param		?Fichinter	$object			FichInter Object
	 *   @return	void
	 */
	protected function _tableau(&$pdf, $tab_top, $tab_height, $nexY, $outputlangs, $hidetop = 0, $hidebottom = 0, $object = null)
	{
		$pdf->SetDrawColor(192, 192, 192);
		$pdf->RoundedRect($this->marge_gauche, $tab_top, $this->page_largeur - $this->marge_gauche - $this->marge_droite, $tab_height + 1, $this->corner_radius, '1111', 'D');

		if (empty($hidebottom)) {
			$employee_name = '';
			if (!empty($object)) {
				$arrayidcontact = $object->getIdContact('internal', 'INTERVENING');
				if (count($arrayidcontact) > 0) {
					$object->fetch_user($arrayidcontact[0]);
					$employee_name = $object->user->getFullName($outputlangs);
				}
			}

			$box_width = 112;
			$posx_sig = ($this->page_largeur - $box_width) / 2;

			// Label above the box
			$pdf->SetFont('', '', 5);
			$pdf->SetXY($posx_sig, 233);
			$label = $outputlangs->transnoentities("NameAndSignatureOfExternalContact");
			$label = rtrim($label, ': '); // Remove colon if present
			$pdf->MultiCell($box_width, 5, dol_strtoupper($label), 0, 'C', false);

			// Signature Box
			// We use Y=237 to align with standard digital signature placement in interventions
			$pdf->SetXY($posx_sig, 237);
			$pdf->RoundedRect($posx_sig, 237, $box_width, 40, $this->corner_radius, '1111', 'D');
		}
	}

	/**
	 *  Show top header of page.
	 *
	 *  @param	TCPDF		$pdf     		Object PDF
	 *  @param  Fichinter	$object     	Object to show
	 *  @param  int	    	$showaddress    0=no, 1=yes
	 *  @param  Translate	$outputlangs	Object lang for output
	 *  @return	float|int                   Return topshift value
	 */
	protected function _pagehead(&$pdf, $object, $showaddress, $outputlangs)
	{
		global $conf, $langs;

		$default_font_size = pdf_getPDFFontSize($outputlangs);

		pdf_pagehead($pdf, $outputlangs, $this->page_hauteur);

		$posx = $this->page_largeur - $this->marge_droite - 100;
		$posy = $this->marge_haute;

		// 1. Draw Blue Header Box (Only Top Corners Rounded)
		$pdf->RoundedRect($this->marge_gauche, $this->marge_haute, $this->page_largeur - $this->marge_gauche - $this->marge_droite, 35, $this->corner_radius, '12', 'F', null, $this->primary_color);

		$pdf->SetTextColor(255, 255, 255);
		$posx = $this->page_largeur - $this->marge_droite - 100;
		$posy = $this->marge_haute + 10;

		// 2. Logo (Centered inside blue box)
		$logo = $conf->mycompany->dir_output.'/logos/'.$this->emetteur->logo;
		if ($this->emetteur->logo && is_readable($logo)) {
			$height = 22; // Ideal height for centered logo
			$sizes = pdf_getSizeForImage($logo);
			if ($sizes['height'] > 0) {
				$w = $sizes['width'] * ($height / $sizes['height']);
				$logo_x = ($this->page_largeur - $w) / 2;
				$pdf->Image($logo, $logo_x, $this->marge_haute + 4, 0, $height);
			}
		}

		// 3. Title and Ref (Single line at the bottom left of blue box)
		$pdf->SetFont('', 'B', 11);
		$pdf->SetTextColor(255, 255, 255);
		$pdf->SetXY($this->marge_gauche + 5, $this->marge_haute + 30);
		$text = dol_strtoupper($outputlangs->transnoentities("InterventionCard"))." ".$object->ref;
		$pdf->MultiCell($this->page_largeur - $this->marge_gauche - $this->marge_droite - 10, 4, $text, 0, 'L');

		// 4. Date and Customer Info (Right side of blue box)
		$pdf->SetFont('', 'B', 10);
		$posx_right = $this->page_largeur - $this->marge_droite - 100;
		
		$pdf->SetXY($posx_right, $this->marge_haute + 5);
		$pdf->MultiCell(100, 4, dol_strtoupper($outputlangs->transnoentities("Date")).": ".dol_print_date($object->date, "day", false, $outputlangs, true), 0, 'R');

		if (!empty($object->ref_client)) {
			$pdf->SetXY($posx_right, $this->marge_haute + 30);
			$pdf->MultiCell(100, 4, dol_strtoupper($outputlangs->transnoentities("RefCustomer")) . ": " . $object->ref_client, 0, 'R');
		}

		$pdf->SetTextColor($this->text_color[0], $this->text_color[1], $this->text_color[2]);

		if ($showaddress) {
			// Sender properties
			$carac_emetteur = pdf_build_address($outputlangs, $this->emetteur, $object->thirdparty, '', 0, 'source', $object);

			// Recipient properties
			$usecontact = false;
			$arrayidcontact = $object->getIdContact('external', 'CUSTOMER');
			if (count($arrayidcontact) > 0) {
				$usecontact = true;
				$result = $object->fetch_contact($arrayidcontact[0]);
			}

			if ($usecontact && ($object->contact->socid != $object->thirdparty->id && (!isset($conf->global->MAIN_USE_COMPANY_NAME_OF_CONTACT) || getDolGlobalString('MAIN_USE_COMPANY_NAME_OF_CONTACT')))) {
				$thirdparty = $object->contact;
			} else {
				$thirdparty = $object->thirdparty;
			}

			$carac_client_name = pdfBuildThirdpartyName($thirdparty, $outputlangs);
			$carac_client = pdf_build_address($outputlangs, $this->emetteur, $object->thirdparty, (isset($object->contact) ? $object->contact : ''), ($usecontact ? 1 : 0), 'target', $object);

			// Address Boxes Positions
			$posy_addr = $this->marge_haute + 42;
			$total_width = $this->page_largeur - $this->marge_gauche - $this->marge_droite;
			$box_width = ($total_width / 2) - 5; // 5mm gap between boxes

			// Sender Box (Left)
			$pdf->SetFillColor($this->light_bg[0], $this->light_bg[1], $this->light_bg[2]);
			$pdf->RoundedRect($this->marge_gauche, $posy_addr, $box_width, 40, $this->corner_radius, '1111', 'F');
			$pdf->SetXY($this->marge_gauche + 2, $posy_addr + 2);
			$pdf->SetTextColor($this->primary_color[0], $this->primary_color[1], $this->primary_color[2]);
			$pdf->SetFont('', 'B', $default_font_size);
			$pdf->MultiCell($box_width - 4, 4, $this->emetteur->name, 0, 'L');
			$pdf->SetTextColor(0, 0, 0);
			$pdf->SetFont('', '', $default_font_size - 1);
			$pdf->MultiCell($box_width - 4, 4, $carac_emetteur, 0, 'L');

			// Recipient Box (Right)
			$posx_rec = $this->marge_gauche + $box_width + 10;
			$pdf->SetDrawColor(192, 192, 192);
			$pdf->RoundedRect($posx_rec, $posy_addr, $box_width, 40, $this->corner_radius, '1111', 'D');
			$pdf->SetXY($posx_rec + 2, $posy_addr + 2);
			$pdf->SetTextColor($this->primary_color[0], $this->primary_color[1], $this->primary_color[2]);
			$pdf->SetFont('', 'B', $default_font_size);
			$pdf->MultiCell($box_width - 4, 4, $carac_client_name, 0, 'L');
			
			$pdf->SetXY($posx_rec + 2, $pdf->GetY());
			$pdf->SetTextColor(0, 0, 0);
			$pdf->SetFont('', '', $default_font_size - 1);
			$pdf->MultiCell($box_width - 4, 4, $carac_client, 0, 'L');
		}

		return 0;
	}

	/**
	 *   	Show footer of page. Need this->emetteur object
	 *
	 *   	@param	TCPDF		$pdf     			PDF
	 * 		@param	Fichinter	$object				Object to show
	 *      @param	Translate	$outputlangs		Object lang for output
	 *      @param	int			$hidefreetext		1=Hide free text
	 *      @return	integer
	 */
	protected function _pagefoot(&$pdf, $object, $outputlangs, $hidefreetext = 0)
	{
		$showdetails = getDolGlobalInt('MAIN_GENERATE_DOCUMENTS_SHOW_FOOT_DETAILS', 0);
		return pdf_pagefoot($pdf, $outputlangs, 'FICHINTER_FREE_TEXT', $this->emetteur, $this->marge_basse, $this->marge_gauche, $this->page_hauteur, $object, $showdetails, $hidefreetext, $this->page_largeur, $this->watermark);
	}
}
