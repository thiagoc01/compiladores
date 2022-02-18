%{

int linha = 1;
int ultimo_token = -2;

%}

WS	[ \t\n]

PONTO	"."

LET	"let"

VAR	"var"

CONST	"const"

IF	"if"

FOR	"for"

WHILE	"while"

ELSE	"else"

FUNCTION "function"

RETURN	"return"

DIGITO  [0-9]

LETRA   [A-Za-z_]

INT {DIGITO}+

ID	(({LETRA}({LETRA}|{DIGITO})*))

FLOAT   {INT}(\.{INT}+)?([Ee](\+|\-)?{INT})?

STRING	('([^'\\\n]|\\'|\"|''|\\.)*')|(\"([^"\\\n]|\\\"|'|\\.|\"\")*\")

STRING2	`([^`\\]|\\`|\\.|\\)*`

NLPOSS	({LET}|{VAR}|{CONST})

%%

<<EOF>>	{unput(EOF); if (ultimo_token != ';' && ultimo_token != -1) return ';';}

";"[\n \r\t;]*	{for (int i = 0 ; yytext[i] != 0 ; i++) if (yytext[i] == '\n') linha++; if (ultimo_token != ';') {ultimo_token = ';'; return ';';}}

"{"[\n \t\r;]*';'[\n \t\r;]*"}"	{for (int i = 0 ; yytext[i] != 0 ; i++) if (yytext[i] == '\n') linha++; ultimo_token = ';'; return ';';}

"\n"$	{linha++; if (ultimo_token != ';'){ ultimo_token = ';'; return ';';}}

"\n"/{WS}*({NLPOSS}){WS}*	{linha++; if (ultimo_token != ';'){ if (ultimo_token != -1) { ultimo_token = ';'; return ';';}}}

"\n"/{WS}*({ID}|{INT}|{FLOAT}|{STRING}|{STRING2}|"}"|"{"){WS}*	{linha++; if (ultimo_token == tk_id || ultimo_token == tk_int || ultimo_token == tk_float || ultimo_token == tk_str || ultimo_token == tk_str2 || ultimo_token == ')' || ultimo_token == ']' || ultimo_token == '}') {ultimo_token = ';';return ';'; }}

{WS}    {if (*yytext == '\n') linha++; }

{PONTO} {ultimo_token = tk_ponto; return tk_ponto;}

{LET}	{yylval.e = "&"; return tk_let;}

{VAR}	{yylval.e = "&"; return tk_var;}

{CONST}	{yylval.e = "&"; return tk_const;}

{IF}	{ultimo_token = tk_if; return tk_if;}

{ELSE}	{ultimo_token = tk_else; return tk_else;}

{FOR}	{ultimo_token = tk_for; return tk_for;}

{WHILE}	{ultimo_token = tk_while; return tk_while;}

{FUNCTION}	{ultimo_token = tk_func; return tk_func;}

{RETURN}	{ultimo_token = tk_return; return tk_return;}

{INT}	{ultimo_token = tk_int; yylval.e = yytext; 
	  return tk_int; }

{FLOAT}	{ultimo_token = tk_float; yylval.e = yytext; 
	  return tk_float; }

{STRING}	{ultimo_token = tk_str; yylval.e = yytext;  return tk_str; }

{STRING2}	{ultimo_token = tk_str2; yylval.e = yytext;  return tk_str2; }

{ID}	{ultimo_token = tk_id; yylval.e = yytext; return tk_id; }

"+="	{ultimo_token = tk_incremento; return tk_incremento;}

"!="	{ultimo_token = tk_diferente; return tk_diferente;}

"++"	{ultimo_token = tk_incremento_um ; return tk_incremento_um;}

"=="	{ultimo_token = tk_igual; return tk_igual;}

.	{if (yytext[0] == ';')ultimo_token = *yytext; return *yytext; }

%%
