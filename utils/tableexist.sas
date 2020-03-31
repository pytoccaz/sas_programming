/******************************************************************************************************
	Programme: tableexist
	Auteur: obe (lincoln)
	Date: 23/09/2014
 
	Test d'existence d'une table ou d'une vue
*****************************************************************************************************/

%macro tableExist(TABLE);
	%sysevalf(%sysfunc(exist(&TABLE.)) OR %sysfunc(exist(&TABLE., VIEW))) 
%mend;