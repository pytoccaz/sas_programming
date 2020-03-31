/*
	pgm: for.sas
	
	auteur: Jim Anderson, UCSF, james.anderson@ucsf.edu

    "

			Si vous utilisez cette macro, SVP conservez la mention de l'auteur. 

											Merci pour lui,

												obe (le traducteur)
								
																						"

	http://www.sascommunity.org/wiki/Streamlining_Data-Driven_SAS_With_The_%25FOR_Macro
	http://www.wuss.org/proceedings08/08WUSS%20Proceedings/papers/app/app04.pdf

  	Fonction : cette macro effectue une boucle de generation de code SAS.
	Elle admet 5 types d'objets differents sur lesquels boucler:
    table SAS, Liste de valeur, suite de nombres, Attributs de table SAS et contenu de repertoire.
    
	La valeurs des objets d'iteration sont assignees aux macros variables specifiees
	par le parametre <macro_var_list> au cours de chaque iteration.
    
    Exemple:
     
      %for(hospid hospname, in=[report_hosps], do=%nrstr(
          title "&hospid &hospname Patient Safety Indicators";
          proc print data=psi_iqi(where=(hospid="&hospid")); run;
      ))

	L'exemple ci-dessus boucle sur la table report_hosps, qui contient les
	variables "hospid" et "hospname". Pour chaque observation, 
	les valeurs des variables "hospid" et "hospname" 
	sont assignees aux macro-variables <hospid> et <hospname> 
	automatiquement crees par la macro FOR. La macro %For genere a chaque iteration 
	le code de boucle.

    
  Parametre:

    macro_var_list = liste des macros variables allouees a chaque iteration

    in = objet d'iteration. Le type d'objet se specifie par le choix de caractere 
							encapsulant le nom de l'objet:

                  (a b c) - liste de valeurs qui vont etre allouee sequentiellement a une macro variable.
                  [xyz] - Une table SAS dont les observations vont fournir sequentiellement de quoi allouer
							une ou plusieurs macro variable. Le lien bijectif entre variables et macro-variables
							se fait sur fait par homonimie. 
                  {xyz} - Une table SAS dont les attributs de variables vont etre macrotises sequentiellement.
       	          <c:\abc> - un chemin de repertoire dont les fichiers et leur descriptions sont la source de
								macro variables automatiques
                  1:100 - une suite de nombres qui fournissent sequentiellement les valeurs d'une macro variable.

    do = Le code SAS a generer a chaque iteration de la macro %for.
              Si ce code requiert la resolution de macros variables allouees par la macro %for,
			  ce qui est le cas la plupart du temps, protegez le code par %nrstr() de facon a 
			  differer la resolution jusqu'au moment de la generation du code.
  
    [ ] iterations sur les observations d'une table:
    La qualification de la table accepte la clause where. Le lien bijectif entre variables et macro-variables
	se fait sur fait par homonimie. 
    
    { } iterations sur les attributs de la table:
    Pour chaque variable de la table, les macro variables de la liste <macro_var_list> recoivent les valeurs 
	des attributs decrivant la variable et le code SAS "do=" est genere. Les noms de macro variables possibles
	sont a choisir parmi  "name", "type", "length", "format" and "label".
        name - prend successivement le nom de chaque variable de la table
        type - se voit allouer la valeur 1 si la variable est numerique et 2 si elle est caractere.
        format - se voit allouer le nom du format de la variable.
        length - se voit allouer la longueur de la variable.
        label - se voit allouer la label de la variable.
    
    < > iterations sur le contenu d'un repertoire:
    Pour chaque fichier du repertoire, les macro variables de la liste <macro_var_list> recoivent les
	valeurs des element decrivant le fichier et le code SAS "do=" est genere. Les noms de macro variables possibles
	sont a choisir parmi "filepath", "filename", "shortname", "extension", and "isdir".
        filepath - se voit allouer le chemin complet du fichier
        filename - se voit allouer le nom du fichier avec son extension
        shortname - se voit allouer le nom du fichier sans son extension
        extension - se voit allouer l'extension du fichier
        isdir - se voit allouer la valeur 1 si l'element est un repertoire, 0 sinon
    
    ( ) iterations sur les valeurs d'une liste:
    Les macro variables specifiee dans <macro_var_list> se voit assigner les valeurs successives
	de la liste d'items. Quand toutes les variables sont assignees,  le code SAS "do=" est genere.
	Le processus se repete jusqu'a ce que la liste de valeur soit epuisee.
	Si la liste est epuisee avant que toutes les variables de <macro_var_list> puissent etre assignees,
	alors l'iteration stoppe et ne genere pas le code SAS "do=" sur les variables partiellement allouees.
    (Le nombre de valeurs dans la liste devrait toujours etre un multiple du nombre de macro variables a 
	assigner specifiees par <macro_var_list>).
    
    <deb>:<fin> iteration sur une suite de nombres
    Un intervalle de 2 nombres utilise un caractere ":" et par defaut a un pas d'incrementation de 1.
	Dans un intervalle de 3 nombre  (e.g., in=1:11:2), le nombre final est le pas d'increntation.
	La variable <macro_var_list> se voit assigner les valeurs comme dans le cas classique %do-%to-%by.
    

	Modifications : 

	1- jan2015/obe : sortie propre de la macro dans les cas d'erreur [] et {} et affichage du code de 
					delockage en cas d'arret brutal de la macro.

*/
%macro for(macro_var_list,in=,do=);
  %local _for_itid _for_ct _for_do _for_i _for_val1 _for_var1 _n_
         _for_dir _for_var_num _for_in_first _for_in_last _for_in_length
         _for_in_sep _for_in_values _for_in_more _for_extra;
  %let _for_do=&do;
  %if %eval(%index(&do,%nrstr(%if))+%index(&do,%nrstr(%do))) %then
  %do; %* conditional macro code - need to embed in macro;
    %global _for_gen;
    %if &_for_gen=%str( ) %then %let _for_gen=0;
    %else %let _for_gen=%eval(&_for_gen+1);
    %unquote(%nrstr(%macro) _for_loop_&_for_gen(); &do %nrstr(%mend;))
    %let _for_do=%nrstr(%_for_loop_)&_for_gen();
  %end;
  %let _for_ct=0;
  %let _for_in_first=%qsubstr(&in,1,1);
  %let _for_in_length=%length(&in);
  %let _for_in_last=%qsubstr(&in,&_for_in_length,1);
  %if &_for_in_first=%qsubstr((),1,1) %then
  %do; %* loop over value list;
   %if &_for_in_last ne %qsubstr((),2,1) %then
   %do;
   %put ERROR: "for" macro "in=(" missing terminating ")";
   %return;
   %end;
    %if &macro_var_list=%str( ) %then
    %do; %*empty variable list - perhaps (s)he just wants &_n_;
      %let macro_var_list=_for_extra;
    %end;
   %if %qsubstr(&in,2,1) ne &_for_in_first %then
   %do; %* implicit space separator -- empty entries disallowed;
   %if &_for_in_length<3 %then %return;
   %let _for_in_values=%substr(&in,2,%eval(&_for_in_length-2));
      %local _for_value_index;
      %let _for_value_index=1;
      %do %while(1);
        %let _for_ct=%eval(&_for_ct+1);
        %let _n_=&_for_ct;
       %let _for_i=1;
       %let _for_var1=%scan(&macro_var_list,1,%str( ));
       %do %while(%str(&_for_var1) ne %str( ));
       %let _for_val1=%scan(&_for_in_values,&_for_value_index,%str( ));
       %let _for_value_index=%eval(&_for_value_index+1);
       %if %length(&_for_val1)=0 %then
       %do; %* end of values before end of variables, terminate iteration;
            %return;
          %end;
       %let &_for_var1=&_for_val1;
       %let _for_i=%eval(&_for_i+1);
       %let _for_var1=%scan(&macro_var_list,&_for_i,%str( ));
       %end;
  %unquote(&_for_do)
      %end;
      %return;
   %end;
   %else
   %do; %* explicit separator -- empty entries allowed;
   %if &_for_in_length<6 %then %return; %* empty list;
   %let _for_in_sep=%qsubstr(&in,3,1);
   %if %qsubstr(&in,4,1) ne &_for_in_last %then
   %do;
   %put ERROR: "for" macro "in=" explicit separator missing right parenthesis;
   %return;
   %end;
   %let _for_in_values=%qleft(%qtrim(%qsubstr(&in,5,%eval(&_for_in_length-5))));
%let _for_in_more=1;
%do %while(1);
%let _for_ct=%eval(&_for_ct+1);
%let _n_=&_for_ct;
%let _for_i=1;
%let _for_var1=%scan(&macro_var_list,1,%str( ));
%do %while(%str(&_for_var1) ne %str( ));
%if &_for_in_more=0 %then %return; %* end of value list;
          %if &_for_in_sep=%qsubstr(&_for_in_values,1,1) %then %let &_for_var1=;
%else %let &_for_var1=%scan(&_for_in_values,1,&_for_in_sep);
%let _for_i=%eval(&_for_i+1);
%let _for_var1=%scan(&macro_var_list,&_for_i,%str( ));
%let _for_in_more=%index(&_for_in_values,&_for_in_sep);
          %if %length(&_for_in_values)=&_for_in_more %then %let _for_in_values=%str( );
%else %let _for_in_values=%qsubstr(&_for_in_values,%eval(&_for_in_more+1));
%end;
%unquote(&_for_do)
%end;
%return;
   %end;
  %end;
  %else %if &_for_in_first=%str([) %then
  %do; %* loop over dataset;
    %local _for_in_dataset;
   %if &_for_in_last ne %str(]) %then
   %do;
   %put ERROR: "for" macro "in=[" missing terminating "]";
   %return;
   %end;
   %if &_for_in_length<3 %then %return;
   %let _for_in_dataset=%substr(&in,2,%eval(&_for_in_length-2));
%let _for_itid=%sysfunc(open(&_for_in_dataset));
%put (FOR) OPENING &_for_in_dataset with id=&_for_itid.; /* obe */
%put (FOR) >>> TO CLOSE THE TABLE PROPERLY AFTER MACRO CANCELING PLEASE SUBMIT: %nrstr(%%)let rc=%nrstr(%%)sysfunc(close(&_for_itid.))%nrstr(;); /* obe */
%if &_for_itid=0 %then
%do;
%put ERROR: for macro cant open dataset &_for_in_dataset;
%return;
%end;
    %do %while(%sysfunc(fetch(&_for_itid,NOSET))>=0);
      %let _for_ct=%eval(&_for_ct+1);
      %let _n_=&_for_ct;
     %let _for_i=1;
     %let _for_var1=%scan(&macro_var_list,1,%str( ));
     %do %while(%str(&_for_var1) ne %str( ));
     %let _for_var_num=%sysfunc(varnum(&_for_itid,&_for_var1));
     %if &_for_var_num=0 %then
     %do;
     %put ERROR: "&_for_var1" is not a dataset variable;
		%let _for_i=%sysfunc(close(&_for_itid)); /* obe: sortie propre */
     %return;
     %end;
     %if %sysfunc(vartype(&_for_itid,&_for_var_num))=C %then
     %do; %* character variable;
     %let _for_val1=%qsysfunc(getvarc(&_for_itid,&_for_var_num));
       %if %sysfunc(prxmatch("[^\w\s.]+",&_for_val1)) %then
       %let &_for_var1=%qtrim(&_for_val1);
       %else
       %let &_for_var1=%trim(&_for_val1);
     %end;
     %else
     %do; %* numeric variable;
     %let &_for_var1=%sysfunc(getvarn(&_for_itid,&_for_var_num));
     %end;
     %let _for_i=%eval(&_for_i+1);
     %let _for_var1=%scan(&macro_var_list,&_for_i,%str( ));
     %end;
%unquote(&_for_do)
    %end;
%let _for_i=%sysfunc(close(&_for_itid));
    %return;
  %end;
  %else %if &_for_in_first=%str({) %then
  %do; %* loop over proc contents;
    %local _for_in_dataset;
   %if &_for_in_last ne %str(}) %then
   %do;
   %put ERROR: "for" macro "in={" missing terminating "}";
   %return;
   %end;
   %if &_for_in_length<3 %then %return;
   %let _for_in_dataset=%substr(&in,2,%eval(&_for_in_length-2));
%let _for_itid=%sysfunc(open(&_for_in_dataset));
%put (FOR) OPENING &_for_in_dataset with id=&_for_itid. ; /* obe */
%put (FOR) >>> TO CLOSE THE TABLE PROPERLY AFTER MACRO CANCELING PLEASE SUBMIT: %nrstr(%%)let rc=%nrstr(%%)sysfunc(close(&_for_itid.))%nrstr(;); /* obe */
%if &_for_itid=0 %then
%do;
%put ERROR: for macro cant open dataset &_for_in_dataset;
%return;
%end;
%let _for_ct = %sysfunc(attrn(&_for_itid,NVARS));
    %do _for_i=1 %to &_for_ct;
      %let _n_=&_for_i;
     %let _for_var_num=1;
     %let _for_var1=%upcase(%scan(&macro_var_list,1,%str( )));
     %do %while(%str(&_for_var1) ne %str( ));
     %if &_for_var1=NAME %then
     %do;
     %let name=%sysfunc(varname(&_for_itid,&_for_i));
     %end;
     %else %if &_for_var1=FORMAT %then
     %do;
     %let format=%sysfunc(varfmt(&_for_itid,&_for_i));
     %end;
     %else %if &_for_var1=TYPE %then
     %do;
     %if %sysfunc(vartype(&_for_itid,&_for_i))=C %then
     %let type=2;
     %else
     %let type=1;
     %end;
     %else %if &_for_var1=LENGTH %then
     %do;
     %let length=%sysfunc(varlen(&_for_itid,&_for_i));
     %end;
     %else %if &_for_var1=LABEL %then
     %do;
     %let _for_val1=%qsysfunc(varlabel(&_for_itid,&_for_i));
       %if %sysfunc(prxmatch("[^\w\s.]+",&_for_val1)) %then
       %let label=%qtrim(&_for_val1);
       %else
       %let label=%trim(&_for_val1);
     %end;
     %else
     %do;
     %put ERROR: "&_for_var1" is not NAME, TYPE, FORMAT, LENGTH or LABEL;
		%let _for_i=%sysfunc(close(&_for_itid)); /* obe: sortie propre */
     %return;
     %end;
     %let _for_var_num=%eval(&_for_var_num+1);
     %let _for_var1=%upcase(%scan(&macro_var_list,&_for_var_num,%str( )));
     %end;
%unquote(&_for_do)
    %end;
%let _for_i=%sysfunc(close(&_for_itid));
    %return;
  %end;
  %else %if &_for_in_first=%str(<) %then
  %do; %* loop over directory contents;
   %if &_for_in_last ne %str(>) %then
   %do;
   %put ERROR: "for" macro "in=<" missing terminating ">";
   %return;
   %end;
    %let _for_val1=;
   %if &_for_in_length<3 %then %return;
    %let _for_dir=%substr(&in,2,%eval(&_for_in_length-2));
%let _for_itid=%sysfunc(filename(_for_val1,&_for_dir));
%let _for_itid=%sysfunc(dopen(&_for_val1));
%if &_for_itid=0 %then
%do;
%put ERROR: cant open directory path=&_for_dir;
%return;
%end;
%let _for_ct = %sysfunc(dnum(&_for_itid));
    %do _for_i=1 %to &_for_ct;
      %let _n_=&_for_i;
     %let _for_var_num=1;
     %let _for_var1=%upcase(%scan(&macro_var_list,1,%str( )));
     %do %while(%str(&_for_var1) ne %str( ));
     %let _for_extra=%sysfunc(dread(&_for_itid,&_for_i));
     %if &_for_var1=FILENAME %then
     %do;
     %let filename=&_for_extra;
     %end;
     %else %if &_for_var1=EXTENSION %then
     %do;
     %if %index(&_for_extra,%str(.)) ne 0 %then
     %do;
     %let extension=.%scan(&_for_extra,-1,%str(.));
     %end;
     %else
     %do;
     %let extension=;
     %end;
     %end;
     %else %if &_for_var1=FILEPATH %then
     %do;
     %let filepath=&_for_dir\&_for_extra; %*windows specific;
     %end;
     %else %if &_for_var1=SHORTNAME %then
     %do;
     %if %index(&_for_extra,%str(.)) ne 0 %then
     %do;
     %let _for_val1=%eval(%length(&_for_extra)-
     %length(%scan(&_for_extra,-1,%str(.)))-1);
     %let shortname=%substr(&_for_extra,1,&_for_val1);
     %end;
     %else
     %do;
     %let shortname=&_for_extra;
     %end;
     %end;
     %else %if &_for_var1=ISDIR %then
     %do; %*below windows specific;
     %let _for_var1=_forfile;
     %let _for_val1=%sysfunc(filename(_for_var1,&_for_dir\&_for_extra));
     %let _for_val1=%sysfunc(dopen(&_for_var1));
     %let isdir=%eval(&_for_val1 ne 0);
     %if &isdir %then
     %do;
     %let _for_val1=%sysfunc(dclose(&_for_val1));
     %end;
     %end;
     %else
     %do;
     %put ERROR: "&_for_var1" is not FILENAME, EXTENSION, FILEPATH, SHORTNAME or ISDIR;
     %return;
     %end;
     %let _for_var_num=%eval(&_for_var_num+1);
     %let _for_var1=%upcase(%scan(&macro_var_list,&_for_var_num,%str( )));
     %end;
%unquote(&_for_do)
    %end;
%let _for_i=%sysfunc(dclose(&_for_itid));
%let _for_i=%sysfunc(filename(_for_val1,));
    %return;
  %end;
  %else %if %index(&in,%str(:)) %then
  %do; %* loop from:to:by;
    %local _for_in_from _for_in_to _for_in_by;
    %let _for_in_from=%scan(&in,1,%str(:));
    %let _for_in_to=%scan(&in,2,%str(:));
    %if &_for_in_to=%str( ) %then
    %do;
      %put ERROR: for macro missing value after : in range;
      %return;
    %end;
    %let _for_in_by=%scan(&in,3,%str(:));
    %if &_for_in_by=%str( ) %then %let _for_in_by=1;
    %let _for_var1=%scan(&macro_var_list,1,%str( ));
    %let _for_ct=1;
    %do _for_i=&_for_in_from %to &_for_in_to %by &_for_in_by;
      %let _n_=&_for_ct;
     %if %str(&_for_var1) ne %str( ) %then %let &_for_var1=&_for_i;
     %let _for_ct=%eval(&_for_ct+1);
%unquote(&_for_do)
    %end;
    %return;
  %end;
  


  %put ERROR: for macro unrecognized in= argument value "&in";
%mend for;



 