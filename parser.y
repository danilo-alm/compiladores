%{
#include <stdio.h>
#include <stdlib.h>

extern char *yytext;
int yylex();
void yyerror(const char *s);
%}

%token INT RETURN IF ELSE IDENT NUMBER
%token LPAREN RPAREN LBRACE RBRACE SEMICOLON
%token PLUS MINUS TIMES DIVIDE ASSIGN
%token LT LE GT GE EQ NEQ

%%

program:
      function { printf("Código sintaticamente correto!\n"); }
    ;

function:
    INT IDENT LPAREN INT IDENT RPAREN LBRACE statements RBRACE
;

statements:
      statement
    | statements statement
    ;

statement:
    RETURN expression SEMICOLON { printf("Comando return.\n"); }
  | IF LPAREN expression RPAREN statement { printf("Comando if.\n"); }
  | LBRACE statements RBRACE { printf("Bloco de código.\n"); }
;


expression:
    expression PLUS expression
  | expression MINUS expression
  | expression TIMES expression
  | expression DIVIDE expression
  | expression LT expression
  | expression LE expression
  | expression GT expression
  | expression GE expression
  | expression EQ expression
  | expression NEQ expression
  | IDENT LPAREN expression RPAREN { printf("Chamada de função: %s\n", yytext); }
  | IDENT
  | NUMBER
;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Erro: %s\n", s);
}

int main() {
    printf("Analisador iniciado...\n");
    return yyparse();
}


