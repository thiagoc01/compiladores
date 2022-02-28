%{

int linha = 1;
int ultimo_token = -1;
vector<string> gera_vetor_codigo(string codigo);
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

ASM	"asm"

DIGITO  [0-9]

LETRA   [A-Za-z_]

INT {DIGITO}+

ID	(({LETRA}({LETRA}|{DIGITO})*))

ID_FUNC	{ID}'('

FLOAT   {INT}(\.{INT}+)?([Ee](\+|\-)?{INT})?

STRING	('([^'\\\n]|\\'|\"|''|\\.)*')|(\"([^"\\\n]|\\\"|'|\\.|\"\")*\")

STRING2	`([^`\\]|\\`|\\.|\\)*`

BOOL	("true"|"false")

NLPOSS	({LET}|{VAR}|{CONST})

%%

<<EOF>>	{unput(EOF); if (ultimo_token != ';' && ultimo_token != -1) return ';';}

";"[\n \r\t;]*	{for (int i = 0 ; yytext[i] != 0 ; i++) if (yytext[i] == '\n') linha++; if (ultimo_token != ';') {ultimo_token = ';'; return ';';}}

"{"[\n \t\r;]*';'[\n \t\r;]*"}"	{for (int i = 0 ; yytext[i] != 0 ; i++) if (yytext[i] == '\n') linha++; }

"\n"/{WS}*({NLPOSS}){WS}*	{linha++;if (ultimo_token != ';'){ if (ultimo_token != -1) { ultimo_token = ';'; return ';';}}}

"\n"/{WS}*({ID}|{INT}|{FLOAT}|{STRING}|{STRING2}|"}"|"{"){WS}*	{linha++; if ((ultimo_token == tk_id || ultimo_token == tk_int || ultimo_token == tk_float || ultimo_token == tk_str || ultimo_token == tk_str2 || ultimo_token == tk_bool || ultimo_token == ')' || ultimo_token == ']' || ultimo_token == '}') && !em_objeto) {ultimo_token = ';';return ';'; } }

"{"/{WS}*{ID}{WS}*":"	{ return tk_abre_obj;}

"{"/{WS}*"}"{WS}+	{if (ultimo_token == ';' || ultimo_token == -1) return tk_bloco_vazio; else{ultimo_token = '{'; return '{';}}

"("/[^(]*")"{WS}*"=>"	{return parentese_args_anon;}

"}"/[^;}]	{ if(ultimo_token != ';' && ultimo_token != '{' && ultimo_token != -1 && !em_objeto) {unput('}');ultimo_token = ';'; return ';';} else return '}';}

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

{ASM}{WS}*.*"}"	{
			while (*yytext != '{')
			{
				if (*yytext == '\n')
					linha++;
				yytext++;
			}
			string trimada = yytext + 1;
			trimada = trimada.substr(0, trimada.size()-1);
		        yylval.c = gera_vetor_codigo( trimada );
		        return tk_ASM; 
		}

{INT}	{ultimo_token = tk_int; yylval.e = yytext; 
	  return tk_int; }

{FLOAT}	{ultimo_token = tk_float; yylval.e = yytext; 
	  return tk_float; }
	  
{BOOL}	{ultimo_token = tk_bool; yylval.e = yytext; return tk_bool;}

{STRING}	{ultimo_token = tk_str; yylval.e = yytext;  return tk_str; }

{STRING2}	{ultimo_token = tk_str2; yylval.e = yytext;  return tk_str2; }

{ID}	{ultimo_token = tk_id; yylval.e = yytext; return tk_id; }

"+="	{ultimo_token = tk_incremento; return tk_incremento;}

"!="	{ultimo_token = tk_diferente; return tk_diferente;}

"++"	{ultimo_token = tk_incremento_um ; return tk_incremento_um;}

"=="	{ultimo_token = tk_igual; return tk_igual;}

"=>"	{ultimo_token = tk_oper_seta; return tk_oper_seta;}

.	{if (yytext[0] == ';' || yytext[0] == ',')ultimo_token = *yytext; return *yytext; }

%%

vector<string> gera_vetor_codigo(string codigo)
{
	vector<string> ret;	
	string var;
	
	for (int i = 0 ; i < codigo.size() ; i++)
	{
		if (codigo[i] == '"')
		{
			var += "\"";
			
			for (int j = i + 1; j < codigo.size() ; j++)
			{
				if (codigo[j] == '"')
				{
					var += codigo[j];
					ret.push_back(var);
					var = "";
					i = j + 1;
					break;
				}
				else
					var += codigo[j];				
			}
		}
		
		else if (codigo[i] == '\'')
		{
			var += "'";
			for (int j = i + 1; j < codigo.size() ; j++)
			{
				if (codigo[j] == '\'')
				{
					var += codigo[j];
					ret.push_back(var);
					var = "";
					i = j + 1;
					break;
				}
				else
					var += codigo[j];				
			}
		}
		
		else if (codigo[i] == ' ')
		{
			ret.push_back(var);
			var = "";
		}
		
		else
			var += codigo[i];
	}
	
	
	if (codigo.size() > 0)
	    ret.push_back(var);
	
	return ret;
}
