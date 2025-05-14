%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* ——— AST node definition ——— */
typedef struct node {
    int type;
    union {
        int num;
        char *id;
        struct {
            struct node *left, *middle, *right;
            int op;
        } op3;   /* re-use for 3-child nodes */
        struct {
            struct node *first;
            struct node *next;
        } list;  /* linked list of statements */
    };
} Node;

/* AST kinds */
#define AST_NUM        1
#define AST_IDENT      2
#define AST_OPERATION  3
#define AST_RETURN     4
#define AST_IF         5
#define AST_BLOCK      6
#define AST_FUNCTION   7

/* Operator codes */
#define OP_PLUS   '+'
#define OP_MINUS  '-'
#define OP_TIMES  '*'
#define OP_DIVIDE '/'
#define OP_LT     '<'
#define OP_LE     'l'
#define OP_GT     '>'
#define OP_GE     'g'
#define OP_EQ     'e'
#define OP_NEQ    'n'
#define OP_CALL   'C'

/* Helpers */
Node* make_num(int n) {
    Node *x = malloc(sizeof *x);
    x->type = AST_NUM; x->num = n; return x;
}
Node* make_ident(char *s) {
    Node *x = malloc(sizeof *x);
    x->type = AST_IDENT; x->id = strdup(s); return x;
}
Node* make_op(Node *l, Node *r, int op) {
    Node *x = malloc(sizeof *x);
    x->type = AST_OPERATION;
    x->op3.left = l; x->op3.right = r; x->op3.op = op;
    return x;
}
Node* make_return(Node *expr) {
    Node *x = malloc(sizeof *x);
    x->type = AST_RETURN;
    x->op3.left = expr;
    return x;
}
Node* make_if(Node *cond, Node *then_stmt) {
    Node *x = malloc(sizeof *x);
    x->type = AST_IF;
    x->op3.left = cond;
    x->op3.middle = then_stmt;
    return x;
}
Node* make_block(Node *stmt_list) {
    Node *x = malloc(sizeof *x);
    x->type = AST_BLOCK;
    x->list.first = stmt_list;
    return x;
}
Node* make_function(char *name, char *param, Node *body) {
    Node *x = malloc(sizeof *x);
    x->type = AST_FUNCTION;
    x->op3.left   = make_ident(name);
    x->op3.middle = make_ident(param);
    x->op3.right  = body;
    return x;
}
/* list helper */
Node* prepend_stmt(Node *stmt, Node *list) {
    Node *x = malloc(sizeof *x);
    x->type = AST_BLOCK; /* reuse block for list nodes */
    x->list.first = stmt;
    x->list.next  = list;
    return x;
}

void print_ast(Node *n, int lvl) {
    if (!n) return;
    for (int i = 0; i < lvl; i++) putchar(' ');
    switch(n->type) {
      case AST_NUM:        printf("Num: %d\n", n->num); break;
      case AST_IDENT:      printf("Ident: %s\n",n->id); break;
      case AST_OPERATION:  printf("Op: %c\n", n->op3.op);
                           print_ast(n->op3.left, lvl+2);
                           print_ast(n->op3.right,lvl+2);
                           break;
      case AST_RETURN:     printf("Return:\n");
                           print_ast(n->op3.left, lvl+2);
                           break;
      case AST_IF:         printf("If:\n");
                           print_ast(n->op3.left,   lvl+2);
                           print_ast(n->op3.middle,lvl+2);
                           break;
      case AST_BLOCK: {    
                           printf("Block:\n");
                           for(Node *c = n->list.first; c; c = c->list.next)
                               print_ast(c, lvl+2);
                       } break;
      case AST_FUNCTION:   printf("Function:\n");
                           print_ast(n->op3.left,   lvl+2);  /* name */
                           print_ast(n->op3.middle,lvl+2);  /* param */
                           print_ast(n->op3.right, lvl+2);  /* body */
                           break;
    }
}

extern char *yytext;
int yylex(void);
void yyerror(const char *s) { fprintf(stderr,"Erro: %s\n",s); exit(1); }
%}

/* Precedences */
%left EQ NEQ
%left LT LE GT GE
%left '+' '-'
%left '*' '/'

%union {
    int    num;
    char  *id;
    Node  *node;
}

%token         INT RETURN IF ELSE
%token <num>   NUMBER
%token <id>    IDENT
%token         LPAREN RPAREN LBRACE RBRACE SEMICOLON
%token         PLUS MINUS TIMES DIVIDE ASSIGN
%token         LT LE GT GE EQ NEQ

%type <node> program function stmt_list statement expression

%%

program:
    function
    { print_ast($1,0); printf("Fim.\n"); }
;

function:
    INT IDENT LPAREN INT IDENT RPAREN LBRACE stmt_list RBRACE
    { $$ = make_function($2, $5, make_block($8)); }
;

stmt_list:
      /* empty */          { $$ = NULL; }
    | stmt_list statement { $$ = prepend_stmt($2, $1); }
;
statement:
    IF LPAREN expression RPAREN statement
    { $$ = make_if($3, $5); }
    | RETURN expression SEMICOLON
        { $$ = make_return($2); }
    | LBRACE stmt_list RBRACE
        { $$ = make_block($2); }
;

expression:
      expression PLUS expression
        { $$ = make_op($1,$3,OP_PLUS); }
    | expression MINUS expression
        { $$ = make_op($1,$3,OP_MINUS); }
    | expression TIMES expression
        { $$ = make_op($1,$3,OP_TIMES); }
    | expression DIVIDE expression
        { $$ = make_op($1,$3,OP_DIVIDE); }
    | expression LT expression
        { $$ = make_op($1,$3,OP_LT); }
    | expression LE expression
        { $$ = make_op($1,$3,OP_LE); }
    | expression GT expression
        { $$ = make_op($1,$3,OP_GT); }
    | expression GE expression
        { $$ = make_op($1,$3,OP_GE); }
    | expression EQ expression
        { $$ = make_op($1,$3,OP_EQ); }
    | expression NEQ expression
        { $$ = make_op($1,$3,OP_NEQ); }
    | IDENT LPAREN expression RPAREN
        { $$ = make_op(make_ident($1), $3, OP_CALL); }
    | NUMBER
        { $$ = make_num($1); }
    | IDENT
        { $$ = make_ident($1); }
;

%%

int main(void) {
    printf("Analisador iniciado...\n");
    return yyparse();
}

