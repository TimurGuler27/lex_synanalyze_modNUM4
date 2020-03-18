/*
      gulerverbrugge.y
	  created by Eli Verbrugge and Timur Guler
 	Specifications for the MFPL language, YACC input file.

      To create syntax analyzer:

        flex mfpl.l
        bison mfpl.y
        g++ mfpl.tab.c -o mfpl_parser
        mfpl_parser < inputFileName
 */

/*
 *	Declaration section.
 */
%{
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <string>
#include <stack>
#include "SymbolTable.h"
using namespace std;

int lineNum = 1; 	// line # being processed

stack<SYMBOL_TABLE> scopeStack;    // stack of scope hashtables

#define UNDEFINED  -1   // Type codes
#define FUNCTION 0
#define INT 1
#define STR 2
#define INT_OR_STR 3
#define BOOL 4
#define INT_OR_BOOL 5
#define STR_OR_BOOL 6
#define INT_OR_STR_OR_BOOL 7

#define ARITHMETIC_OP 97
#define LOGICAL_OP 98
#define RELATIONAL_OP 99

#define NOT_APPLICABLE -1

void beginScope();
void endScope();
void cleanUp();
void prepareToTerminate();
void bail();
bool findEntryInAnyScope(const string theName);

void printRule(const char*, const char*);
int yyerror(const char* s) 
{
  printf("Line %d: %s\n", lineNum, s);
  bail();
}

extern "C" 
{
    int yyparse(void);
    int yylex(void);
    int yywrap() {return 1;}
}

%}

%union 
{
  char* text;
  TYPE_INFO typeInfo;
};

/*
 *	Token declarations
*/
%token  T_LPAREN T_RPAREN 
%token  T_IF T_LETSTAR T_LAMBDA T_PRINT T_INPUT T_PROGN T_EXIT
%token  T_ADD  T_SUB  T_MULT  T_DIV
%token  T_LT T_GT T_LE T_GE T_EQ T_NE T_AND T_OR T_NOT	 
%token  T_INTCONST T_STRCONST T_T T_NIL T_IDENT T_UNKNOWN

%type <text> T_IDENT
%type <typeInfo> N_CONST N_EXPR N_PARENTHESIZED_EXPR N_IF_EXPR N_BIN_OP

/*
 *	Starting point.
 */
%start  N_START

/*
 *	Translation rules.
 */
%%
N_START		: // epsilon 
			{
			}
			| N_START N_EXPR
			{
			printf("\n---- Completed parsing ----\n\n");
			}
			;
N_EXPR		: N_CONST
			{
			$$.type = $1.type; 
			$$.numParams = $1.numParams;
			$$.returnType = $1.returnType;
			}
            | T_IDENT
            {
			TYPE_INFO found = findEntryInAnyScope(string($1));
			if (found.type != NOT_APPLICABLE) 
				yyerror("Undefined identifier");
			$$.type = found.type; 
			$$.numParams = found.numParams;
			$$.returnType = found.returnType;
			}
            | T_LPAREN N_PARENTHESIZED_EXPR T_RPAREN
            {
			$$.type = $2.type; 
			$$.numParams = $2.numParams;
			$$.returnType = $2.returnType;
			}
			;
N_CONST		: T_INTCONST
			{
			$$.type = INT;
			$$.numParams = NOT_APPLICABLE;
			$$.returnType = NOT_APPLICABLE;
			}
            | T_STRCONST
			{
			$$.type = STR;
			$$.numParams = NOT_APPLICABLE;
			$$.returnType = NOT_APPLICABLE;
			}
            | T_T
            {
			$$.type = BOOL;
			$$.numParams = NOT_APPLICABLE;
			$$.returnType = NOT_APPLICABLE;
			}
            | T_NIL
            {
			$$.type = BOOL;
			$$.numParams = NOT_APPLICABLE;
			$$.returnType = NOT_APPLICABLE;
			}
			;
N_PARENTHESIZED_EXPR	: N_ARITHLOGIC_EXPR 
				{
				$$.type = $1.type;
				$$.numParams = $1.numParams;
				$$.returnType = $1.returnType;
				}
            	| N_IF_EXPR 
				{
				$$.type = $1.type;
				$$.numParams = $1.numParams;
				$$.returnType = $1.returnType;
				}
            	| N_LET_EXPR 
				{
				$$.type = $1.type;
				$$.numParams = $1.numParams;
				$$.returnType = $1.returnType;
				}
                | N_LAMBDA_EXPR 
				{
				$$.type = $1.type;
				$$.numParams = $1.numParams;
				$$.returnType = $1.returnType;
				}
                | N_PRINT_EXPR 
				{
				$$.type = $1.type;
				$$.numParams = $1.numParams;
				$$.returnType = $1.returnType;
				}
                | N_INPUT_EXPR 
				{
				$$.type = $1.type;
				$$.numParams = $1.numParams;
				$$.returnType = $1.returnType;
				}
            	| N_PROGN_OR_USERFUNCTCALL 
				{
				$$.type = $1.type;
				$$.numParams = $1.numParams;
				$$.returnType = $1.returnType;
				}
				| T_EXIT
				{
				bail();
				}
				;
N_PROGN_OR_USERFUNCTCALL : N_FUNCT_NAME N_ACTUAL_PARAMS
				{
				}
				| T_LPAREN N_LAMBDA_EXPR T_RPAREN N_ACTUAL_PARAMS
				{
				}
				;
N_FUNCT_NAME	: T_PROGN
				{
				}
				| T_IDENT
				{
				if (findEntryInAnyScope(string($1)).type != NOT_APPLICABLE) 
				  yyerror("Undefined identifier");
				}
                     	;
N_ARITHLOGIC_EXPR	: N_UN_OP N_EXPR
				{
				if($2.type == FUNCTION)
					yyerror("Arg 1 cannot be a function");
				$$.type = BOOL;
				$$.numParams = NOT_APPLICABLE;
				$$.returnType = NOT_APPLICABLE;
				}
				| N_BIN_OP N_EXPR N_EXPR
				{
				}
                     	;
N_IF_EXPR   : T_IF N_EXPR N_EXPR N_EXPR
			{
			}
			;
N_LET_EXPR  : T_LETSTAR T_LPAREN N_ID_EXPR_LIST T_RPAREN N_EXPR
			{
			endScope();
			}
			;
N_ID_EXPR_LIST  : /* epsilon */
			{
			}
            | N_ID_EXPR_LIST T_LPAREN T_IDENT N_EXPR T_RPAREN 
			{
			string lexeme = string($3);
			printf("___Adding %s to symbol table\n", $3);
			bool success = scopeStack.top().addEntry(SYMBOL_TABLE_ENTRY(lexeme,
																		UNDEFINED));
			if (!success) 
				yyerror("Multiply defined identifier");
			}
			;
N_LAMBDA_EXPR   : T_LAMBDA T_LPAREN N_ID_LIST T_RPAREN N_EXPR
			{
			endScope();
			}
			;
N_ID_LIST       : /* epsilon */
			{
			}
            | N_ID_LIST T_IDENT 
			{
			string lexeme = string($2);
			printf("___Adding %s to symbol table\n", $2);
			bool success = scopeStack.top().addEntry(SYMBOL_TABLE_ENTRY(lexeme, 
								UNDEFINED));
			if (! success) 
				yyerror("Multiply defined identifier");
			}
			;
N_PRINT_EXPR    : T_PRINT N_EXPR
			{
			}
			;
N_INPUT_EXPR    : T_INPUT
			{
			}
			;
N_EXPR_LIST : N_EXPR N_EXPR_LIST  
			{
			}
            | /* epsilon */
			{
			}
			;
N_BIN_OP	     : N_ARITH_OP
			{
			}
			|
			N_LOG_OP
			{
			}
			|
			N_REL_OP
			{
			}
			;
N_ARITH_OP	     : T_ADD
			{
			}
                | T_SUB
			{
			}
			| T_MULT
			{
			}
			| T_DIV
			{
			}
			;
N_REL_OP	: T_LT
			{
			}	
			| T_GT
			{
			}	
			| T_LE
			{
			}	
			| T_GE
			{
			}	
			| T_EQ
			{
			}	
			| T_NE
			{
			}
			;	
N_LOG_OP	: T_AND
			{
			}	
			| T_OR
			{
			}
			;
N_UN_OP	     : T_NOT
			{
			}
			;
N_ACTUAL_PARAMS	: //epsilon
				{
				}
				| N_EXPR_LIST
				{
				}
				;
%%

#include "lex.yy.c"
extern FILE *yyin;

void printRule(const char* lhs, const char* rhs) 
{
  printf("%s -> %s\n", lhs, rhs);
  return;
}

void beginScope() 
{
  scopeStack.push(SYMBOL_TABLE());
  printf("\n___Entering new scope...\n\n");
}

void endScope() 
{
  scopeStack.pop();
  printf("\n___Exiting scope...\n\n");
}

TYPE_INFO findEntryInAnyScope(const string theName) 
{
  TYPE_INFO info = {UNDEFINED, UNDEFINED, UNDEFINED};
  if (scopeStack.empty( )) return(info);
  info = scopeStack.top().findEntry(theName);
  if (info.type != UNDEFINED)
    return(info);
  else 
  { // check in "next higher" scope
    SYMBOL_TABLE symbolTable = scopeStack.top( );
    scopeStack.pop( );
    info = findEntryInAnyScope(theName);
    scopeStack.push(symbolTable); // restore the stack
    return(info);
  }
}

void cleanUp() 
{
  if (scopeStack.empty()) 
    return;
  else 
  {
    scopeStack.pop();
    cleanUp();
  }
}

void prepareToTerminate()
{
  cleanUp();
  cout << endl << "Bye!" << endl;
}

void bail()
{
  prepareToTerminate();
  exit(1);
}

int main() 
{
  do {
	yyparse();
  } while (!feof(yyin));

  prepareToTerminate();
  return 0;
}
