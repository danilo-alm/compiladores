%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
%}

%option noyywrap

%%

"int"           return INT;
"return"        return RETURN;
"if"            return IF;
"else"          return ELSE;

[0-9]+          { yylval = atoi(yytext); return NUMBER; }
[a-zA-Z_][a-zA-Z0-9_]* { return IDENT; }

"("             return LPAREN;
")"             return RPAREN;
"{"             return LBRACE;
"}"             return RBRACE;
";"             return SEMICOLON;

"+"             return PLUS;
"-"             return MINUS;
"*"             return TIMES;
"/"             return DIVIDE;
"="             return ASSIGN;

"<="            return LE;
">="            return GE;
"<"             return LT;
">"             return GT;
"=="            return EQ;
"!="            return NEQ;

[ \t\r\n]+      ; // ignora espaços em branco

.               { printf("Caractere desconhecido: %s\n", yytext); }

%%


