/******************************************************************************************************
	Programme: ar_put (famille des macro AR)
	Auteur: obe (lincoln)
	Date: 17/10/2014
 
	Desc: put des valeurs chargees dans les items d'un objet AR
			 
	Param: label = nom de l'objet AR
		   list_var = liste des variables a charger (optionnel) 
		   table_ref= table de reference de liste de variable (obligatoire si list_var est vide)
 		   pos= rang affiche (parametre utile aux macros ar_\w+_lag)
		Priorite des parametres: 

						list_var > table_ref
						

 *****************************************************************************************************/

%macro ar_put(label
				, list_var=
				, table_ref=
				, pos=1
);

 
	/* si liste var manque table_ref fournit la liste des variables */
	%if %missing(&list_var.) %then %do;

		%if %missing(&table_ref) %then %do;
			%put (ar_put &label) Aucun item specifie via <list_var> ou <table_ref>;
			%return;
		%end;
		%else %if ^%tableexist(&table_ref.) %then %do;
			/* controle existance de table_ref */
			%put ERROR: (ar_put &label) la table &table_ref est introuvable.;
			%return;
		%end;

		 %let list_var=%for(NAME, in={&table_ref}, do=%nrstr(&NAME));		

	%end;
	
	/* chargement */
	put
	%for(VAR, in=(&list_var.), do=%nrstr(&label._&VAR.(&pos.)=));
	
%mend;
