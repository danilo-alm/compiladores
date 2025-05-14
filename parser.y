%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Flex’s global text buffer */
extern char *yytext;
/* Prototype for the lexer and error handler */
int  yylex(void);
void yyerror(const char *s);

/* --- AST node definitions --- */
typedef struct node {
    int type;
    union {
        int num;        /* literal number */
        char *id;       /* identifier */
        struct {
            struct node *left;
            struct node *right;
            int op;
        } op;           /* binary operation */
    };
} Node;

/* AST node kinds */
#define AST_NUM       1
#define AST_IDENT     2
#define AST_OPERATION 3

/* Operator codes */
#define OP_PLUS   1
#define OP_MINUS  2
#define OP_TIMES  3
#define OP_DIVIDE 4
#define OP_LT     5
#define OP_LE     6
#define OP_GT     7
#define OP_GE     8
#define OP_EQ     9
#define OP_NEQ   10

/* Node-creation helpers */
Node* create_num_node(int num) {
    Node *n = malloc(sizeof(*n));
    n->type = AST_NUM;
    n->num  = num;
    return n;
}
Node* create_ident_node(char *id) {
    Node *n = malloc(sizeof(*n));
    n->type = AST_IDENT;
    n->id   = strdup(id);
    return n;
}
Node* create_op_node(Node *l, Node *r, int op) {
    Node *n = malloc(sizeof(*n));
    n->type      = AST_OPERATION;
    n->op.left   = l;
    n->op.right  = r;
    n->op.op     = op;
    return n;
}

/* Print AST (for debugging) */
void print_ast(Node *node, int level) {
    if (!node) return;
    for (int i = 0; i < level; i++) putchar(' ');
    switch (node->type) {
      case AST_NUM:
        printf("Num: %d\n", node->num);
        break;
      case AST_IDENT:
        printf("Ident: %s\n", node->id);
        break;
      case AST_OPERATION:
        printf("Op: %d\n", node->op.op);
        print_ast(node->op.left,  level+2);
        print_ast(node->op.right, level+2);
        break;
    }
}
%}

/* Tell Bison about our value‐union */
%union {
    int    num;   /* for NUMBER */
    char  *id;    /* for IDENT */
    Node  *node;  /* for everything that builds an AST node */
}

/* Token declarations */
%token         INT RETURN IF ELSE
%token <num>   NUMBER
%token <id>    IDENT
%token         LPAREN RPAREN LBRACE RBRACE SEMICOLON
%token         PLUS MINUS TIMES DIVIDE ASSIGN
%token         LT LE GT GE EQ NEQ

/* Nonterminals that produce AST nodes */
%type  <node>  program function statements statement expression

%%

program:
    function                { 
        print_ast($1, 0);
        printf("Código correto!\n");
    }
;

function:
    INT IDENT LPAREN INT IDENT RPAREN LBRACE statements RBRACE
    { 
        /* We choose the AST of the last statement as the root */
        $$ = $8;
    }
;

statements:
    statement               { $$ = $1; }
  | statements statement   { $$ = $2; }
;

statement:
    RETURN expression SEMICOLON
    { $$ = $2; }
  | IF LPAREN expression RPAREN statement
    { $$ = $3; /* ignore the body, just pass the condition node along */ }
  | LBRACE statements RBRACE
    { $$ = $2; }
;

expression:
    expression PLUS expression
    { $$ = create_op_node($1, $3, OP_PLUS); }
  | expression MINUS expression
    { $$ = create_op_node($1, $3, OP_MINUS); }
  | expression TIMES expression
    { $$ = create_op_node($1, $3, OP_TIMES); }
  | expression DIVIDE expression
    { $$ = create_op_node($1, $3, OP_DIVIDE); }
  | expression LT expression
    { $$ = create_op_node($1, $3, OP_LT); }
  | expression LE expression
    { $$ = create_op_node($1, $3, OP_LE); }
  | expression GT expression
    { $$ = create_op_node($1, $3, OP_GT); }
  | expression GE expression
    { $$ = create_op_node($1, $3, OP_GE); }
  | expression EQ expression
    { $$ = create_op_node($1, $3, OP_EQ); }
  | expression NEQ expression
    { $$ = create_op_node($1, $3, OP_NEQ); }
  | NUMBER
    { $$ = create_num_node($1); }
  | IDENT
    { $$ = create_ident_node($1); }
;

%%

/* Error handler */
void yyerror(const char *s) {
    fprintf(stderr, "Erro: %s\n", s);
}

/* Entry point */
int main(void) {
    printf("Analisador iniciado...\n");
    return yyparse();
}

