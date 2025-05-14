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
            struct node *left, *right;
            int op;
        } op;
    };
} Node;

/* AST kinds */
#define AST_NUM       1
#define AST_IDENT     2
#define AST_OPERATION 3

/* AST‐operator codes (distinct from Bison token names) */
#define AST_OP_PLUS   '+'
#define AST_OP_MINUS  '-'
#define AST_OP_TIMES  '*'
#define AST_OP_DIVIDE '/'
#define AST_OP_LT     '<'
#define AST_OP_LE     'l'   /* <= */
#define AST_OP_GT     '>'
#define AST_OP_GE     'g'   /* >= */
#define AST_OP_EQ     'e'   /* == */
#define AST_OP_NEQ    'n'   /* != */
#define AST_OP_CALL   'C'

/* Helpers to build AST nodes */
Node* create_num_node(int n) {
    Node *x = malloc(sizeof *x);
    x->type = AST_NUM; x->num = n;
    return x;
}
Node* create_ident_node(char *s) {
    Node *x = malloc(sizeof *x);
    x->type = AST_IDENT; x->id = strdup(s);
    return x;
}
Node* create_op_node(Node *l, Node *r, int op) {
    Node *x = malloc(sizeof *x);
    x->type = AST_OPERATION;
    x->op.left  = l;
    x->op.right = r;
    x->op.op    = op;
    return x;
}

/* Print AST for debugging */
void print_ast(Node *n, int lvl) {
    if (!n) return;
    for (int i = 0; i < lvl; i++) putchar(' ');
    if (n->type == AST_NUM)
        printf("Num: %d\n", n->num);
    else if (n->type == AST_IDENT)
        printf("Ident: %s\n", n->id);
    else {
        printf("Op: %c\n", n->op.op);
        print_ast(n->op.left,  lvl+2);
        print_ast(n->op.right, lvl+2);
    }
}

/* Flex interface */
extern char *yytext;
int  yylex(void);
void yyerror(const char *s) { fprintf(stderr,"Erro: %s\n",s); exit(1); }
%}

/* Precedence declarations on Bison tokens */
%left EQ NEQ
%left LT LE GT GE
%left PLUS MINUS
%left TIMES DIVIDE

/* Semantic-value union */
%union {
    int    num;   /* for NUMBER */
    char  *id;    /* for IDENT */
    Node  *node;  /* for AST nodes */
}

/* Token declarations */
%token        INT RETURN IF ELSE
%token <num>  NUMBER
%token <id>   IDENT
%token        LPAREN RPAREN LBRACE RBRACE SEMICOLON

/* Operator tokens */
%token        PLUS MINUS TIMES DIVIDE ASSIGN
%token        LT LE GT GE EQ NEQ

/* Nonterminals producing AST nodes */
%type  <node> program function stmt_list statement expression

%%

program:
    function
    {
      print_ast($1,0);
      printf("Código correto!\n");
    }
;

function:
    INT IDENT LPAREN INT IDENT RPAREN LBRACE stmt_list RBRACE
    {
      /* use the AST of the last statement as the root */
      $$ = $8;
    }
;

stmt_list:
      /* empty */           { $$ = NULL; }
    | stmt_list statement   { $$ = $2; }
;

statement:
      IF LPAREN expression RPAREN statement
      { $$ = $3; }
    | RETURN expression SEMICOLON
      { $$ = $2; }
    | LBRACE stmt_list RBRACE
      { $$ = $2; }
;

expression:
      expression PLUS expression   
        { $$ = create_op_node($1, $3, AST_OP_PLUS); }
    | expression MINUS expression  
        { $$ = create_op_node($1, $3, AST_OP_MINUS); }
    | expression TIMES expression  
        { $$ = create_op_node($1, $3, AST_OP_TIMES); }
    | expression DIVIDE expression 
        { $$ = create_op_node($1, $3, AST_OP_DIVIDE); }
    | expression LT expression     
        { $$ = create_op_node($1, $3, AST_OP_LT); }
    | expression LE expression     
        { $$ = create_op_node($1, $3, AST_OP_LE); }
    | expression GT expression     
        { $$ = create_op_node($1, $3, AST_OP_GT); }
    | expression GE expression     
        { $$ = create_op_node($1, $3, AST_OP_GE); }
    | expression EQ expression     
        { $$ = create_op_node($1, $3, AST_OP_EQ); }
    | expression NEQ expression    
        { $$ = create_op_node($1, $3, AST_OP_NEQ); }
    | IDENT LPAREN expression RPAREN
        { $$ = create_op_node(create_ident_node($1), $3, AST_OP_CALL); }
    | NUMBER                       
        { $$ = create_num_node($1); }
    | IDENT                        
        { $$ = create_ident_node($1); }
;

%%

int main(void) {
    printf("Analisador iniciado...\n");
    return yyparse();
}

