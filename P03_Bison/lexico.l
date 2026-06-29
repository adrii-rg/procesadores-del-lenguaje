/*
* Autor: Adrian Redondo Garcia
* 
* En esta práctica mediante el uso de Flex y Bison, este programa traduce
* código de un lenguaje de alto nivel a código de la máquina de pila abstracta.
* Es similar a la práctica anterior solo que en vez de utilizar un analizador
* descendente como es JavaCC, usamos uno ascendente que es en este caso Bison.

* Analizador lexico implementado en Flex. 
* Lee las entradas y genera los tokens que consumira Bison.
*/
%{
    #include "y.tab.h"
%}

%x COM
%%
"//"[^\n]*                  { ; }  /* Comentarios de una linea */
                            /* Comentarios multilinea */
"/*"                        { BEGIN(COM); }
<COM>"*/"                   { BEGIN(INITIAL); }
<COM>\n                     { ; }
<COM>.                      { ; }

"si"                        { return SI; }
"sino"                      { return SINO; }
"mientras"                  { return MIENTRAS; }
"hacer"                     { return HACER; }
"imprimir"                  { return IMPRIMIR; }
"+="                        { return SIGUAL; }
"-="                        { return RIGUAL; }
"*="                        { return MIGUAL; }
"/="                        { return DIGUAL; }
[0-9]+                      { yylval.num = atoi(yytext);
                              return NUM; }
[a-zA-Z_]+([a-zA-Z0-9_])*   { yylval.id = strdup(yytext);
                              return ID; }
[ \n\t\r]                   { ; }
.                           { return yytext[0]; } /* Sino coincide con ningun otro token
                                                     enviamos uno por uno a Bison */
