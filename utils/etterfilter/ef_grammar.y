/*
    etterfilter -- grammar for filter source files

    Copyright (C) ALoR & NaGA

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

    $Header: /home/drizzt/dev/sources/ettercap.cvs/ettercap_ng/utils/etterfilter/ef_grammar.y,v 1.10 2003/09/16 12:08:41 alor Exp $
*/

%{

#include <ef.h>
#include <ef_functions.h>
#include <ec_strings.h>
#include <ec_filter.h>

#define YYERROR_VERBOSE

%}
 
/* 
 * ==========================================
 *          BISON Declarations 
 * ==========================================
 */
 
/* definition for the yylval (global variable) */
%union {
   char *string;     
   struct filter_op fop;
}

/* token definitions */
%token TOKEN_EOL

%token <fop> TOKEN_CONST     /* an integer number */
%token <fop> TOKEN_OFFSET    /* an offset in the form xxxx.yyy.zzzzz */
%token <fop> TOKEN_STRING    /* a string "xxxxxx" */
%token <fop> TOKEN_FUNCTION  /* a function */

%token TOKEN_IF          /*  if ( ) {  */
%token TOKEN_ELSE        /*  } else {  */

%token TOKEN_OP_NOT      /*  !  */
%token TOKEN_OP_AND      /*  &&  */
%token TOKEN_OP_OR       /*  ||  */

%token TOKEN_OP_ASSIGN   /*  =  */
%token TOKEN_OP_CMP_EQ   /*  ==  */
%token TOKEN_OP_CMP_LT   /*  <  */
%token TOKEN_OP_CMP_GT   /*  >  */
%token TOKEN_OP_CMP_LEQ  /*  <=  */
%token TOKEN_OP_CMP_GEQ  /*  >=  */

%token TOKEN_OP_END      /*  ;  */

%token TOKEN_PAR_OPEN    /*  (  */
%token TOKEN_PAR_CLOSE   /*  )  */

%token TOKEN_BLK_BEGIN   /*  {  */
%token TOKEN_BLK_END     /*  }  */

%token TOKEN_UNKNOWN

/* non terminals */
%type <fop> instruction
%type <fop> conditions
%type <fop> offset
%type <fop> math_expr

/* precedences */
%left TOKEN_OP_SUB TOKEN_OP_ADD
%left TOKEN_OP_MUL TOKEN_OP_DIV
%left TOKEN_UMINUS /* unary minus */

%left TOKET_OP_AND
%left TOKET_OP_OR
%left TOKET_OP_NOT

%%

/* 
 * ==========================================
 *          GRAMMAR Definitions 
 * ==========================================
*/

/* general line, can be empty or not */ 
input: /* empty line */
      | input block
      ;
     
block:   /* empty block */
      |  if_statement block
      |  if_else_statement block
      |  single_instruction block
      ;
      
/* every instruction must be terminated with ; */      
single_instruction: 
         instruction TOKEN_OP_END 
      ;

/* instructions are functions or assignment */
instruction: 
         TOKEN_FUNCTION { 
            printf("\tfunction\n"); 
            /* functions are encoded by the lexycal analyzer */
         }

      |  offset TOKEN_OP_ASSIGN math_expr { 
            printf("\tassignment\n"); 
            /* math_expr is always a value, so we can add it to an offset */
            $$.op.assign.offset = $1.op.assign.offset + $3.op.assign.value;
            $$.opcode = FOP_ASSIGN;
         }
      ;

/* the if statement */
if_statement: 
         TOKEN_IF TOKEN_PAR_OPEN conditions TOKEN_PAR_CLOSE TOKEN_BLK_BEGIN block TOKEN_BLK_END 
         { printf("\tONLY IF\n"); }
      ;
      
/* if {} else {} */      
if_else_statement: 
         TOKEN_IF TOKEN_PAR_OPEN conditions TOKEN_PAR_CLOSE TOKEN_BLK_BEGIN block TOKEN_BLK_END TOKEN_ELSE TOKEN_BLK_BEGIN block TOKEN_BLK_END
         { printf("\tIF ELSE\n"); }
      ;

/* conditions used by the if statement */
conditions: 
         offset TOKEN_OP_CMP_EQ TOKEN_STRING { 
            printf("\tcondition cmp string\n"); 
            $$.opcode = FOP_TEST;
            $$.op.test.op = FTEST_EQ;
         }

      |  offset TOKEN_OP_CMP_EQ TOKEN_CONST { 
            printf("\tcondition cmp eq\n");
            $$.opcode = FOP_TEST;
            $$.op.test.op = FTEST_EQ;
         }
         
      |  offset TOKEN_OP_CMP_LT TOKEN_CONST { 
            printf("\tcondition cmp lt\n"); 
            $$.opcode = FOP_TEST;
            $$.op.test.op = FTEST_LT;
         }

      |  offset TOKEN_OP_CMP_GT TOKEN_CONST { 
            printf("\tcondition cmp gt\n");
            $$.opcode = FOP_TEST;
            $$.op.test.op = FTEST_GT;
         }

      |  offset TOKEN_OP_CMP_LEQ TOKEN_CONST { 
            printf("\tcondition cmp leq\n");
            $$.opcode = FOP_TEST;
            $$.op.test.op = FTEST_LEQ;
         }

      |  offset TOKEN_OP_CMP_GEQ TOKEN_CONST { 
            printf("\tcondition cmp geq\n"); 
            $$.opcode = FOP_TEST;
            $$.op.test.op = FTEST_GEQ;
         }
      
      |  TOKEN_FUNCTION { 
            printf("\tcondition func\n"); 
            /* functions are encoded by the lexycal analyzer */
         }

      |  TOKEN_OP_NOT conditions { printf("\tcondition NOT\n"); }
      |  conditions TOKEN_OP_AND conditions { printf("\tcondition AND\n"); } 
      |  conditions TOKEN_OP_OR conditions { printf("\tcondition OR\n"); } 
      ;

/* offsets definitions */
offset:
         TOKEN_OFFSET {
            $$.op.test.offset = $1.op.test.offset;
         }
         
      |  offset TOKEN_OP_ADD math_expr {
            /* 
             * we are lying here, but math_expr operates
             * only on values, so we can add it to offset
             */
            $$.op.test.offset = $1.op.test.offset + $3.op.test.value; 
         }
         
      |  offset TOKEN_OP_SUB math_expr {
            $$.op.test.offset = $1.op.test.offset - $3.op.test.value; 
         }
      ;

/* math expression */
math_expr: 
         TOKEN_CONST  { 
            $$.op.test.value = $1.op.test.value; 
         }
         
      |  math_expr TOKEN_OP_ADD math_expr { 
            $$.op.test.value = $1.op.test.value + $3.op.test.value;
         }
         
      |  math_expr TOKEN_OP_SUB math_expr {
            $$.op.test.value = $1.op.test.value - $3.op.test.value;
         }
         
      |  math_expr TOKEN_OP_MUL math_expr {
            $$.op.test.value = $1.op.test.value * $3.op.test.value;
         }
         
      |  math_expr TOKEN_OP_DIV math_expr {
            $$.op.test.value = $1.op.test.value / $3.op.test.value;
         }
         
      |  TOKEN_OP_SUB math_expr %prec TOKEN_UMINUS {
            $$.op.test.value = -$2.op.test.value;
         }
      ;

%%

/* 
 * ==========================================
 *                C Code  
 * ==========================================
 */

/*
 * name of the tokens as they should be presented to the user
 */
struct {
   char *name;
   char *string;
} errors_array[] = 
   {
      { "TOKEN_CONST", "integer" },
      { "TOKEN_OFFSET", "offset" },
      { "TOKEN_FUNCTION", "function" },
      { "TOKEN_IF", "'if'" },
      { "TOKEN_ELSE", "'else'" },
      { "TOKEN_OP_NOT", "'!'" },
      { "TOKEN_OP_AND", "'&&'" },
      { "TOKEN_OP_OR", "'||'" },
      { "TOKEN_OP_EQ", "'='" },
      { "TOKEN_CMP_EQ", "'=='" },
      { "TOKEN_CMP_LT", "'<'" },
      { "TOKEN_CMP_GT", "'>'" },
      { "TOKEN_CMP_LEQ", "'<='" },
      { "TOKEN_CMP_GEQ", "'>='" },
      { "TOKEN_OP_END", "';'" },
      { "TOKEN_OP_ADD", "'+'" },
      { "TOKEN_OP_MUL", "'*'" },
      { "TOKEN_OP_DIV", "'/'" },
      { "TOKEN_OP_SUB", "'-'" },
      { "TOKEN_PAR_OPEN", "'('" },
      { "TOKEN_PAR_CLOSE", "')'" },
      { "TOKEN_BLK_BEGIN", "'{'" },
      { "TOKEN_BLK_END", "'}'" },
      { "$end", "end of file" },
      { NULL, NULL }
   };

/*
 * This function is needed by bison. so it MUST exist.
 * It is the error handler.
 */
int yyerror(char *s)  
{ 
   char *error;
   int i = 0;

   /* make a copy to manipulate it */
   error = strdup(s);

   /* subsitute the error code with frendly messages */
   do {
      str_replace(&error, errors_array[i].name, errors_array[i].string);
   } while(errors_array[++i].name != NULL);

   /* special case for UNKNOWN */
   if (strstr(error, "TOKEN_UNKNOWN")) {
      str_replace(&error, "TOKEN_UNKNOWN", "'TOKEN_UNKNOWN'");
      str_replace(&error, "TOKEN_UNKNOWN", yylval.string);
   }
 
   /* print the actual error message */
   SCRIPT_ERROR("%s", error);

   SAFE_FREE(error);

   /* return the error */
   return 1;
}

/* EOF */

// vim:ts=3:expandtab

