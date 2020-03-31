/******************************************************************************************************
	Programme: ar_decharge (famille des macro AR)
	Auteur: obe (lincoln)
	Date: 17/10/2014
 
	Desc: dechargement des items d'un objet AR dans leur variables liees ou dans d'autre variables du PDV.
			 
	Param	: 	label = identifiant de l'objet
				list_var = liste des variables endogenes a decharger (optionnel) 
				table_ref= table de reference des variables endogenes a decharger (obligatoire si list_var est vide)
				list_out= liste des variables de recuperation (optionnel). Par defaut les valeurs retenues sont
				dechargees dans les variables endogenes liees.
				prefix_out= creer des variables de recuperation en prefixant les variables endogenes
				suffix_out= creer des variables de recuperation en suffixant les variables endogenes	 
			    pos= rang au sein de l'objet des valeurs a charger (parametre utile aux macros ar_\w+_lag)

				list_var et table_ref vides desactivent la macro (return)

	Priorite des parametres: 

						 list_var > table_ref   

					     prefix_out = suffix_out > list_out
						
	Note: la macro ar_declare permet de declarer l'objet AR
			et la macro ar_charge permet de charger l'objet AR.
	
 *****************************************************************************************************/

%macro ar_decharge(label
					, list_var=
					, table_ref=
					, list_out=
					, prefix_out=
					, suffix_out=
					, pos=1
);


	/* prefix_out ne peut etre egale a <label>_ car alors il y a conflit de nommage entre la 
		variable de recuperation de la valeur de l'item et l'item lui-meme
	 */

	%if ^%missing(&prefix_out.) %then %do;
		%if %upcase(&label._) eq  %upcase(&prefix_out.) %then %do;
%put ERROR: (ar_decharge &label) <prefix_out> doit etre different de &label._ car ce label est reserve.;
			%return;
		%end;
	%end;


	/* si liste var manque table_ref fournit la liste des variables */
	%if %missing(&list_var.) %then %do;

		%if %missing(&table_ref) %then %do;
			%put (ar_decharge &label) Auncune variable specifiee via <list_var> ou <table_ref>.;
			%return;
		%end;
		%else %if ^%tableexist(&table_ref.) %then %do;
			/* controle existance de table_ref */
			%put ERROR: (ar_decharge &label) la table &table_ref est introuvable.;
			%return;
		%end;

		 %let list_var=%for(NAME, in={&table_ref}, do=%nrstr(&NAME));		

	%end;

	%if %missing(&list_out) %then %let list_out=&list_var.;

	%if ^%missing(&prefix_out) %then %do;
		%let list_out=%add_string(&list_out., &prefix_out, delim=%str( ), location=prefix);	
	%end;
	%if ^%missing(&suffix_out) %then %do;
		%let list_out=%add_string(&list_out., &suffix_out, delim=%str( ), location=suffix);	
	%end;

				
	 %let xlist=%parallel_join(&list_var, &list_out, %str( )); 
	
	/* dechargement */
	%for(VARIN VAROUT, in=(&xlist.), do=%nrstr(&VAROUT.=&label._&VARIN.(&pos.);))
	
%mend;
