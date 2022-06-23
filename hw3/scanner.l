%{
#include <stdio.h>
#include <math.h>
#include <string.h>
#include "y.tab.h"
%}

DIGIT   [0-9]
ID      [a-zA-Z_][a-zA-Z0-9_]*
HEX     [a-fA-F0-9]
SCHAR    "\\a"|"\\b"|"\\e"|"\\f"|"\\n"|"\\r"|"\\t"|"\\v"|(\\\\)|"\\'"|"\\\""|"\\?"|(\\[0-9]{1,3})|(\\x({HEX}+))|(\\u{HEX}{4,4})|(\\U{HEX}{8,8})

%x CMNT

%%

"//".*      {}
"/*"        { BEGIN CMNT; }
<CMNT>.     {}
<CMNT>\n    {}
<CMNT>"*/"  { BEGIN INITIAL; }

":"|";"|","|"\."|"["|"]"|"("|")"|"{"|"}"            { return yytext[0]; }

"+"|"-"|"*"|"/"|"%"|"<"|">"|"="|"!"|"^"|"&"|"\|"|"~"    { return yytext[0]; }

"<="    { return (LE_OP); }
">="    { return (GE_OP); }
"=="    { return (EQ_OP); }
"!="    { return (NE_OP); }

const                       { return (CONST); }
int                         { return (INT_TYPE); }
char4                       { return (CHAR4_TYPE); }
float|double|void           {
                                yylval.sval = strdup(yytext);
                                return (CONST_TYPE); 
                            }

HIGH    {
            yylval.ival = 1;
            return (INTEGER);
        }
LOW     {
            yylval.ival = 0;
            return (INTEGER);
        }

for     { return (FOR); }
do      { return (DO); }
while   { return (WHILE); }
if      { return (IF); }
else    { return (ELSE); }

break       { return (BREAK); }
return      { return (RETURN); }

{DIGIT}+            {
                        yylval.ival = atoi(yytext);
                        return (INTEGER);
                    }

{ID}        {
                yylval.sval = strdup(yytext);
                return (IDENT);
            }

\n          {}
[ \t]+      {}

%%

int yywrap () {
    return 1;
}
