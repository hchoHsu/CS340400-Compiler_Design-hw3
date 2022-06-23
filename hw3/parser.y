%{
    #include <stdio.h>
    #include <string.h>
    #include <stdlib.h>
    #define DBG 0
    #define MAX_SYMBOL 200
    int yylex(void);
    int yyerror(char *);

    enum MODE {FUNC, VAR, ARG, PTR, ARY, CHAR4};

    struct node {
        char *type;         // string record nodetype
        struct node **grammer_list;    // grammer[0], grammer[1]...
        int list_len;                   // grammer length
        union {
            int ival;
            double fval;
            char *sval;
        };
    };

    struct symbol_table {
        char *name;
        int scope;
        int offset;
        int mode;
        int isreturn;
        int total_args;
        int loaded_args;
        int total_locals;
        int total_saved;
    } table[MAX_SYMBOL];

    int cur_scope = 0;
    int symbol_num = 0;
    int cur_func = -1;
    int label_num = 0;
    int true_false_lb = 0;

    int break_stack[10];
    int break_top = -1;

    struct node* create_node(char* type, int list_len);
    struct node* create_string_node(char* content);
    void decl_settype(struct node* cur, int mode);
    int look_table(char *name);
    int look_table_check_scope(char *name, int scope);
    
%}
 
%union {
    int ival;
    double fval;
    char *sval;
    struct node *nptr;
}
%token <ival> INTEGER
%token <sval> IDENT CONST_TYPE
%token CONST INT_TYPE CHAR_TYPE CHAR4_TYPE
%token FOR DO WHILE IF ELSE
%token LE_OP GE_OP EQ_OP NE_OP
%token BREAK RETURN

/* Associativity + Precedence */
%left '+' '-'
%left '*' '/' '%'
%nonassoc signel_grammer
%nonassoc IDENT
%right '(' '['
%nonassoc IFX
%nonassoc ELSE

/* define type for nonterminals */
// scalar definition
%type <nptr> init_declarator init_declarator_list
%type <nptr> declarator direct_declarator 
%type <sval> decl_specs decl_type
%type decl pointer initializer

// function decl/def
%type <nptr> func_decl func_def init_func
%type <nptr> parameter_def init_declarator_def
%type <ival> parameter_list

// statement
%type stmt for_stmt
%type compound_stmt compound_stmt_list

// expression
%type <ival> for_expr_3 while_expr do_prefix if_expr ifelse_prefix
%type <nptr> expr assign_expr log_or_expr log_and_expr
%type <nptr> bit_or_expr bit_xor_expr bit_and_expr equal_expr
%type <nptr> relation_expr
%type <nptr> shift_expr add_sub_expr MDR_expr
%type <nptr> unary_expr left_hand_side_unary_expr const_expr_style expr_parameter_list const_expr

%start program_start
%type program_start program

%%
program_start:
    program 
    ;

program:
    decl program 
    | func_decl program 
    | func_def  program 
    | decl 
    | func_decl 
    | func_def 
    ;

/* ================================= */
/* ======= Scalar declaration ====== */
/* ================================= */
decl:
    decl_specs init_declarator_list ';' {
        if (strcmp($1, "char4") == 0)
            decl_settype($2, CHAR4);
    }
    ;

decl_specs:
    CONST decl_type {$$ = $2;}
    | decl_type {$$ = $1;}
    | CONST CONST_TYPE {$$ = $2;}
    | CONST_TYPE       {$$ = $1;}
    ;

decl_type:
    CHAR_TYPE {$$ = "char";}
    | INT_TYPE {$$ = "int";}
    | CHAR4_TYPE {$$ = "char4";}
    ;

init_declarator_list:
    init_declarator {$$ = $1;}
    | init_declarator_list ',' init_declarator; {
        struct node *cur = create_node("decl_list", 2);
        cur->grammer_list[0] = $1;
        cur->grammer_list[1] = $3;
        $$ = cur;
    }

init_declarator:
    declarator                      { $$ = $1; }
    | declarator '=' initializer    {
        printf("  ld   t0, 0(sp)\n");
        int idx = look_table($1->sval);
        printf("  sd   t0, -%d(s0)\n", table[idx].offset);
        printf("  addi sp, sp, 8\n");
        $$ = $1;
    }
    ;

initializer:
    expr
    ;

declarator:
    direct_declarator   { $$ = $1; }
    | pointer direct_declarator {
        int idx = look_table($2->sval);
        table[idx].mode = PTR;
        $$ = $2;
    }
    ;

pointer:
    '*'
    ;

direct_declarator:
    IDENT { 
        struct node *cur = create_string_node($1);
        if (look_table_check_scope($1, cur_scope) < 0)
            symbol_insert_var($1, cur_scope, VAR);
        $$ = cur;
    }
    | IDENT '[' INTEGER ']' {
        struct node *cur = create_string_node($1);
        symbol_insert_var($1, cur_scope, ARY);  // insert a0
        // remain space for function
        table[cur_func].total_locals += $3 - 1;   // give other N-1 spaces
        $$ = cur;
    }
    ;



/* ============================================= */
/* ====== function declaration/definition ====== */
/* ============================================= */
func_decl:
    init_func '(' ')' ';' {
        cur_scope--;
        cur_func = -1;
    }
    | init_func '(' parameter_list ')' ';' {
        remove_from_symbol_table(cur_scope);
        int idx = look_table($1->sval);
        table[idx].total_args = $3;
        cur_scope--;
        cur_func = -1;
    }
    ;

func_def:   // TODO: arguments location wrong
    init_func '(' ')' compound_stmt
    {
        remove_from_symbol_table(cur_scope);
        cur_scope--;
        cur_func = -1;
        printf(".%s_funcExit:\n", $1->sval);
        printf("  ld   ra, 392(sp)\n");
        printf("  ld   s0, 384(sp)\n");
        printf("  addi sp, sp, 400\n");
        printf("  ret\n");
    }
    | init_func '(' parameter_list ')' compound_stmt
    {
        remove_from_symbol_table(cur_scope);
        cur_scope--;
        cur_func = -1;
        printf(".%s_funcExit:\n", $1->sval);
        printf("  ld   ra, 392(sp)\n");
        printf("  ld   s0, 384(sp)\n");
        printf("  addi sp, sp, 400\n");
        printf("  ret\n");
    }
    ;

init_func:
    decl_specs init_declarator {
        int idx = look_table($2->sval);
        cur_scope++;
        if (table[idx].mode != FUNC) {
            symbol_change_func(idx, 0, 0, 2);
            table[idx].isreturn = strcmp($1, "void") == 0 ? 0 : 1;
            printf(".global %s\n", $2->sval);
        }
        else {
            cur_func = idx;
            printf("%s:\n", $2->sval);
            printf("  addi sp, sp, -400\n");
            printf("  sd   ra, 392(sp)\n");
            printf("  sd   s0, 384(sp)\n");
            printf("  addi s0, sp, 400\n");
        }
        $$ = $2;
    }
    ;

// function definition parameters
parameter_list:
    parameter_def {
        if (cur_func >= 0) {
            int idx = look_table($1->sval);
            printf("  sd   a0, -%d(s0)\n", table[idx].offset);
        }
        $$ = 1;
    }
    | parameter_list ',' parameter_def {
        if (cur_func >= 0) {
            int idx = look_table($3->sval);
            printf("  sd   a%d, -%d(s0)\n", $1, table[idx].offset);
        }
        $$ = $1 + 1;
    }
    ;
parameter_def:
    decl_specs init_declarator_def {$$ = $2;};
init_declarator_def:
    IDENT {
        struct node *cur = create_string_node($1);
        if (look_table_check_scope($1, cur_scope) < 0)
            symbol_insert_var($1, cur_scope, ARG);
        $$ = cur;
    }
    | pointer IDENT {
        struct node *cur = create_string_node($2);
        if (look_table_check_scope($2, cur_scope) < 0)
            symbol_insert_var($2, cur_scope, ARG);
        int idx = look_table($2);
        table[idx].mode = PTR;
        $$ = cur;
    };


/* ======================== */
/* ====== Statement ======= */
/* ======================== */
stmt:
    expr ';'
    | IF '(' if_expr ')' compound_stmt %prec IFX {
        printf(".IFLB_%d:\n", $3-1);
        remove_from_symbol_table(cur_scope);
        cur_scope--;
    }
    | ifelse_prefix compound_stmt {
        printf(".IFLB_%d:\n", $1);
        remove_from_symbol_table(cur_scope);
        cur_scope--;
    }
    | while_prefix '(' while_expr ')' stmt {
        printf("  j    .LB_%d\n", $3-1);
        printf(".LB_%d:\n", $3);
        remove_from_symbol_table(cur_scope);
        cur_scope--;
        break_top--;
    }
    | do_prefix stmt WHILE '(' expr ')' ';' {
        printf("  ld   t0, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  bne  t0, x0, .LB_%d\n", $1);
        remove_from_symbol_table(cur_scope);
        cur_scope--;
    }
    | for_stmt {
        remove_from_symbol_table(cur_scope);
        cur_scope--;
        break_top--;
    }
    | RETURN expr ';' {
        printf("  ld   a0, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  j    .%s_funcExit\n", table[cur_func].name);
    }
    | RETURN ';' {
        printf("  j    .%s_funcExit\n", table[cur_func].name);
        remove_from_symbol_table(cur_scope);
        cur_scope--;
        cur_func = -1;
    }
    | BREAK ';' {
        printf("  j    .LB_%d\n", break_stack[break_top]);
    }
    | compound_stmt
    ;

/* IF ELSE */
ifelse_prefix:
    IF '(' if_expr ')' compound_stmt ELSE {
        printf("  j    .IFLB_%d\n", $3);
        printf(".IFLB_%d:\n", $3-1);
        remove_from_symbol_table(cur_scope);
        $$ = $3;
    };

/* If Part */
if_expr:
    expr {
        cur_scope++;
        true_false_lb += 2;
        printf("  ld   t0, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  beq  t0, x0, .IFLB_%d\n", true_false_lb-1);
        $$ = true_false_lb;
    };
/* Do While Part */
do_prefix:
    DO {
        label_num += 1;
        printf(".LB_%d:\n", label_num);
        cur_scope++;
        $$ = label_num;
    };
/* While Part */
while_prefix:
    WHILE {
        label_num += 2;
        printf(".LB_%d:\n", label_num-1);
    };
while_expr:
    expr {
        printf("  ld   t0, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  beq  t0, x0, .LB_%d\n", label_num);
        break_top++;
        break_stack[break_top] = label_num;
        cur_scope++;
        $$ = label_num;
    }
/* For Part */
for_stmt:
    FOR '(' for_expr_1 ';' for_expr_2 ';' for_expr_3 ')' stmt {
        printf("  j    .LB_%d\n", $7 - 2);
        printf(".LB_%d:\n", $7);
    };
for_expr_1:
    expr {  // i = 0, then jump to condition
        cur_scope++;
        label_num += 4;
        printf("  j    .LB_%d\n", label_num-3);
        printf(".LB_%d:\n", label_num-3);
    };
for_expr_2:
    expr {  // if condition != 0, true, go stmt
        printf("  ld   t0, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  bne  t0, x0, .LB_%d\n", label_num-1);
        printf("  j    .LB_%d\n", label_num);
        printf(".LB_%d:\n", label_num-2);
        break_top++;
        break_stack[break_top] = label_num;
    };
for_expr_3:
    expr {
        printf("  j    .LB_%d\n", label_num-3);
        printf(".LB_%d:\n", label_num-1);
        $$ = label_num;
    };

compound_stmt:
    '{' '}'
    | '{' compound_stmt_list '}'
    ;
compound_stmt_list:
    decl
    | stmt
    | compound_stmt_list decl
    | compound_stmt_list stmt
    ;

/* ======================== */
/* ====== expression ====== */
/* ======================== */
expr:
    assign_expr {
        $$ = $1;
    }
    ;


assign_expr:
    log_or_expr { $$ = $1; }
    | left_hand_side_unary_expr '=' assign_expr {
        printf("  ld   t0, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        
        if (strcmp($1->type, "ref") == 0) {
            printf("  ld   t1, 0(sp)\n");
            printf("  addi sp, sp, 8\n");
            printf("  sd   t0, 0(t1)\n");
        }
        else {
            int idx = look_table($1->sval);
            printf("  sd   t0, -%d(s0)\n", table[idx].offset);
            printf("  addi sp, sp, 8\n");
        }
        $$ = $1;
    }
    ;

left_hand_side_unary_expr:
    const_expr %prec signel_grammer { $$ = $1; }
    | '*' unary_expr {
        $2->type = "ref";
        $$ = $2;
    }
    | IDENT '[' expr ']' {
        struct node *cur = create_node("STRING", 0);
        cur->sval = $1;
        cur->type = "ref";
        $$ = cur;

        printf("  ld   t0, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  slli t0, t0, 3\n");

        int idx = look_table($1);
        if (table[idx].mode == PTR) {
            printf("  ld   t1, -%d(s0)\n", table[idx].offset);
        }
        else if (table[idx].mode == ARY) {
            printf("  addi t1, s0, -%d\n", table[idx].offset);
        }
        printf("  sub  t0, t1, t0\n");
        printf("  addi sp, sp, -8\n");
        printf("  sd   t0, 0(sp)\n");
    }
    ;

log_or_expr:
    log_and_expr { $$ = $1; }
    ;

log_and_expr:
    bit_or_expr { $$ = $1; }
    ;

bit_or_expr:
    bit_xor_expr { $$ = $1; }
    | bit_or_expr '|' bit_xor_expr {
        printf("  ld   t0, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  ld   t1, 0(sp)\n");
        printf("  or   t0, t0, t1\n");
        printf("  sd   t0, 0(sp)\n");
        $$ = $1;
    }
    ;

bit_xor_expr:
    bit_and_expr { $$ = $1; }
    | bit_xor_expr '^' bit_and_expr {
        printf("  ld   t0, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  ld   t1, 0(sp)\n");
        printf("  xor  t0, t0, t1\n");
        printf("  sd   t0, 0(sp)\n");
        $$ = $1;
    }
    ;

bit_and_expr:
    equal_expr { $$ = $1; }
    | bit_and_expr '&' equal_expr {
        printf("  ld   t0, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  ld   t1, 0(sp)\n");
        printf("  and  t0, t0, t1\n");
        printf("  sd   t0, 0(sp)\n");
        $$ = $1;
    }
    ;

equal_expr:
    relation_expr { $$ = $1; }
    | equal_expr EQ_OP relation_expr {
        printf("  ld   t0, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  ld   t1, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  beq  t0, t1, .trueLB_%d\n", true_false_lb);
        printf("  j    .falseLB_%d\n", true_false_lb);
        printf(".trueLB_%d:\n", true_false_lb);
        printf("  addi sp, sp, -8\n");
        printf("  li   t0, 1\n");
        printf("  sd   t0, 0(sp)\n");
        printf("  j    .tfLB_exit_%d\n", true_false_lb);
        printf(".falseLB_%d:\n", true_false_lb);
        printf("  addi sp, sp, -8\n");
        printf("  li   t0, 0\n");
        printf("  sd   t0, 0(sp)\n");
        printf(".tfLB_exit_%d:\n", true_false_lb);
        true_false_lb++;
    }
    | equal_expr NE_OP relation_expr {
        printf("  ld   t0, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  ld   t1, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  bne  t0, t1, .trueLB_%d\n", true_false_lb);
        printf("  j    .falseLB_%d\n", true_false_lb);
        printf(".trueLB_%d:\n", true_false_lb);
        printf("  addi sp, sp, -8\n");
        printf("  li   t0, 1\n");
        printf("  sd   t0, 0(sp)\n");
        printf("  j    .tfLB_exit_%d\n", true_false_lb);
        printf(".falseLB_%d:\n", true_false_lb);
        printf("  addi sp, sp, -8\n");
        printf("  li   t0, 0\n");
        printf("  sd   t0, 0(sp)\n");
        printf(".tfLB_exit_%d:\n", true_false_lb);
        true_false_lb++;
    }
    ; 

relation_expr:
    shift_expr { $$ = $1; }
    | relation_expr LE_OP shift_expr {
        printf("  ld   t1, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  ld   t0, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  bgt  t0, t1, .falseLB_%d\n", true_false_lb);
        printf("  j    .trueLB_%d\n", true_false_lb);
        printf(".trueLB_%d:\n", true_false_lb);
        printf("  addi sp, sp, -8\n");
        printf("  li   t0, 1\n");
        printf("  sd   t0, 0(sp)\n");
        printf("  j    .tfLB_exit_%d\n", true_false_lb);
        printf(".falseLB_%d:\n", true_false_lb);
        printf("  addi sp, sp, -8\n");
        printf("  li   t0, 0\n");
        printf("  sd   t0, 0(sp)\n");
        printf(".tfLB_exit_%d:\n", true_false_lb);
        true_false_lb++;
    }
    | relation_expr GE_OP shift_expr {
        printf("  ld   t1, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  ld   t0, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  blt  t0, t1, .falseLB_%d\n", true_false_lb);
        printf("  j    .trueLB_%d\n", true_false_lb);
        printf(".trueLB_%d:\n", true_false_lb);
        printf("  addi sp, sp, -8\n");
        printf("  li   t0, 1\n");
        printf("  sd   t0, 0(sp)\n");
        printf("  j    .tfLB_exit_%d\n", true_false_lb);
        printf(".falseLB_%d:\n", true_false_lb);
        printf("  addi sp, sp, -8\n");
        printf("  li   t0, 0\n");
        printf("  sd   t0, 0(sp)\n");
        printf(".tfLB_exit_%d:\n", true_false_lb);
        true_false_lb++;
    }
    | relation_expr '<' shift_expr {
        printf("  ld   t1, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  ld   t0, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  blt  t0, t1, .trueLB_%d\n", true_false_lb);
        printf("  j    .falseLB_%d\n", true_false_lb);
        printf(".trueLB_%d:\n", true_false_lb);
        printf("  addi sp, sp, -8\n");
        printf("  li   t0, 1\n");
        printf("  sd   t0, 0(sp)\n");
        printf("  j    .tfLB_exit_%d\n", true_false_lb);
        printf(".falseLB_%d:\n", true_false_lb);
        printf("  addi sp, sp, -8\n");
        printf("  li   t0, 0\n");
        printf("  sd   t0, 0(sp)\n");
        printf(".tfLB_exit_%d:\n", true_false_lb);
        true_false_lb++;
    }
    | relation_expr '>' shift_expr {
        printf("  ld   t1, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  ld   t0, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  bgt  t0, t1, .trueLB_%d\n", true_false_lb);
        printf("  j    .falseLB_%d\n", true_false_lb);
        printf(".trueLB_%d:\n", true_false_lb);
        printf("  addi sp, sp, -8\n");
        printf("  li   t0, 1\n");
        printf("  sd   t0, 0(sp)\n");
        printf("  j    .tfLB_exit_%d\n", true_false_lb);
        printf(".falseLB_%d:\n", true_false_lb);
        printf("  addi sp, sp, -8\n");
        printf("  li   t0, 0\n");
        printf("  sd   t0, 0(sp)\n");
        printf(".tfLB_exit_%d:\n", true_false_lb);
        true_false_lb++;
    }
    ;

shift_expr:
    add_sub_expr { $$ = $1; }
    ;

add_sub_expr:
    MDR_expr { $$ = $1; }
    | add_sub_expr '+' MDR_expr {
        printf("\n");
        printf("  ld   t1, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  ld   t0, 0(sp)\n");
        printf("  addi sp, sp, 8\n");

        if ($1 != NULL && $1->type != NULL && strcmp($1->type, "address") == 0) {
            printf("  slli t1, t1, 3\n");
            printf("  sub  t0, t0, t1\n");
        }
        else if ($1 != NULL && $1->type != NULL && strcmp($1->type, "char4") == 0) {
            printf("  kadd8 t0, t0, t1\n");
        }
        else {
            printf("  add  t0, t0, t1\n");
        }
        printf("  addi sp, sp, -8\n");
        printf("  sd   t0, 0(sp)\n");
        $$ = $1;
    }
    | add_sub_expr '-' MDR_expr {
        printf("\n");
        printf("  ld   t1, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  ld   t0, 0(sp)\n");
        printf("  addi sp, sp, 8\n");

        if ($1 != NULL && $1->type != NULL && strcmp($1->type, "address") == 0) {
            printf("  slli t1, t1, 3\n");
            printf("  add  t0, t0, t1\n");
        }
        else if ($1 != NULL && $1->type != NULL && strcmp($1->type, "char4") == 0) {
            printf("  ksub8 t0, t0, t1\n");
        }
        else {
            printf("  sub  t0, t0, t1\n");
        }
        
        printf("  addi sp, sp, -8\n");
        printf("  sd   t0, 0(sp)\n");
        $$ = $1;
    }
    ;

MDR_expr:
    unary_expr { $$ = $1; }
    | MDR_expr '*' unary_expr  {
        printf("  ld   t1, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  ld   t0, 0(sp)\n");
        printf("  mul  t0, t0, t1\n");
        printf("  sd   t0, 0(sp)\n");
        $$ = $1;
    }
    | MDR_expr '/' unary_expr  {
        printf("  ld   t1, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  ld   t0, 0(sp)\n");
        printf("  div  t0, t0, t1\n");
        printf("  sd   t0, 0(sp)\n");
        $$ = $1;
    }
    ;

unary_expr:
    const_expr_style %prec signel_grammer { $$ = $1; }
    | '*' unary_expr {
        printf("  ld   t0, 0(sp)\n");
        printf("  ld   t0, 0(t0)\n");
        printf("  sd   t0, 0(sp)\n");
        $2->type = "ref";
        $$ = $2;
    }
    | '&' unary_expr {
        printf("  addi sp, sp, 8\n");
        int idx = look_table($2->sval);
        printf("  addi t0, s0, -%d\n", table[idx].offset);
        printf("  addi sp, sp, -8\n");
        printf("  sd   t0, 0(sp)\n");
        $$ = $2;
    }
    | '+' unary_expr {
        $$ = $2;
    }
    | '-' unary_expr {
        printf("  li   t1, 0\n");
        printf("  ld   t0, 0(sp)\n");
        printf("  sub  t0, t1, t0\n");
        printf("  sd   t0, 0(sp)\n");
        $$ = $2;
    }
    ;

const_expr_style:
    const_expr %prec signel_grammer { $$ = $1; }
    | IDENT '[' expr ']' {
        printf("  ld   t1, 0(sp)\n");
        printf("  slli t1, t1, 3\n");
        printf("  addi sp, sp, 8\n");

        struct node *cur = create_node("STRING", 0);
        cur->sval = $1;

        int idx = look_table($1);
        if (table[idx].mode == ARY) {
            cur->type = "ary";
            printf("  addi sp, sp, -8\n");
            printf("  addi t0, s0, -%d\n", table[idx].offset);
            printf("  sd   t0, 0(sp)\n");
        }
        else {
            printf("  addi sp, sp, -8\n");
            printf("  ld   t0, -%d(s0)\n", table[idx].offset);
            printf("  sd   t0, 0(sp)\n");
        }
        printf("  ld   t0, 0(sp)\n");
        printf("  addi sp, sp, 8\n");
        printf("  sub  t0, t0, t1\n");
        printf("  ld   t0, 0(t0)\n");
        printf("  addi sp, sp, -8\n");
        printf("  sd   t0, 0(sp)\n");

        $$ = cur;
    }
    | IDENT '('  ')' {  // function()
        // printf("  addi sp, sp, -8\n");
        // printf("  sd ra, 0(sp)\n");
        printf("  jal  ra, %s\n", $1);
        // printf("  ld ra, 0(sp)\n");
        // printf("  addi sp, sp, 8\n");
        int idx = look_table($1);
        if(table[idx].isreturn > 0) {
            printf("  addi sp, sp, -8\n");
            printf("  sd   a0, 0(sp)\n");
        }
        struct node *cur = create_node("STRING", 0);
        cur->sval = $1;
        $$ = cur;
    }
    | IDENT '(' expr_parameter_list ')'{    // function(int a, int b)
        int idx = look_table($1);
        for(int i = table[idx].total_args-1; i >= 0; i--) {
            printf("  ld a%d, 0(sp)\n", i);
            printf("  addi sp, sp, 8\n");
        }
        if (strcmp($1, "digitalWrite") == 0 || strcmp($1, "delay") == 0) {
            printf("  addi sp, sp, -8\n");
            printf("  sd ra, 0(sp)\n");
        }
        printf("  jal ra, %s\n", $1);
        if (strcmp($1, "digitalWrite") == 0 || strcmp($1, "delay") == 0) {
            printf("  ld ra, 0(sp)\n");
            printf("  addi sp, sp, 8\n");
        }
        if(table[idx].isreturn > 0) {
            printf("  addi sp, sp, -8\n");
            printf("  sd   a0, 0(sp)\n");
        }
        struct node *cur = create_node("STRING", 0);
        cur->sval = $1;
        $$ = cur;
    }
    ;
expr_parameter_list:
    expr { $$ = $1; }
    | expr_parameter_list ',' expr 
    ;


const_expr:
    INTEGER         { 
                        struct node *cur = create_node("INTEGER", 0);
                        cur->ival = $1;
                        printf("  li   t0, %d\n", cur->ival);
                        printf("  addi sp, sp, -8\n");
                        printf("  sd   t0, 0(sp)\n");
                        $$ = cur;
                    }
    | IDENT         {
                        struct node *cur = create_node("STRING", 0);
                        cur->sval = $1;
                        int idx = look_table($1);
                        if (table[idx].mode == ARY) {
                            printf("  addi sp, sp, -8\n");
                            printf("  addi t0, s0, -%d\n", table[idx].offset);
                            printf("  sd   t0, 0(sp)\n");
                        }
                        else {
                            printf("  addi sp, sp, -8\n");
                            printf("  ld   t0, -%d(s0)\n", table[idx].offset);
                            printf("  sd   t0, 0(sp)\n");
                        }

                        if (table[idx].mode == ARY || table[idx].mode == PTR)
                            cur->type = "address";
                        if (table[idx].mode == CHAR4)
                            cur->type = "char4";

                        $$ = cur;
                    }
    | '(' expr ')'  {
                        struct node *cur = create_node("STRING", 2);
                        cur->sval = strdup("(");
                        struct node *nxt = create_node("STRING", 0);
                        nxt->sval = strdup(")");
                        cur->grammer_list[0] = $2;
                        cur->grammer_list[1] = nxt;
                        $$ = cur;
                    }
    ;

%%

struct node* create_node(char* type, int list_len){
    struct node *cur = (struct node*)malloc(sizeof(struct node));
    cur->list_len = list_len;

    if (type != NULL)
        cur->type = strdup(type);
    else cur->type = NULL;

    if (list_len != 0)
        cur->grammer_list = (struct node**)malloc(list_len*sizeof(struct node*));
    else cur->grammer_list = NULL;

    return cur;
}
struct node* create_string_node(char* content){
    struct node* cur = create_node("STRING", 0);
    cur->sval = strdup(content);
    return cur;
}
void decl_settype(struct node* cur, int mode){
    if (cur->list_len == 0) {
        int idx = look_table(cur->sval);
        table[idx].mode = mode;
        return;
    }
    for(int i = 0; i < cur->list_len; i++) {
        decl_settype(cur->grammer_list[i], mode);
    }
}

int look_table(char *name) {
    for(int i = symbol_num-1; i >= 0; i--) {
        /* printf("= look at %s: scope %d, mode %d\n", table[i].name, table[i].scope, table[i].mode); */
        if(strcmp(table[i].name, name) == 0) {
            return i;
        }
    }
    return -1;
}
int look_table_check_scope(char *name, int scope) {
    for(int i = symbol_num-1; i >= 0; i--) {
        /* printf("= look at %s: scope %d\n", table[i].name, table[i].scope); */
        if(strcmp(table[i].name, name) == 0 && table[i].scope == scope) {
            return i;
        }
    }
    return -1;
}

void remove_from_symbol_table(int scope) {  // 最大的scope全部拿掉
    while (symbol_num >= 0) {
        /* printf("= rm %s: scope %d\n", table[symbol_num-1].name, table[symbol_num-1].scope); */
        if (table[symbol_num-1].scope < scope)
            break;
        symbol_num--;
    }
}
void symbol_insert_var(char *name, int scope, int mode) {
    table[symbol_num].name = name;
    table[symbol_num].scope = scope;
    table[symbol_num].mode = mode;
    table[symbol_num].loaded_args = 0;

    table[symbol_num].isreturn = -1;
    table[symbol_num].total_args = -1;
    table[symbol_num].total_locals = -1;
    table[symbol_num].total_saved = -1;
    /* printf(">>>>>> Symbol %s: scope %d, mode %d\n", name, scope, mode); */

    if (cur_func < 0) {
        symbol_num++;
        return;
    }

    if (mode == VAR || mode == ARY) {
        int offset = table[cur_func].total_locals*8 + table[cur_func].total_saved*8 + table[cur_func].total_args*8 + 8;
        table[symbol_num].offset = offset;
        table[cur_func].total_locals++;
    }
    else if (mode == ARG) {
        int offset = table[cur_func].total_saved*8 + table[cur_func].loaded_args*8 + 8;
        table[symbol_num].offset = offset;
        table[cur_func].loaded_args++;
    }

    symbol_num++;
}
void symbol_change_func(int idx, int scope, int total_args, int total_saved) {
    table[idx].mode = FUNC;
    table[idx].total_args = total_args;
    table[idx].total_locals = 0;
    table[idx].total_saved = total_saved;
}
void symbol_insert_func(char *name, int scope, int total_args, int total_saved) {
    table[symbol_num].offset = -1;
    table[symbol_num].isreturn = -1;
    table[symbol_num].loaded_args = 0;

    table[symbol_num].name = name;
    table[symbol_num].scope = scope;
    table[symbol_num].mode = FUNC;
    table[symbol_num].total_args = total_args;
    table[symbol_num].total_locals = 0;
    table[symbol_num].total_saved = total_saved;

    symbol_num++;
}

void parser_initialize() {
    // insert 2 global functions
    symbol_insert_func("digitalWrite", 0, 2, 0);
    symbol_insert_func("delay", 0, 1, 0);
}

int yyerror(char *s){
    fprintf(stderr, "%s\n", s);
    return 0;
}

int main(){
    parser_initialize();
    yyparse();
    return 0;
}
