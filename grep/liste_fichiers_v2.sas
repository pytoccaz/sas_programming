/******************************************************************************  
* Programme          : LIST_FILE
*
* Mots clef			 : recherche textuelle, Recursivite, call execute, parsing
*
* Auteur             : obe
*
* Date 			     : juillet 2010
*
* Objectif           : Lister les fichiers d'une arborescence 
*
*
* Parametres         : chemin       ----> repertoire racine 
*					   extension    ----> extension des fichiers cible ex: sas, txt, csv	
*					   sous_dossier ----> recherche sur les sous-dossiers (1 par defaut ou 0)	
*					   ajout        ----> parametre technique de suppression de la table de sortie. 
*										  Peut etre passe a 1 pour compiler les resultats de plusieurs recherches.
*						
* Sortie            : table WORK.liste_fichier
*						   colonnes : fichier  ---> nom du fichier
*									  dossier  ---> nom du dossier
*
******************************************************************************/

%macro LIST_FILE(chemin, extension, ajout=0, sous_dossier=1);

	
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


%let saveOptions = %sysfunc(getoption(MPRINT)) %sysfunc(getoption(SOURCE)) 
					%sysfunc(getoption(NOTES))  %sysfunc(getoption(SYMBOLGEN))
					%sysfunc(getoption(MACROGEN))	;

options nomprint nosource nonotes NOSYMBOLGEN NOMACROGEN;



%if ^%missing(&extension.) %then %do;
	%if %bquote(&extension.) eq %bquote(*) or %bquote(&extension.) eq %bquote(*.*) %then %let _selection_fichier=1;
	%else %do;
		/* reverse de l'extension  */
		%let noisnetxe=%sysfunc(lowcase(&extension.), $revers%sysfunc(length(%str(&extension.))).);
		/* clause de selection du fichier */
		%let _selection_fichier="&noisnetxe." =: lowcase(reverse(strip(fichier)));
	%end;
%end;
%else %let _selection_fichier=1;



 %if &ajout. eq 0 %then %do; 
	proc datasets lib=work nolist;
		delete liste_fichier (memtype=DATA);
	quit;
 %end; 


		%macro _dummy(chemin);
		 /* liste des fichiers et des dossiers du repertoire &chemin */

data _temp_liste_fichier (keep=repertoire chemin fichier) _temp_liste_dossier (keep=chemin);
length repertoire chemin  $256. fichier $128. ;
rc=filename('frep',"&chemin");
did=dopen('frep');
if did then do;
	memcnt=DNUM(did);
		do i=1 to memcnt;
			chemin=" ";	
			did_s=.;
			fichier=dread(did,i);
			repertoire="&chemin.";
			chemin=cats("&chemin./", fichier);

			if (   	&_selection_fichier. ) 
				then do; 
					rc=filename('frep0', chemin);
					if rc eq 0 then do;
						did_s=dopen('frep0');
						rc=dclose(did_s);
						if did_s then output _temp_liste_dossier; /* sortie si repertoire => examen du fichier suivant */
						else output _temp_liste_fichier;
					end;
			end;
			else do;
				rc=filename('frep1',chemin);
				put chemin=;
				put rc=;
				if rc eq 0 then do;
					did_s=dopen('frep1');
					put did_s=;
					if did_s then output _temp_liste_dossier;
					rc=dclose(did_s);
				end;
			end; 
		end;
end;
else put "ERROR: &chemin n'est pas un nom de repertoire existant.";
rc=dclose(did);
RUN;

proc append data=_temp_liste_fichier  base=liste_fichier;
run;


		%if &sous_dossier. eq 1 %then %do;
		/* auto execution sur sous-dossiers de &chemin */
			data _null_;
			set  _temp_liste_dossier nobs=nbobs;
			call execute(cats('%_dummy(', chemin, ");"));
			run;
		%end;
		%mend _dummy;

/* lancement du programme parseur  */
%_dummy(&chemin.);

proc datasets nolist; delete _temp_liste_fichier _temp_liste_dossier  ; quit;
options &saveOptions;

 %mend  LIST_FILE;

/*
 %LIST_FILE(/SOF/sim/database, *) ; 
*/