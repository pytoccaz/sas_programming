/******************************************************************************************************
	Programme: ar_vidange (famille des macro AR)
	Auteur: obe (lincoln)
	Date: 17/10/2014
 
	Desc: vidange des array AR
			 
	Param: 	label = identifiant de l'objet
		   	list_var = liste des array a vider (optionnel) 
		   	table_ref= table de reference de liste des array a vider (obligatoire si list_var est vide)

		Priorite des parametres: 

						 list_var > table_ref   			

 *****************************************************************************************************/

%macro ar_vidange(label, list_var=, table_ref=);


	/* si liste var manque table_ref fournit la liste des variables */
	%if %missing(&list_var.) %then %do;

		%if %missing(&table_ref) %then %do;
			%put (ar_vidange &label) Aucun item specifie via <list_var> ou <table_ref>;
			%return;
		%end;
		%else %if ^%tableexist(&table_ref.) %then %do;
			/* controle existance de table_ref */
			%put ERROR: (ar_vidange &label) la table &table_ref est introuvable.;
			%return;
		%end;

		 %let list_var=%for(NAME, in={&table_ref}, do=%nrstr(&NAME));		

	%end;


	/* vidange */
	%for(VAR, in=(&list_var.), do=%nrstr(call missing(of &label._&VAR.(*));))	

%mend;
