/******************************************************************************  
* Programme          : SCAN_REP_FILE

* Mots clef			 : recherche textuelle, Recursivite, call execute, parsing

* Auteur             : obe

* Creation		     : juillet 2010  

* Modifications		 : juillet 2013 - creation de la sous macro _dummy
									  %_dummy facilite la gestion des parametres et la fin de la macro enveloppe correspond 
										a la fin du parsing ce qui n'est pas le cas lorsqu'il n'y a pas encapsulation.

 					   aout 2013	- meilleur gestion du quoting des parametres string et ext.	


* Objectif           : Parser les fichiers d'une arborescence a la recherche d'une expression 

						 recherche par expression reguliere en specifiant regstring=1,
							exemples : 
			                     1) tous les formats de type caractere:  /\$\w+\./
						         2) toutes les macro-variables:  /&\w+\b/
						         3) tous les mots de 26 lettres (ou chiffres) :   /\b\w{26}\b/
								 4) mprint ou symbolgen :  /mpint|symbolgen/
                        La recherche n'est pas sensible � la casse si nocase=1.

* Parametres         : chemin       ----> repertoire racine 
					   ext		    ----> extension des fichiers cible ex: sas, txt, csv	
					   string         ----> texte a rechercher, a proteger en respectant le systeme de quoting sas 
											si presence de caractere de type quote,
											 par exemple pour rechercher <<l'abeille>>, les solutions suivantes sont toutes valables :
												"l'abeille", 'l''abeille', %bquote(l'abeille)												
					   sous_dossier ----> recherche sur les sous-dossiers (1 par defaut ou 0)	
					   ajout        ----> parametre technique de suppression de la table de sortie. 
										  Peut etre passe � 1 pour compiler les resultats de plusieurs recherches.
						regstring=1 ----> indique que string est une expression reguliere valide, a eventuellement proteger 
											selon le systeme de quoting sas 
						regext=1    ----> indique que l'extension est une expression reguliere valide
						nocase=0    ----> respect de la case


* Sortie            : table WORK.RESULTAT_RECHERCHE
						   colonnes : fichier  ---> nom du fichier
									  dossier  ---> nom du dossier
									  ligne    ---> ligne du fichier qui contient l'expression
									  no_ligne ---> numero de la ligne au sein du fichier

******************************************************************************/

%macro SCAN_REP_FILE(chemin, ext, string, ajout=0, sous_dossier=1, regext=0, regstring=0, nocase=1);

	
	%macro missing(param);
	/* meilleur code pour tester si param est vide */
	/*  
		source: Paper 022-2009
				IS THIS MACRO PARAMETER BLANK?

			Chang Y. Chung, Princeton University, Princeton, NJ
			John King, Ouachita Clinical Data Services, Mount Ida, AR
	*/
	%sysevalf(%superq(param)=,boolean)
	%mend missing;

/* desactivation des opts verbeuses */
%let saveOptions = %sysfunc(getoption(MPRINT)) %sysfunc(getoption(SOURCE)) 
					%sysfunc(getoption(NOTES))  %sysfunc(getoption(SYMBOLGEN))
					%sysfunc(getoption(MACROGEN))	;

options nomprint nosource nonotes NOSYMBOLGEN NOMACROGEN;

/* gestion de la case  */
%local i;
%if &nocase %then %let i=i;

/* protection des simples quotes */
%if &regstring.=0 %then %do;
	%if &string=%nrstr(%") or &string = %nrstr(%') %then %let string=%sysfunc(quote(&string.));
%end;

/* gestion du filtre sur l'extension des fichiers eligibles */
%if &regext. eq 0 %then %do;
	%if ^%missing(&ext.) %then %do;
		/* * ==> selection de tous les fichiers */
		%if %bquote(&ext.) eq %bquote(*) %then %let _selection_fichier=1;
		/* *.* ==> idem que pour unix */
		%else %if %bquote(&ext.) eq %bquote(*.*) %then %let _selection_fichier=index(fichier,'.');
		%else %do;
			/* recherche des fichiers se terminant par ext */
			/* reverse de l'extension  */
			%let txe=%sysfunc(lowcase(&ext.), $revers%sysfunc(length(%str(&ext.))).);
			/* clause de selection du fichier */
			%let _selection_fichier=dequote(resolve('&txe.')) =: lowcase(reverse(strip(fichier)));
		%end;
	%end;
	%else %let _selection_fichier=1; /* vide <=> * */
%end;
%else %let _selection_fichier=prxmatch(regext , strip(fichier)); /* gestion par regexp si regext=1 */		


 %if &ajout. eq 0 %then %do; 
 	/* suppression de la table des resultats */
	proc datasets lib=work nolist;
		delete resultat_recherche (memtype=DATA);
	quit;
 %end; 

 		/*
			MACRO procedant a la decouverte des repertoires et au parsing des fichiers		
 		*/
		%macro _dummy(chemin);
		 /* liste des fichiers et des dossiers du repertoire &chemin */
		data _temp_liste_fichier (keep=fichier ) _temp_liste_dossier (keep=chemin);
		length chemin  $256. fichier $128. ;
		
		/* decouverte des fichiers par regexp si demandee  */
		%if &regext. eq 1 %then %do;
				 retain regext;
				 if _n_=1 then do;
				   	 /* compilation de l'expression reguliere */
				 		regext=prxparse(dequote(resolve('&ext')));
						if regext eq . then do ; put "ERROR: ext / Expression reguliere incorrecte"; stop; end;
				 end;
		%end;
		
		/* ouverture du repertoire racine */	
		rc=filename('frep',"&chemin");
		did=dopen('frep');
		if did then do;
			/* parcours des membres */
			memcnt=DNUM(did);
				do i=1 to memcnt;
					chemin=" ";	
					did_s=.;
					/* recuperation du nom du membre */	
					fichier=dread(did,i);
					chemin=cats("&chemin./", fichier);

					 /* selection du membre par rapport a son extension */	
					 if (   
							&_selection_fichier. 
						) 
						then do; 
							/* controle si le membre est un repertoire */
							rc=filename('frep0', chemin);
							if rc eq 0 then do;
								did_s=dopen('frep0');
								rc=dclose(did_s);
								if did_s then do;
									output _temp_liste_dossier; /* recuperation dans la table des repertoires */
									rc=dclose(did_s);
								end;
								else output _temp_liste_fichier; /* recuperation si fichier */
								rc=filename('frep0', '');
							end;
					end;
					else do;
						/* controle si les fichiers rejetes sont des repertoires  */
						rc=filename('frep0',chemin);
						if rc eq 0 then do;
							did_s=dopen('frep0');
							if did_s then output _temp_liste_dossier; /* recuperation dans la table des repertoires */
							rc=dclose(did_s);
							rc=filename('frep0', '');
						end;
					end; 
				end;
		end;
		else put "ERROR: &chemin n'est pas un nom de repertoire existant.";
		rc=dclose(did); rc=filename('frep', '');
		RUN;

		/*
		 recherche de l'expression &string dans les fichiers 
		*/
		data _temp_scan ;

	 /* gestion recherche par regexp si regstring=1 */
	%if &regstring. eq 1 %then %do;
		 %if &regstring. eq 1 %then %do; 	retain reg;	%end;
		 if _n_=1 then do;
		   	 /* compilation de l'expression reguliere */
		 		reg=prxparse(cats(dequote(resolve('&string')), "&i"));
				if reg eq . then do ; put "ERROR: string / Expression reguliere incorrecte"; stop; end;
		 end;
	%end;
		 /* set des fichiers elus  */
		 set _temp_liste_fichier end=eof;

		 length dossier $256. ;
		 length file_ ligne $256. no_ligne 4;
		 file_ = cats("&chemin./", fichier); /* chemin complet du fichier */
		 dossier="&chemin.";
		  no_ligne=0;

		 /* infile de tous les fichiers les un apres les autres  */
		 infile indummy filevar=file_ truncover  end=done; 

		 /* lecture du contenu du fichier file_ */
		 do while(not done);
				input ligne $256. ;
				no_ligne+1;
	%if &regstring eq 1 %then %do;
				if prxmatch(reg,ligne) then output; /*  expression presente=> recuperation */
	%end;
	%else %do;
				if find(ligne, dequote(resolve('&string')), "&i") then output;
	%end;
		end;
		 
		 keep dossier fichier ligne no_ligne;

		 if eof then call prxfree(reg);
		run; 

		/* collecte des resultats  */
		proc append data=_temp_scan  base=resultat_recherche;
		run;


		%if &sous_dossier. eq 1 %then %do;
		/* recherche de l'expression &string dans les sous-dossiers de &chemin par recursivite */
			data _null_;
			set  _temp_liste_dossier nobs=nbobs;
			call execute(cats('%_dummy(', chemin, ");"));
			run;
		%end;
		%mend _dummy;

	/* lancement du programme parseur  */
	%_dummy(&chemin.);

	/* suppression des tables temporaires */
	proc datasets nolist; delete _temp_liste_fichier _temp_liste_dossier _temp_scan; quit;
	options &saveOptions;

 %mend SCAN_REP_FILE;


 /*%SCAN_REP_FILE(/travail/t03798,  .txt, """chat"" ""chien"" ", regstring=0, regext=0,  nocase=1) ; */




%SCAN_REP_FILE(C:\Users\bernard-oli\Desktop\wrk
/*Z:\Users\Projets\2016\ParBilanConso16 - 3134\04 - V1.3\05 - R7\1_Traitements SQL\TR_SCORE*/
/*C:\Users\bernard-oli\Desktop\wrk*/
,  ".sql"
, 'DUAL'
, regstring=0, regext=0,  nocase=1) ; 