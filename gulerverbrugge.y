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
			}
			;
N_EXPR		: N_CONST
			{
			}
            | T_IDENT
            {
			if (!findEntryInAnyScope(string($1))) 
				yyerror("Undefined identifier");
			}
            | T_LPAREN N_PARENTHESIZED_EXPR T_RPAREN
            {
			}
			;
N_CONST		: T_INTCONST
			{
			}
            | T_STRCONST
			{
			}
            | T_T
            {
			}
            | T_NIL
            {
			}
			;
N_PARENTHESIZED_EXPR	: N_ARITHLOGIC_EXPR 
				{
				}
            	| N_IF_EXPR 
				{
				}
            	| N_LET_EXPR 
				{
				}
                | N_LAMBDA_EXPR 
				{
				}
                | N_PRINT_EXPR 
				{
				}
                | N_INPUT_EXPR 
				{
				}
            	| N_PROGN_OR_USERFUNCTCALL 
				{
				}
				| T_EXIT
				{
				bail();
				}
				;
N_PROGN_OR_USERFUNCTCALL : N_FUNCT_NAME N_EXPR_LIST
				{
				}
				;
N_FUNCT_NAME		: T_PROGN
				{
				}
				| T_IDENT
				{
				if (!findEntryInAnyScope(string($1))) 
				  yyerror("Undefined identifier");
				}
                     	;
N_ARITHLOGIC_EXPR	: N_UN_OP N_EXPR
				{
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
			if (! success) 
				yyerror("Multiply defined identifier");
			}
			;
N_LAMBDA_EXPR   : T_LAMBDA T_LPAREN N_ID_LIST T_RPAREN N_EXPR
			{
=			endScope();
			}
			;
N_ID_LIST       : /* epsilon */
			{
=			}
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

bool findEntryInAnyScope(const string theName) 
{
  if (scopeStack.empty( )) return(false);
  bool found = scopeStack.top().findEntry(theName);
  if (found)
    return(true);
  else 
  { // check in "next higher" scope
    SYMBOL_TABLE symbolTable = scopeStack.top( );
    scopeStack.pop( );
    found = findEntryInAnyScope(theName);
    scopeStack.push(symbolTable); // restore the stack
    return(found);
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
