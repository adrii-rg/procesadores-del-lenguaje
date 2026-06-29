/*
* Autor: Adrian Redondo Garcia
* 
* En esta práctica mediante el uso de flex y bison, este programa traduce
* código de un lenguaje de alto nivel a código de la maquina de pila abstracta.
* Es similar a la práctica anterior solo que en vez de utilizar un analizador
* descendente como es JavaCC, usamos uno ascendente que es en este caso bison.
* 
* Analizador sintactico implementado en Bison.
* Define la gramatica del lenguaje y las acciones encargadas de generar el codigo
* de la maquina de pila abstracta a partir del lenguaje de alto nivel.
*/

%{
      #include <stdio.h>
      #include <stdlib.h>

      extern int yyparse();
      extern FILE *yyin;

      int yylex(void);
      int yyerror(char *);

      int yydebug = 1;

      /*
      * Funcion que se encarga de devolver el siguiente nº de etiqueta
      */
      int sigNumero() {
            static int etiqueta = -1;
            return ++etiqueta;
      }
%}

%union {
      int num;
      int etiqueta;
      char* id;
}

// Tokenes recibidos de flex
%token SI SINO MIENTRAS HACER IMPRIMIR
%token SIGUAL RIGUAL MIGUAL DIGUAL
%token <num> NUM
%token <id> ID

%left '+' '-' SIGUAL RIGUAL
%left '*' '/' MIGUAL DIGUAL
%%
/*
* Produccion que se encarga de una lista de sentencias.
* Se usa como axioma
*/
list_sntncs : sntnc ';' list_sntncs
            | sntnc ';'
            ;

/*
* Produccion que se encarga de tratar cada tipo de sentencia, ya sea bucle, asignacion, etc
*/
sntnc : sel_stmt
      | iter_stmt
      | assig_stmt
      | print_stmt
      ;

/*
* Produccion que se encarga de la sentencia de imprimir
*/
print_stmt : IMPRIMIR '(' expr ')'  { printf("    print\n"); } ;

/*
* Produccion principal que se encarga de las sentencias condicionales
*/
sel_stmt : SI '(' expr ')' 
           { $<etiqueta>$=sigNumero();
             printf("    sifalsovea LBL%d\n", $<etiqueta>$); }
           '{' list_sntncs '}' { $<etiqueta>$ = $<etiqueta>5; }
           sel_else 
         ;

/*
* Produccion auxiliar a sel_stmt, gestionando el "sino" opcional
*/
sel_else : { printf("LBL%d:\n", $<etiqueta>0); } /* Caso donde no hay sino */
         | SINO { $<etiqueta>$ = sigNumero();
                  printf("    vea LBL%d\n", $<etiqueta>$);
                  printf("LBL%d:\n", $<etiqueta>0); }
           '{' list_sntncs '}' { printf("LBL%d:\n", $<etiqueta>2); }
         ;

/*
* Produccion que se encarga de los bucles
*/
iter_stmt : MIENTRAS { $<etiqueta>$=sigNumero();
                       printf("LBL%d:\n", $<etiqueta>$); }
            '(' expr ')' { $<etiqueta>$ = sigNumero();
                           printf("    sifalsovea LBL%d\n", $<etiqueta>$); }
            '{' list_sntncs '}' { printf("    vea LBL%d\n", $<etiqueta>2);
                                  printf("LBL%d:\n", $<etiqueta>6); }
          | HACER { $<etiqueta>$=sigNumero();
                    printf("LBL%d:\n", $<etiqueta>$); }
            '{' list_sntncs '}' MIENTRAS '(' expr ')'
            { printf("    siciertovea LBL%d\n", $<etiqueta>2); }
          ;

/*
* Produccion que se encarga de las asignaciones de variables
*/
assig_stmt : ID {printf("    valori %s\n",$1); free($1);} '=' expr { printf("    asigna\n"); }
           | ID {printf("    valori %s\n    valord %s\n", $1, $1);}
             SIGUAL expr { printf("    sum\n    asigna\n"); free($1); }
           | ID {printf("    valori %s\n    valord %s\n", $1, $1);}
             RIGUAL expr { printf("    sub\n    asigna\n"); free($1); }
           | ID {printf("    valori %s\n    valord %s\n", $1, $1);}
             MIGUAL expr { printf("    mul\n    asigna\n"); free($1); }
           | ID {printf("    valori %s\n    valord %s\n", $1, $1);}
             DIGUAL expr { printf("    div\n    asigna\n"); free($1); }
           ;

/*
* Produccion que se encarga de las sumas y restas
*/
expr : expr '+' mult_expr  { printf("    sum\n"); }
     | expr '-' mult_expr  { printf("    sub\n"); }
     | mult_expr
     ;

/*
* Produccion que se encarga de las multiplicaciones y divisiones
*/
mult_expr : mult_expr '*' val { printf("    mul\n"); }
          | mult_expr '/' val { printf("    div\n"); }
          | val
          ;

/*
* Produccion que se encarga de los numeros, identificadores y expresiones que se
* encuentren entre paréntesis
*/
val : NUM         { printf("    mete %d\n", $1); }
    | ID          { printf("    valord %s\n", $1); free($1); }
    | '(' expr ')'
    ;

%%
int yyerror(char *s){
    printf("%s\n", s);

    return 1;
}

int main(int argc, char *argv[]) {
      if (argc > 1) {
            FILE *file;
            file = fopen(argv[1], "r");
            if (!file) {
                  printf("No se puede abrir el fichero %s\n", argv[1]);
                  exit(1);
            }
        yyin = file;
      } else {
        yyin = stdin;
        printf("Introduce una expresion (Ctrl+D para terminar):\n");
      }

      yyparse();

      return 0;
}
