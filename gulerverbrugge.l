/*    
      gulerverbrugge.l
	  created by Eli Verbrugge and Timur Guler

 	Specifications of tokens for the MFPL language.
 */

%{

%}

/*
 *	Definitions of regular expressions
*/

WSPACE		[ \t\r]+
NEWLINE          \n
LO_ALPHA		[a-z]
HI_ALPHA		[A-Z]
ALPHA			{LO_ALPHA}|{HI_ALPHA}
DIGIT            [0-9]
ALPHANUM		{ALPHA}|{DIGIT}
UNDERSCORE		_

IDENT			({UNDERSCORE}|{ALPHA})({ALPHANUM}|{UNDERSCORE})*

NEG_INTCONST	"-"[0-9]+
POS_INTCONST	("+")?[0-9]+
INTCONST        {NEG_INTCONST}|{POS_INTCONST}

DOUBLE_QUOTE      \"
STRCONST         {DOUBLE_QUOTE}[^\"\n]*{DOUBLE_QUOTE} 

COMMENT           ";".*$      
/*
 *	Tokens
*/
%%

"("			{
			return T_LPAREN;
			}
")"			{
			return T_RPAREN;
			}
"+"			{
			return T_ADD;
			}
"-"			{
			return T_SUB;
			}
"*"			{
			return T_MULT;
			}
"/"			{
			return T_DIV;
			}
">"			{
			return T_GT;
			}
">="		{
			return T_GE;
			}
"<"			{
			return T_LT;
			}
"<="		{
			return T_LE;
			}
"="			{
			return T_EQ;
			}
"/="		{
			return T_NE;
			}
"progn"		{
			return T_PROGN;
			}
"let*"		{
			beginScope();
			return T_LETSTAR;
			}
"if"		{
			return T_IF;
			}
"lambda"	{
			beginScope();
			return T_LAMBDA;
			}
"print"		{
			return T_PRINT;
			}
"input"		{
			return T_INPUT;
			}
"t"			{
			return T_T;
			}
"nil"		{
			return T_NIL;
			}
"and"		{
			return T_AND;
			}
"or"		{
			return T_OR;
			}
"not"		{
			return T_NOT;
			}
"exit"		{
			return T_EXIT;
			}
{INTCONST}	{
			return T_INTCONST;
			}
{STRCONST}	{
			return T_STRCONST;
			}
{IDENT}		{
			yylval.text = strdup(yytext);
			return T_IDENT;
			}
{WSPACE}		{ }
{NEWLINE}       {
                 lineNum++;
                }
{COMMENT}		{ }
.			{
			       yytext);
			return T_UNKNOWN;
			}

%%



