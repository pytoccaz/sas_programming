# AR macros 

Those macros make "retain statement "-like coding easy.

## Install

Include [utils macros](../utils) sources in your SAS project.

## Get Started

The AR-macros are SAS9 datasteps macros, ie should be inserted between *data* statement and *run* statement to run properly. They can't be used elsewhere. They won't work in SQL procedures or any other SAS proc or full macro code.  

### ar_declare

declare a set of temporay arrays to retain SAS datastep variable value from the PDV.

```sas
data step;
%ar_declare(LABEL, table_ref=sashelp.class);
set _null_;
run;
/* is equivalent to */
data step;
ARRAY LABEL_Name(1) $8 _TEMPORARY_;
ARRAY LABEL_Sex(1) $1 _TEMPORARY_;
ARRAY LABEL_Age(1) 8 _TEMPORARY_;
ARRAY LABEL_Height(1) 8 _TEMPORARY_;
ARRAY LABEL_Weight(1) 8 _TEMPORARY_;
set _null_;
run;
```


### ar_charge & ar_decharge
load pdv variable values into arrays & download array values to pdv variables 

The code below pushes 13th and 14th obs at the bottom of the newtable:


```sas
data newtable;
%ar_declare(AR13, table_ref=sashelp.class);
%ar_declare(AR14, table_ref=sashelp.class);
set sashelp.class end=fin;

if _n_=13 then do;
  %ar_charge(AR13, table_ref=sashelp.class); 
end;
else if _n_=14 then do;
  %ar_charge(AR14, table_ref=sashelp.class); 
end;
else output;

if fin then do;
  %ar_decharge(AR13, table_ref=sashelp.class); output;
  %ar_decharge(AR14, table_ref=sashelp.class); output;
end;

run;
```

