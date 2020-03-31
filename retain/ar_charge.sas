/******************************************************************************************************
	Programme: ar_charge (famille des macro AR)
	Auteur: obe  
	Date: 17/10/2014
 
	Desc: chargement des items d'un objet AR
			 
	Param: label = identifiant de l'objet
		   list_var = liste des variables a charger (obligatoire si table_ref n'est pas specifiee) 
		   table_ref= table de reference de liste de variable (optionnel)
		   pos= rang au sein de l'objet des valeurs a charger (parametre utile aux macros NLAG)
		list_var et table_ref vides desactivent la macro (return)


	Priorite des parametres: 

						list_var > table_ref
						
	Note: la macro ar_declare permet de declarer l'objet AR
			et la macro ar_decharge permet de decharger les valeurs chargees dans le PDV.
	
 *****************************************************************************************************/

%macro ar_charge(label
				, list_var=
				, table_ref=
				, pos=1
);

 
	/* si liste var manque table_ref fournit la liste des variables */
	%if %missing(&list_var.) %then %do;

		%if %missing(&table_ref) %then %do;
      %put (ar_charge &label) Auncune variable specifiee via <list_var> ou <table_ref>.;
			%return;
		%end;
		%else %if ^%tableexist(&table_ref.) %then %do;
			/* controle existance de table_ref */
			%put ERROR: (ar_charge &label) la table &table_ref est introuvable.;
			%return;
		%end;
		 %let list_var=%for(NAME, in={&table_ref}, do=%nrstr(&NAME));		

	%end;
	
	/* chargement */
	%for(VAR, in=(&list_var.), do=%nrstr(&label._&VAR.(&pos.)=&VAR.;))
	
%mend;
