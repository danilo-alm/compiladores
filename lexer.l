%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Mirror the Node type so parser.tab.h’s YYSTYPE.node works */
typedef struct node {
    int type;
    union {
        int num;
        char *id;
        struct {
            struct node *left, *right;
            int op;
        } op;
    };
} Node;

/* Prototypes for AST builders (linking) */
extern Node* create_num_node(int);
extern Node* create_ident_node(char*);
extern Node* create_op_node(Node*,Node*,int);
extern void print_ast(Node*,int);

/* Bring in the tokens and union definition */
#include "parser.tab.h"
%}

%option noyywrap

%%

"int"           return INT;
"return"        return RETURN;
"if"            return IF;
"else"          return ELSE;

[0-9]+          { yylval.num = atoi(yytext); return NUMBER; }
[A-Za-z_][A-Za-z0-9_]* {
                  yylval.id = strdup(yytext);
                  return IDENT;
                }

"=="            return EQ;
"!="            return NEQ;
"<="            return LE;
">="            return GE;
"<"             return LT;
">"             return GT;

"="             return ASSIGN;
"+"             return PLUS;
"-"             return MINUS;
"*"             return TIMES;
"/"             return DIVIDE;

"("             return LPAREN;
")"             return RPAREN;
"{"             return LBRACE;
"}"             return RBRACE;
";"             return SEMICOLON;

[ \t\r\n]+      /* skip whitespace */;
"//".*          /* skip line comment */;
"/*"([^*]|\*+[^*/])*\*+"/"  /* skip block comment */;
.               /* ignore everything else */;
%%

