/*
    Autor: Adrian Redondo Garcia

    En esta practica, el programa analiza un procedimiento PL-SQL, buscando la
    siguiente información:
     - El numero de argumentos del procedimiento
     - El numero de variables locales en el procedimiento
     - En las sentencias UPDATE/DELETE cual es la mas larga
     - En las sentencias SELECT el numero de tablas a las que accede y sus nombres

    Hay un total de 7 estados:
     - INITIAL: Estado de arranque definido por Flex
     - ARGS: Estado encargado de contar los argumentos.
     - VARS: Estado encargado de contar las variables locales.
     - BODY: Estado encargado del cuerpo del procedimiento, su funcionalidad esta
             dividida en dos estados:
        * B_SEL: Estado encargado de las consultas SELECT, contando el numero
                 de tablas a las que accede asi como sus nombres.
        * B_UPD_DEL: estadoo encargado de las consultas UPDATE y DELETE,
                     comprobando cual de ellas es la mas larga.
     - COM: Estado encargado de los comentarios, para filtrar si hay alguna
            consulta en un comentario el programa no la detecte.
*/

%option caseless stack

variable            [A-Za-z0-9_]+

%x  ARGS        
%x  VARS        
%x  BODY        
%x  B_SEL       
%x  B_UPD_DEL   
%x  COM         

%{
    int contArgumentos = 0;   
    int contVarLocales = 0;             
    int contSelMasTablas = 0;           // Contador que guarda el SELECT con mas tablas
    int contSelTablasActual = 1;        // Contador encargado del SELECT que se este leyendo
    char *insDelActual = NULL;          // Array para el INSERT/DELETE que se este leyendo
    char *insDelMasLargo = NULL;        // Array para guardar el INSERT/DELETE mas largo
    char *tablasSelectActual = NULL;    // Array para guardar los nombres de las tablas del SELECT que se este leyendo
    char *tablasSelectMasTablas = NULL; // Array para guardar los nombres de las tablas del SELECT con mas tablas
%}
%%
<INITIAL>"PROCEDURE "{variable}" "?\n?\(    { BEGIN(ARGS); }        /* Reconociendo el principio del procedimiento, entramos
                                                                       en la sección de argumentos */
<ARGS>{variable},                           { contArgumentos++; }
<ARGS>\)                                    { contArgumentos++; }
<ARGS>"IS"/(" "|\t|\n)                      { BEGIN(VARS); }        /* Mediante IS sabemos que nos encontramos en la seccion 
                                                                       de las variables locales */
<VARS>{variable}" "{variable};              { contVarLocales++; }
<VARS>"BEGIN"                               { BEGIN(BODY); }        /* Reconociendo BEGIN entramos en la seccion del cuerpo
                                                                       del procedmiento */
<BODY>("UPDATE"|"DELETE")                   { BEGIN(B_UPD_DEL); yymore(); }
<B_UPD_DEL>[^;]*                            { 
                                              /* 
                                               Cogemos todos los caracteres hasta el ; que es cuando termina el UPDATE/DELETE
                                               y comparamos su tamaño con el anterior y sustituimos si es mas largo
                                              */
                                              free(insDelActual);
                                              insDelActual = strdup(yytext);

                                              if (insDelMasLargo == NULL || strlen(insDelActual) > strlen(insDelMasLargo)) {
                                                  free(insDelMasLargo);
                                                  insDelMasLargo = strdup(insDelActual);
                                              }

                                              BEGIN(BODY); }
<BODY>"FROM"                                { BEGIN(B_SEL); contSelTablasActual = 1;}  /* El FROM indica el comienzo del SELECT */
<B_SEL>("WHERE"|;)                          { 
                                              /*
                                               Al llegar al WHERE o ; comparamos el numero de tablas que tenemos
                                               y si es mayor lo sustituimos
                                              */
                                              if (contSelTablasActual > contSelMasTablas) {
                                                  free(tablasSelectMasTablas);
                                                  tablasSelectMasTablas = strdup(tablasSelectActual);
                                                  contSelMasTablas = contSelTablasActual;
                                              }
                                                
                                              BEGIN(BODY);
                                            }
                                            /* Cogemos el nombre de las tablas y contamos las "," para saber el numero */
<B_SEL>{variable}(," "?{variable})*        { tablasSelectActual = strdup(yytext); 
                                                for (int i = 0; i < strlen(tablasSelectActual); i++) {
                                                    if (tablasSelectActual[i] == ',') {
                                                        contSelTablasActual++;
                                                    }
                                                }
                                            }
                                            /* 
                                             Al llegar al END, el cuerpo de procedimiento ha terminado por lo que se
                                             puede volver al estado inicial
                                            */
<BODY>"END "{variable};                     { BEGIN(INITIAL); }
<*>"--".*                                   { ; }                   
<*>"/*"                                     { yy_push_state(COM); } /*  
                                                                      Como puede haber comentarios en cualquier parte del
                                                                      procedimiento, usamos la pila para cambiar al estado
                                                                      COM y una vez finalizado, volver al estado en que
                                                                      nos encontrabamos
                                                                    */
<COM>"*/"                                   { yy_pop_state(); }
<COM>\n                                     { ; }
<COM>.                                      { ; }
<*>.|\n                                     { ; }
%%
int main(int argc, char **argv){
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
    }

    yylex();

    printf(" - El procedimiento tiene %d argumentos\n", contArgumentos);
    printf(" - El numero de variables locales es: %d\n", contVarLocales);
    printf(" - La sentencia de de actualizacion/borrado mas larga es:\n \"%s\"\n", insDelMasLargo);
    printf(" - La consulta con mayor número de tablas tiene %d y son: %s\n", contSelMasTablas, tablasSelectMasTablas);

    // Liberamos la memoria de los arrays
    free(insDelActual);
    free(insDelMasLargo);
    free(tablasSelectActual);
    free(tablasSelectMasTablas);

    return 0;
}