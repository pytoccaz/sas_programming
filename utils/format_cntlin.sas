/******************************************************************************************************
	Programme: format_cntlin.sas
	Version: V1.0

	Auteur: obe
	Date: 01/04/2013

	Modification : obe - 06/06/2014 : gestion des tables cntlin vide

	Desc: macro de creation de format a partir de donnees SAS.
		  Utilisee pour creer les informats ALEX.

******************************************************************************************************/
%macro format_cntlin(cntlin /* table source du format */
					, where=1 /* clause de filtrage de la table cntlin */
					, type= /* val du type format (sans quoting) */
					, start= /* var|val start du format */
					, end=   /* var|val end du format */
					, label= /* var|val label du format */
					, sexcl= /* var|val sexl du format */
					, eexcl= /* var|val eexl du format */
					, other= /* val OTHER (avec quoting) */
					, hlo= /* var|val pour le HLO (autre que other) */
					, otherHlo="O" 	/* var| val du HLO pour other  */
					, otherStart= 	/* var| val du START pour le other  */
					, otherEnd= 	/* var| val du END pour le other  */
					, otherSexcl=   /* var| val du SEXCL pour le other  */
					, otherEecl=    /* var| val du START pour le other  */
					, fmt= /* var|val fmtname du format  */
					, lib=WORK /* var|val du catalogue */
					, by= /* var de sectorisation des formats */
					, sby= /* var de tri simple sans sectorisation */
					, nodup=0 /* 1 pour suppression des doublons sur le sby */
					, nodupby= /* obsolete: variable(s) supplementaire(s) de dedoublonnage si by ne suffit pas  */
					, default= /* var|val default */
					, length=/* var|val de longeur du format */
					, min= /* var|val min */
					, max= /* var|val max */
					, debug=0 /* val de debugage: 1 conserve les tables intermediaires */
				);

/*
	Macro de production de format a partir d'une table SAS.
	Auteur: obe (LINCOLN)
	Date: 01/04/2013	

	ATTENTION: pour dedoublonner on peut toujours utiliser le couple de parametres sby+nodup.
			   Quand il y a sectorisation (et donc utilisation du parametre by) on peut eventuellement se 
			   passer du parametre sby et utiliser le parametre nodup pour dedoublonner
			    par rapport aux variables de sectorisation; et si l'on a besoin d'introduire 
				des variables de dedoublonnage supplementaires, on peut utiliser le parametre 
				nodupby. Mais c'est déconseillé. Il vaut mieux toujours passer par une premiere 
				phase de dédoublonnage avec sby+nodup, puis by=. 



*/

/* macro de production de code */
%local m_clauseby m_if_last /*m_var_end*/;


/* table intermediaire de suppression des evenuelles observations logiques */
data _temp_sort;
	set &cntlin.;
	where &where.;
run;

/* si sby est non vide on prend sby, sinon (sby vide) alors si by est non vide sby=by
	sinon sby=vide
*/
%let sby=%sysfunc(coalescec(&sby., &by.));


%if ^%missing(&sby.) %then %do; 
	proc sort data=_temp_sort %if &nodup. %then %do; nodupkey %end; ;
	by &sby. &nodupby.;
	run;

	/* clause set sby */
	%let m_clauseby=by &sby.;
%end;

/* sectoristation des formats par by */
%if ^%missing(&by.) %then %do; 
proc sort data=_temp_sort ;
by &by. ;
run;

	/* clause set by */
	%let m_clauseby=by &by.;

	/* clause de fin de groupe */
	%let m_if_last=last.%scan(&by, -1);
%end;
%else %if ^%missing(&other.) %then %do;
	/* clause de fin de table */	
	%let m_if_last=last;

	/* var end */
	/*%let m_var_end=end=last;*/
%end;

data _prepare_fmt;
	if nb_obs>0 then set _temp_sort nobs=nb_obs /*&m_var_end.*/ end=last;
	&m_clauseby.;
	start=&start.;
	%if ^%missing(&end.) %then %do; end=&end.; %end;
	%else %do; end=start; %end;
	label=&label.;
	fmtname=&fmt.;
	type="&type.";
	%if ^%missing(&end.) %then %do; end=&end.; %end;
	%if ^%missing(&default.) %then %do; default=&default.; %end;
	%if ^%missing(&sexcl.) %then %do; sexcl=&sexcl.; %end;
	%if ^%missing(&eexcl.) %then %do; eexcl=&eexcl.; %end;
	%if ^%missing(&default.) %then %do; default=&default.; %end;
	%if ^%missing(&length.) %then %do; length=&length.; %end;
	%if ^%missing(&min.) %then %do; min=&min.; %end;
	%if ^%missing(&max.) %then %do; max=&min.; %end;
	%if ^%missing(&hlo.) %then %do; hlo=&hlo.; %end;
	if nb_obs>0 then output;

	%if ^%missing(&other.) %then %do; 
 		if &m_if_last. then do;
		  %if &otherhlo. eq "O" %then %do;    call missing(start, end); %end;
		  %if ^%missing(&otherStart.) %then %do;    start=&otherStart.; %end;
		  %if ^%missing(&otherEnd.) %then %do;    end=&otherEnd.; %end;
		  %if ^%missing(&otherSexcl.) %then %do;    sexcl=&otherSexcl.; %end;
		  %if ^%missing(&otherEecl.) %then %do;    eexcl=&otherEecl.; %end;
		  hlo=&otherhlo.;
		  label=&other.;
		  output;
		end;
	%end;

run;

/* creation du(des) format(s) */
proc format cntlin= _prepare_fmt  lib=&lib.;
run;

	/* suppression des tables intermediaires */
	proc datasets lib=work nolist;
	delete 
		_temp_sort

	%if &debug.=0 %then %do;
		_prepare_fmt
	%end;
	;
	quit;

%mend format_cntlin;
