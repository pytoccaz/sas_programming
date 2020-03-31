/*%parallel_join 
    Desc: Jointure deux a deux des items de deux listes 
             
    dependance: %num_tokens

    Arguments obligatoires:
        words1 - la permiere liste
        words2 - la seconde liste
        joinstr - le separateur d'items en output
    Arguments optionnels: 
        delim1 - separateur de la liste words1 [defaut: espace] 
        delim2 - separateur de la liste words1 [defaut: espace] 

    Exemples: 
    %put  %parallel_join(a b c, d e f, *);                    *produit le texte a*d b*e c*f ;           
    %put  %parallel_join(a#b#c, d.e.f, *, delim1=#, delim2=.);*produit le texte a*d b*e c*f;

    Credit:
      source code from Robert J. Morris, Text Utility Macros for Manipulating Lists of Variable Names
        (SUGI 30, 2005) www2.sas.com/proceedings/sugi30/029-30.pdf            
*/


%macro parallel_join(words1, words2, joinstr, delim1=%str( ), delim2=%str( )); 
    %local i num_words1 num_words2 word outstr; 
    %* Verify macro arguments. ; 

    %if (%length(&words1) eq 0) %then %do; 
        %put ***ERROR(parallel_join): Required argument 'words1' is missing.; 
        %goto exit; 
    %end; 
    %if (%length(&words2) eq 0) %then %do; 
        %put ***ERROR(parallel_join): Required argument 'words2' is missing.; 
        %goto exit; 
    %end; 
        %if (%length(&joinstr) eq 0) %then %do; 
        %put ***ERROR(parallel_join): Required argument 'joinstr' is missing.; 
        %goto exit; 
    %end; 

    %* Find the number of words in each list. ; 
    %let num_words1 = %num_tokens(&words1, delim=&delim1); 
    %let num_words2 = %num_tokens(&words2, delim=&delim2); 
    %* Check the number of words. ; 
    %if (&num_words1 ne &num_words2) %then %do; 
        %put ***ERROR(parallel_join): The number of words in 'words1' and; 
        %put *** 'words2' must be equal.; 
        %goto exit; 
    %end; 
    %* Build the outstr by looping through the corresponding words and joining 
    * them by the joinstr. ; 
    %let outstr=; 
    %do i = 1 %to &num_words1; 
        %let word = %scan(&words1, &i, &delim1); 
        %let outstr = &outstr &word&joinstr%scan(&words2, &i, &delim2); 
    %end; 
    %* Output the list of joined words. ; 
    &outstr 
    %exit: 
%mend parallel_join; 
 