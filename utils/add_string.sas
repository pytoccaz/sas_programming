/*%add_string 
    Desc: Ajout d'un prefix ou d'un suffixe aux items d'une liste
    dependance: %num_tokens

    Arguments obligatoires:
        words = la liste
        str = le texte de (pre|suf)fixation 

    Arguments optionnels: 
        location = [prefix|suffix, default: suffix] 
        delim = caractere de separation [default: space] 

    Exemples: 
        %put  %add_string(a b c, _max); *produit le texte a_max b_max c_max;            
        %put %add_string(a b c, max_, location=prefix);     *produit le texte max_a max_b max_c;            
        %put %add_string(%str(a,b,c), _max, delim=%str(,)); *produit le texte a_max,b_max,c_max;

    Credit:
        source code from Robert J. Morris, Text Utility Macros for Manipulating Lists of Variable Names
          (SUGI 30, 2005) www2.sas.com/proceedings/sugi30/029-30.pdf           

*/


%macro add_string(words, str, delim=%str( ), location=suffix); 
    %local outstr i word num_words; 

    %* Verify macro arguments. ; 
    %if (%length(&words) eq 0) %then %do; 
        %put ***ERROR(add_string): Required argument 'words' is missing.; 
        %goto exit; 
    %end; 
    %if (%length(&str) eq 0) %then %do; 
        %put ***ERROR(add_string): Required argument 'str' is missing.; 
        %goto exit; 
    %end; 
    %if (%upcase(&location) ne SUFFIX and %upcase(&location) ne PREFIX) %then %do; 
        %put ***ERROR(add_string): Optional argument 'location' must be; 
        %put *** set to SUFFIX or PREFIX.; 
        %goto exit; 
    %end; 

    %* Build the outstr by looping through the words list and adding the 
    * requested string onto each word. ; 
    %let outstr = ; 
    %let num_words = %num_tokens(&words, delim=&delim); 
    %do i=1 %to &num_words; 
        %let word = %scan(&words, &i, &delim); 
        %if (&i eq 1) %then %do; 
            %if (%upcase(&location) eq PREFIX) %then %do; 
                %let outstr = &str&word; 
            %end; 
            %else %do; 
                %let outstr = &word&str; 
            %end; 
        %end; 
        %else %do; 
            %if (%upcase(&location) eq PREFIX) %then %do; 
                %let outstr = &outstr&delim&str&word; 
            %end; 
            %else %do; 
                %let outstr = &outstr&delim&word&str; 
            %end; 
        %end; 
    %end; 
    %* Output the new list of words. ; 
    &outstr 
    %exit: 
%mend add_string; 
