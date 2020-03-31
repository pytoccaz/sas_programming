/******************************************************************************************************
	Programme: ar_item (famille des macro AR)
	Auteur: obe (lincoln)
	Date: 28/11/2014
 
	Desc: la macro ar_item renvoie la valeur d'un item d'un objet AR
			 
	Param: label = nom de l'objet AR
		   var = variable identifiant l'item
		   pos= rang au sein de l'objet de la valeurs a recuperer (parametre utile aux macros NLAG)
 						
	Note: peut etre utilise en lecture (<variable>=%ar_item...) ou ecriture (%ar_item...=<grandeur SAS>)
	
 *****************************************************************************************************/

%macro ar_item(label, var=, pos=1);

	/* si liste var manque table_ref fournit la liste des variables */
	%if %missing(&var.) %then %do;

			%put (ar_item &label) Aucun item specifie via <var>.;
			%return;

	%end;
	
 	&label._&VAR.(&pos.) 
	
%mend;
