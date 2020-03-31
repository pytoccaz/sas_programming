 /******************************************************************************************************
	Programme: ar_declare (famille des macro AR)
	Auteur: obe (lincoln)
	Date: 17/10/2014
 
	Desc	: 	Declaration d'un objet de retain de masse constitue de 
				plusieurs array temporaires de dimension 1 appelees items et liees chacun a une variable du PDV

				Chaque item sert a retenir la valeur de variable a laquelle il est lie.

				Le lien entre un item AR et sa variable se fait par le nom de la variable :
				La variable TOTO sera liee a l'item <label>_TOTO(1).


				Les valeurs des variables liees sont enregistrees dans l'objet sous l'action de la macro ar_charge.
				Les valeurs sont recuperees dans les variables liees (ou dans d'autres variables) sous l'action de 
				la macro ar_decharge.
			 
	Param	: 	label = identifiant de l'objet
			   	list_var = liste des variables eligibles (optionnel)
				list_length= liste des longueurs des variables (optionnel)
								Si une seule longueur alors cette longueur vaut pour toutes les variables de list_var

				table_ref= table de reference des variables (optionnel)
							et des longueurs de variables (si list_length est vide)
				
				dim= dimension des arrays formant l'objet (parametre utile aux macros AR_NLAG)
	
				list_var et table_ref vides desactivent la macro (return)
		


	Priorite des parametres: 

			 	list_var>table_ref  
				list_length>table_refest specifiee (si list_var est non vide) 
				
				si list_var est manquant alors list_length n'a pas d'effet: toute l'information 
				des attributs provient de table_ref

	Note	: 	la macro ar_charge permet de charger l'objet AR
				et la macro ar_decharge permet de decharger ses valeurs dans le PDV.
	
 *****************************************************************************************************/

%macro ar_declare(label
					, list_var=
					, list_length=
					, table_ref=
					, dim=1
);

/* ne rien faire si pas de specification de variable */
%if %missing(&table_ref) and %missing(&list_var) %then %do;
	%put (ar_declare &label) Auncune variable specifiee via <list_var> ou <table_ref>.;
	%return;
%end;


/* controle existence de table_ref */
%if ^%missing(&table_ref) %then %do;
	%if ^%tableexist(&table_ref.) %then %do;
		%put ERROR: (ar_declare &label) la table &table_ref est introuvable.;
		%return;
	%end;
%end;


/* list_var vide =>recuperation des variables et de leur longueur depuis table_ref */
%if %missing(&list_var.) %then %do;
	%let list_var=%for(NAME, in={&table_ref}, do=%nrstr(&NAME));	
	%let list_length=%for(VAR, in=(&list_var.), do=%nrstr(%mgetlength(&VAR, &table_ref.)));
%end;


%if %missing(&list_length) %then %do;
	%if %missing(&table_ref) %then %do;
		%put ERROR: (ar_declare &label) les longueurs de stockage doivent etre specifiees via <table_ref> ou <list_length>.;
		%return;
	%end;
	
	/* recuperation des longueurs depuis table_ref */	
	%let list_length=%for(VAR, in=(&list_var.), do=%nrstr(%mgetlength(&VAR, &table_ref.)));
%end;
%else %if %num_tokens(&list_length.) EQ 1 %then %do;
	/* length vaut pour toutes les variables */	
	%let list_length=%sysfunc(repeat(%str(&list_length. ), %num_tokens(&list_var.)-1));	
%end;


/* construit les array temporaires de recuperation */
%local _var_length;
%let _var_length=%parallel_join(&list_var., &list_length., %str( ));
%for(VAR LEN, in=(&_var_length.), do=%nrstr(ARRAY &label._&VAR.(&dim.) &LEN. _TEMPORARY_ ;))


/* emission pour chaque variable d'une macro variable de mme nom se resolvant en l'item de stockage associee  */

%for(VAR, in=(&list_var.), do=%nrstr(%GLOBAL &VAR; %let &VAR=&label._&VAR.(1) ;))


%mend;