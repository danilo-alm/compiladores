%{
#include "parser.tab.h"
%}
%option noyywrap

%%
"int"           return INT;
"return"        return RETURN;
"if"            return IF;
"else"          return ELSE;

[0-9]+          { yylval.num = atoi(yytext); return NUMBER; }
[A-Za-z_][A-Za-z0-9_]* { yylval.id = strdup(yytext); return IDENT; }

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

[ \t\r\n]+      /* skip whitespace */;
"//".*          /* skip line comment */;
"/*"([^*]|\*+[^*/])*\*+"/"  /* skip block comment */;
.               /* any other character: ignore or report */;
%% 

