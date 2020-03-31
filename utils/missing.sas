/******************************************************************************************************
	Programme: missing.sas
	Version: prototype

	Auteur: obe (lincoln)
	Date: 01/04/2013
	
	Desc: retourne 1 si param est manquant.    
  
	source: Paper 022-2009
			IS THIS MACRO PARAMETER BLANK?

		Chang Y. Chung, Princeton University, Princeton, NJ
		John King, Ouachita Clinical Data Services, Mount Ida, AR
 ******************************************************************************************************/


%macro missing(param);
	%sysevalf(%superq(param)=,boolean)
%mend;
