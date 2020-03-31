/******************************************************************************************************
	Programme: ar_compare (famille des macro AR)
	Auteur: obe (lincoln)
	Date: 25/11/2014
 
	Desc: la macro ar_compare permet de comparer des variables du PDV avec les variables conservee en memoire AR
			 
	Param: label = nom de l'objet AR
		   list_var = liste des variables a comparer (optionnel) 
		   table_ref= table de reference de liste de variable (optionnel)
		   methode= EGALITE ou DIFFERENCE 
		   pos= rang des valeurs a comparer  (parametre utile aux macros AR_NLAG)

		Priorite des parametres: 

						list_var > table_ref
						
	Note: 
	
 *****************************************************************************************************/

%macro ar_compare(label, list_var=, table_ref=, methode=EGAL, pos=1);

 	/* si liste var manque:
		soit table_ref fournit la liste des variables a comparer 
		a defaut de table_ref, la macro de comparaison renvoie une valeur manquante
	*/
	%if %missing(&list_var.) %then %do;

		%if %missing(&table_ref) %then %do;
			%put (ar_compare &label) Auncune variable specifiee via <list_var> ou <table_ref>.;
			
			/* retourne valeur manquante */
			.

			%return;
		%end;
		%else %if ^%tableexist(&table_ref.) %then %do;
			/* controle existance de table_ref */
			%put ERROR: (ar_compare &label) la table &table_ref est introuvable.;

			
			/* retourne valeur manquante */
			.


			%return;
		%end;
		

		 %let list_var=%for(NAME, in={&table_ref}, do=%nrstr(&NAME));		

	%end;
	
	/* comparaison */
	%if %upcase(%substr(&methode., 1, 4)) eq DIFF %then %do;
	NOT
	%end;

	(1  
	%for(VAR, in=(&list_var.), do=%nrstr(AND &label._&VAR.(&pos.)=&VAR.)))
 
	
%mend;
