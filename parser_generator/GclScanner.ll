%{
#include <cerrno>
#include <climits>
#include <cstdlib>
#include <cstdio>
#include <cstring>
#include <exception>
#include "GclParsingContext.hpp"
#include "GclParser.hpp"

// Work around an incompatibility in flex (at least versions
// 2.5.31 through 2.5.33): it generates code that does
// not conform to C89.  See Debian bug 333231
// <http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=333231>.
# undef yywrap
# define yywrap() 1

// The location of the current token.
static parser::Location loc;

void error(const parser::Location& l,
           const std::string& m)
{
    std::cout << l << m << std::endl;
    exit(1);
}

%}
%option noyywrap nounput batch debug noinput
IDENT [a-z][a-zA-Z_0-9]*
NUM   [+-]?[0-9]+
BLANK [ \t]

%{
#include "GclParsingContext.hpp"
using namespace program;
// Tell Flex the lexer's prototype ...
# define YY_DECL parser::GclParser::symbol_type yylex(parser::GclParsingContext &gcla)
// ... and declare it for the parser's sake.
YY_DECL;
%}

%{
  // Code run each time a pattern is matched.
# define YY_USER_ACTION  loc.columns (yyleng);
%}

%%

%{
  // Code run each time yylex is called.
  loc.step();
%}

"//".*       { loc.step(); }
{BLANK}+     { loc.step(); }
[\n]+        { loc.lines(yyleng); loc.step(); }
do           { return parser::GclParser::make_DO(loc); }
od           { return parser::GclParser::make_OD(loc); }
while        { return parser::GclParser::make_WHILE(loc); }
requires     { return parser::GclParser::make_REQUIRES(loc); }
ensures      { return parser::GclParser::make_ENSURES(loc); }
forall       { return parser::GclParser::make_FORALL(loc); }
exists       { return parser::GclParser::make_EXISTS(loc); }
record       { return parser::GclParser::make_RECORD(loc); }
null         { return parser::GclParser::make_NULL(loc); }
"("          { return parser::GclParser::make_LPAR(loc); }
")"          { return parser::GclParser::make_RPAR(loc); }
"["          { return parser::GclParser::make_LBRA(loc); }
"]"          { return parser::GclParser::make_RBRA(loc); }
"{"          { return parser::GclParser::make_LCUR(loc); }
"}"          { return parser::GclParser::make_RCUR(loc); }
";"          { return parser::GclParser::make_SCOL(loc); }
","          { return parser::GclParser::make_COMMA(loc); }
"."          { return parser::GclParser::make_DOT(loc); }
"="          { return parser::GclParser::make_ASSIGN(loc); }
"::"         { return parser::GclParser::make_COLS(loc); }
"->"         { return parser::GclParser::make_ARROW(loc); }
"!"          { return parser::GclParser::make_NOT(loc); }
"*"          { return parser::GclParser::make_MUL(loc); }
"/"          { return parser::GclParser::make_DIV(loc); }
"+"          { return parser::GclParser::make_PLUS(loc); }
"-"          { return parser::GclParser::make_MINUS(loc); }
">"          { return parser::GclParser::make_GT(loc); }
">="         { return parser::GclParser::make_GE(loc); }
"<"          { return parser::GclParser::make_LT(loc); }
"<="         { return parser::GclParser::make_LE(loc); }
"=="         { return parser::GclParser::make_EQ(loc); }
"!="         { return parser::GclParser::make_NEQ(loc); }
"|"          { return parser::GclParser::make_OR(loc); }
"&"          { return parser::GclParser::make_AND(loc); }
"==>"        { return parser::GclParser::make_IMP(loc); }
"true"       { return parser::GclParser::make_TRUE(loc); }
"false"      { return parser::GclParser::make_FALSE(loc); }
"int"|"bool" { return parser::GclParser::make_TYPE(yytext, loc); }
{IDENT}      { return parser::GclParser::make_ID(yytext, loc); }
{NUM}        {
  errno = 0;
  long n = strtol (yytext, NULL, 10);
  if (! (INT_MIN <= n && n <= INT_MAX && errno != ERANGE))
    error(loc, "integer out of range");
  return parser::GclParser::make_INTEGER(n, loc);
}
.            { error(loc, "invalid character");}
<<EOF>>      { return parser::GclParser::make_END(loc); }

%%

