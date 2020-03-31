
/*%num_tokens
 Auteur: Gabriel Cano
 Desc: Compte le nombre d'items d'une liste 
 Arguments obligatoires :
   words – la liste
 Arguments optionnels :
   delim – le delimiteur [par defaut: espace]

 Example:
     %put %num_tokens(a b c d e);
     %put %num_tokens(a-b-c-d-e, delim=-);

 Credit:
    source code from Robert J. Morris, Text Utility Macros for Manipulating Lists of Variable Names
        (SUGI 30, 2005) www2.sas.com/proceedings/sugi30/029-30.pdf
    authored by Gabriel Cano;
*/

%macro num_tokens(words, delim=%str( ));
    %local counter;
    %* Loop through the words list, incrementing a counter for each word found. ;
    %let counter = 1;
    %do %while (%length(%scan(&words, &counter, &delim)) > 0);
        %let counter = %eval(&counter + 1);
    %end;
    %* Our loop above pushes the counter past the number of words by 1. ;
    %let counter = %eval(&counter - 1);
    %* Output the count of the number of words. ;
    &counter
%mend ; 
