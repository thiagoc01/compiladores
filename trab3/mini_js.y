%{
#include <string>
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <map>
#include <vector>
extern "C" int yylex(void);

using namespace std;

struct Atributos {
  vector<string> c; // Código gerado
  string e;
  int linha;
  bool declarada_let;
  bool e_const;
  bool incremento;
};

#define YYSTYPE Atributos

vector< map<string, Atributos> > escopos;
map<string, int> posicoes_labels_iniciais;
int label_if = 1;
int label_else = 1;
int label_for = 1;
int label_while = 1;

int yylex();
int yyparse();
void yyerror(const char *);
void declara_variavel(string nome, int linha, string tipo_declarado);
void cria_escopo();
void deleta_escopo();
void checa_condicao_variavel(string nome);
void print(string s);
vector<string> concatena_vetor(vector<string> v1, vector<string> v2);
void gera_codigo(vector<string> codigo);
string gera_label_inicial(string nome, int label);
string gera_label_final(string nome, int label);
void resolve_enderecos(vector<string> &codigo);

extern int linha;
extern int ultimo_token;

string ultimo_tipo_declarado; // Referencial para declarações, em caso de haver várias seguidas na mesma linha

%}

%token tk_let tk_var tk_const tk_int tk_float tk_str tk_str2 tk_id tk_ponto tk_igual tk_incremento tk_incremento_um tk_diferente
%token tk_if tk_for tk_while tk_else tk_func
// Start indica o símbolo inicial da gramática
%start FIM

%%


FIM : S {$1.c.push_back("."); resolve_enderecos($1.c); gera_codigo($1.c);};

S :  CMD S {$1.c = concatena_vetor($1.c, $2.c); $$ = $1; } 
	| CMD ;

CMD : declaracao_const';' {$$ = $1;  $1.c.clear();}
	| declaracao ';' { $$ = $1; $1.c.clear();}
	| E  ';' {$1.c.push_back("^");  $$ = $1; $1.c.clear();}
	| chamada_if {$$ = $1;  $1.c.clear();}
	| chamada_for {$$ = $1;  $1.c.clear();}
	| chamada_while {$$ = $1;  $1.c.clear();}
	| bloco {$$ = $1;  $1.c.clear();};
	
	
bloco : '{' ';' '}'
	| '{' {cria_escopo();} mult_CMD  '}' {ultimo_token = -1; deleta_escopo(); $$ = $3; $3.c.clear();}
	| bloco_vazio;

mult_CMD : CMD mult_CMD {$1.c = concatena_vetor($1.c, $2.c); $$ = $1; $1.c.clear(); $2.c.clear();} 
		| CMD ;

LVALUE : tk_id {$1.c.push_back($1.e); $$ = $1; };

LVALUEPROP : LVALUEPROP {$1.c.push_back("[@]"); } '[' E ']' {$1.c = concatena_vetor($1.c, $4.c); $$ = $1;  $1.c.clear();} 
		| LVALUEPROP {$1.c.push_back("[@]"); } tk_ponto LVALUE {$1.c = concatena_vetor($1.c, $4.c); $$ = $1;  $1.c.clear();} 
		| LVALUE {$1.c.push_back("@");} tk_ponto LVALUE {$1.c.push_back($4.e); $1.c = concatena_vetor($1.c, $3.c); $$ = $1;  $1.c.clear();} 
		| LVALUE {$1.c.push_back("@");} '[' E ']' {$1.c = concatena_vetor($1.c, $4.c); $$ = $1; $1.c.clear();};

Tipo : tk_let {ultimo_tipo_declarado = "let"; } 
	| tk_var {ultimo_tipo_declarado = "var"; };

declaracao : Tipo LVALUE {declara_variavel($2.e, linha, ultimo_tipo_declarado);  $2.c.push_back("&"); } multi_decl {$2.c = concatena_vetor($2.c, $4.c); $$ = $2;  $2.c.clear(); $4.c.clear();} 
			| Tipo decl_atrib multi_decl {$2.c = concatena_vetor($2.c, $3.c); $$ = $2;   $2.c.clear(); $3.c.clear();} ;

multi_decl : ',' decl_atrib multi_decl {$2.c = concatena_vetor($2.c, $3.c); $$ = $2;  $2.c.clear(); $3.c.clear();} 
			| ',' LVALUE {declara_variavel($2.e, linha, ultimo_tipo_declarado); $2.c.push_back("&");} multi_decl {$2.c = concatena_vetor($2.c, $4.c); $$ = $2; $2.c.clear();  $4.c.clear(); } 
			| /* Vazio */;

declaracao_const : tk_const {ultimo_tipo_declarado = "const";} decl_atrib {declara_variavel($2.e, linha, "const");} multi_decl_const {$3.c = concatena_vetor($3.c, $5.c); $$ = $3; $5.c.clear();};

multi_decl_const : ',' decl_atrib multi_decl_const {$2.c = concatena_vetor($2.c, $3.c); $$ = $2;  $3.c.clear();} 
			| /* Vazio */;
			
atribuicao : LVALUEPROP {checa_condicao_variavel($1.e); } '=' E {$1.c = concatena_vetor($1.c, $4.c); $1.c.push_back("[=]");  $$ = $1;  $1.c.clear(); $4.c.clear();}
			| LVALUE {checa_condicao_variavel($1.e);  } '=' E  {$1.c = concatena_vetor($1.c, $4.c); $1.c.push_back("=");  $$ = $1;   $1.c.clear(); $4.c.clear();}
			| LVALUE {checa_condicao_variavel($1.e); $1.c.push_back($1.e); $1.c.push_back("@"); } tk_incremento E {$1.c = concatena_vetor($1.c, $4.c); $1.c.push_back("+"); $1.c.push_back("=");  $$ = $1;  $1.c.clear(); $4.c.clear();}
			| LVALUEPROP { checa_condicao_variavel($1.e); $1.c = concatena_vetor($1.c, $1.c); $1.c.push_back("[@]");} tk_incremento E {$1.c = concatena_vetor($1.c, $4.c); $1.c.push_back("+"); $1.c.push_back("[=]");  $$ = $1;  $1.c.clear(); $4.c.clear();};

decl_atrib : LVALUE {declara_variavel($1.e, linha, ultimo_tipo_declarado); $1.c.push_back("&"); $1.c.push_back($1.e);} '=' E {$1.c = concatena_vetor($1.c, $4.c); $1.c.push_back("="); $1.c.push_back("^"); $$ = $1;  $1.c.clear(); $4.c.clear();};
			
E : '!'E {$2.c.push_back("!"); $$ = $2; $2.c.clear();} 
	| 	F 
		{
			if ($1.incremento == true)
			{
				$1.c.push_back($1.e);
				$1.c.push_back($1.e); 
				$1.c.push_back("@");
				$1.c.push_back("1"); 
				$1.c.push_back("+");
				$1.c.push_back("="); 
				$1.c.push_back("^");
				$$ = $1;
			}
			else
			{
				$$ = $1;
			}
			$1.c.clear();
		} | atribuicao {$$ = $1; $1.c.clear();};

F : F '|' '|' G {$1.c = concatena_vetor($1.c, $4.c); $1.c.push_back("||"); $$ = $1;} 
			| F '&''&' G {$1.c = concatena_vetor($1.c, $4.c); $1.c.push_back("&&"); $$ = $1;} 
			| G ;

G : G '<' H {$1.c = concatena_vetor($1.c, $3.c); $1.c.push_back("<"); $$ = $1;} 
			| G '>' H {$1.c = concatena_vetor($1.c, $3.c); $1.c.push_back(">"); $$ = $1;} 
			| G '>''=' H {$1.c = concatena_vetor($1.c, $4.c); $1.c.push_back(">="); $$ = $1;} 
			| G '<''=' H {$1.c = concatena_vetor($1.c, $4.c); $1.c.push_back("<="); $$ = $1;} 
			| G tk_igual H {$1.c = concatena_vetor($1.c, $3.c); $1.c.push_back("=="); $$ = $1;} 
			| G tk_diferente H {$1.c = concatena_vetor($1.c, $3.c); $1.c.push_back("!="); $$ = $1;} 
			| H;

H : H '+' I {$1.c = concatena_vetor($1.c, $3.c); $1.c.push_back("+"); $$ = $1; } 
			| H '-' I {$1.c = concatena_vetor($1.c, $3.c); $1.c.push_back("-"); $$ = $1;}
			| I;

I : I '*' J {$1.c = concatena_vetor($1.c, $3.c); $1.c.push_back("*"); $$ = $1;} 
			| I '/' J {$1.c = concatena_vetor($1.c, $3.c); $1.c.push_back("/"); $$ = $1;} 
			| J ;

J : '+'K {$$ = $2;} 
			| '-'K { $1.c.push_back("0"); $1.c = concatena_vetor($1.c, $2.c); $1.c.push_back("-"); $$ = $1; } 
			| K ;

K : LVALUE {checa_condicao_variavel($1.e); $1.c.push_back("@"); $1.incremento = false; $$ = $1; }
			| tk_int {$1.c.push_back($1.e); $1.incremento = false; $$ = $1; } 
			| tk_float {$1.c.push_back($1.e); $1.incremento = false; $$ = $1; } 
			| tk_str {$1.c.push_back($1.e); $1.incremento = false; $$ = $1; } 
			| tk_str2 {$1.c.push_back($1.e); $1.incremento = false; $$ = $1; } 
			| '('E')' {$$ = $2; } 
			| LVALUEPROP {checa_condicao_variavel($1.e); $1.c.push_back("[@]"); $1.incremento = false; $$ = $1; }
			| LVALUE tk_incremento_um {checa_condicao_variavel($1.e); $1.c.push_back("@"); $1.incremento = true; $$ = $1; }
			| Objetos {$$ = $1; };
			
bloco_vazio : '{' '}';

Objetos : '['']' {$2.c.push_back("[]"); $$ = $2;}
			| bloco_vazio {$1.c.push_back("{}"); $$ = $1; };
			
/*

Para ser implementado quando solicitado

args_vetor : E mult_args_vetor {} 
			| ;
mult_args_vetor : ',' E mult_args_vetor {}
			| ;


args_dict : LVALUE ':' RVALUE_dict mult_args_dict 
			| ;

mult_args_dict : ',' LVALUE ':' RVALUE_dict mult_args_dict 
			| ;

RVALUE_dict : LVALUEPROP '=' multi_atrib_dict 
			| LVALUE '=' multi_atrib_dict 
			| LVALUE tk_incremento multi_atrib_dict 
			| LVALUEPROP tk_incremento multi_atrib_dict 
			| E;

multi_atrib_dict : LVALUEPROP '=' multi_atrib_dict 
			| LVALUE '=' multi_atrib_dict 
			| LVALUE tk_incremento multi_atrib_dict 
			| LVALUEPROP tk_incremento multi_atrib_dict 
			| E;
*/

chamada_if:  tk_if '(' E ')' 
			{
				ultimo_token = -1; 
				$3.c.push_back("!");
				/* Marca o início do if. Coloca no map de posicões iniciais para que, ao chegar no fim do if, possamos colocar o offset na posição. */
				$3.c.push_back(gera_label_inicial("if", label_if));
				posicoes_labels_iniciais.insert({$3.c[$3.c.size() - 1],$3.c.size() - 1});
				
				$3.c.push_back("?");			
			}
						
			CMD
			
			{
				$3.c = concatena_vetor($3.c, $6.c);
				
				/* Mesmo raciocínio do if descrito anteriormente. */
				$3.c.push_back(gera_label_inicial("else", label_else));
				posicoes_labels_iniciais.insert({$3.c[$3.c.size() - 1],$3.c.size() - 1});
				$3.c.push_back("#");
				
				
				string para_encontrar = gera_label_final("if", label_if-1); // String para encontrar no map o label inicial desse if.
				map<string,int>::iterator i = posicoes_labels_iniciais.find(para_encontrar);
				$3.c[i->second] = para_encontrar + "+" + to_string(1 + $6.c.size() + 3); // Pula a ?, o tamanho do CMD do if atual, o label do else e o # 
				posicoes_labels_iniciais.erase(i);
				
			}
						
			chamada_else
			
			{				
				$3.c = concatena_vetor($3.c, $8.c);
				
				/* Mesmo raciocínio do if descrito anteriormente. */
				string para_encontrar = gera_label_final("else", label_else-1);				
				map<string,int>::iterator i = posicoes_labels_iniciais.find(para_encontrar);
				$3.c[i->second] = para_encontrar + "+" + to_string(1 + $8.c.size() + 1); // Pula o # e o tamanho do CMD do else
				posicoes_labels_iniciais.erase(i);
				
				$$ = $3;
				$3.c.clear();
			};

chamada_else: tk_else {ultimo_token = -1;} CMD {$$ = $3;}
			| ;

chamada_while:	tk_while '(' E ')' 
		{
			/* Marca o começo do while, ou seja, onde começa a expressão condicional. */
			
			string para_encontrar = gera_label_inicial("while", label_while);
			
			$2.c = concatena_vetor($2.c, $3.c);
			ultimo_token = -1;
			$2.c.push_back("!");
			
			/* Mesmo raciocínio de um if comum. */
			$2.c.push_back(gera_label_inicial("if", label_if));
			posicoes_labels_iniciais.insert({$2.c[$2.c.size() - 1],$2.c.size() - 1});
			$2.c.push_back("?");			
		}
		CMD
		{
			$2.c = concatena_vetor($2.c, $6.c);
			
			/* Chegando no fim de um while, basta colocarmos como offset o tamanho do comando acrescido do tamanho da expressão condicional. */
			string para_encontrar = gera_label_final("while", label_while-1);			
			$2.c.push_back(para_encontrar + "-" + to_string($2.c.size()));
			
			$2.c.push_back("#");
			
			/* Mesmo raciocínio de um if. */
			para_encontrar = gera_label_final("if", label_if-1);
			map<string,int>::iterator i = posicoes_labels_iniciais.find(para_encontrar);
			$2.c[i->second] = para_encontrar + "+" + to_string(1 + $6.c.size() + 3); // Pula a ?, o tamanho do CMD do while atual e o goto de repetição
			
			posicoes_labels_iniciais.erase(i);
			
			$$ = $2;
			$3.c.clear();
		}
		
		
		;

chamada_for :	tk_for '(' for_decl_ou_atrib ';' E ';' for_incr_ou_nao ')'
		{
			/* Marca o começo do for, ou seja, onde termina a declaração e começa a expressão condicional. */
			string para_encontrar = gera_label_inicial("for", label_for);
			posicoes_labels_iniciais.insert({para_encontrar, $3.c.size() - 1});
			
			$3.c = concatena_vetor($3.c, $5.c);
			ultimo_token = -1;
			$3.c.push_back("!");
			
			/* Mesmo raciocínio de um if. */
			$3.c.push_back(gera_label_inicial("if", label_if));
			posicoes_labels_iniciais.insert({$3.c[$3.c.size() - 1],$3.c.size() - 1});
			
			$3.c.push_back("?");		
		}
		
		CMD
		
		{
			$3.c = concatena_vetor($3.c, $10.c);
			$3.c = concatena_vetor($3.c, $7.c);
			string para_encontrar = gera_label_final("for", label_for-1);
			/* Diferente do while, antes da expressão há a declaração ou atribuição. Então, não podemos ir para a posição 0 do vetor. */
			
			map<string,int>::iterator i = posicoes_labels_iniciais.find(para_encontrar);
			$3.c.push_back(para_encontrar + "-" + to_string($3.c.size() - 1 - i->second));
			posicoes_labels_iniciais.erase(i);
			
			$3.c.push_back("#");
			
			/* Mesmo raciocínio de um if, mas agora pulamos o comando e o incremento. */
			
			para_encontrar = gera_label_final("if", label_if-1);
			i = posicoes_labels_iniciais.find(para_encontrar);
			$3.c[i->second] = para_encontrar + "+" + to_string(1 + $7.c.size() + $10.c.size() + 3); // Pula a ?, o tamanho do CMD do for atual, o tamanho da atribuicao e o goto de repetição

			posicoes_labels_iniciais.erase(i);
			
			$$ = $3;
			$3.c.clear();
			$5.c.clear();
			$7.c.clear();
		};

for_decl_ou_atrib : declaracao 
			| atribuicao {$1.c.push_back("^"); $$ = $1;}
			| /* Vazio */;

for_incr_ou_nao : atribuicao {$1.c.push_back("^"); $$ = $1;}
			| /* Vazio */;
%%

#include "lex.yy.c"

void cria_escopo()
{
	map<string,Atributos> novo;
	
	escopos.push_back(novo);
}

void deleta_escopo()
{
	escopos.pop_back();
}

void checa_condicao_variavel(string nome)
{
	map <string, Atributos> escopo;
	
	for (int i = escopos.size() - 1 ; i >= 0 ; i--)
	{
		escopo = escopos[i];
		
		if (escopo.count(nome) != 0)
		{
			Atributos a = escopo[nome];
			
			if (a.e_const)
			{
				string erro = "Erro: tentativa de modificar uma variável constante ('";
			
				cout << erro + nome + "').\n";
				
				exit(1);
			}
		}
	}
	
	if (escopo.count(nome) == 0)
	{
		string erro = "Erro: a variável '";
			
		cout << erro + nome + "' não foi declarada.\n";
		
		exit(1);
	}
	
	
	
}

void declara_variavel(string nome, int linha, string tipo_declaracao)
{
	map <string,Atributos> *ultimo_escopo = &escopos.back();
	
	if (ultimo_escopo->count(nome) != 0)
	{
		Atributos a = (*ultimo_escopo)[nome];
			
		if (a.declarada_let)
		{
			string erro = "Erro: a variável '";
			cout << erro + a.e + "' já foi declarada na linha " + to_string(a.linha) + ".\n";
			exit(1);	
		}
		
		ultimo_escopo->erase(nome);				
	}
	
	Atributos atributos;
	
	atributos.e = nome;
	atributos.linha = linha;
	if (tipo_declaracao == "let")
	{					
		atributos.declarada_let = true;
		atributos.e_const = false;
	}
	
	else if (tipo_declaracao == "var")
	{
		atributos.declarada_let = false;
		atributos.e_const = false;
	}
	
	else if (tipo_declaracao == "const")
	{
		atributos.declarada_let = true;
		atributos.e_const = true;
	}
	
	ultimo_escopo->insert({nome, atributos});
}

string gera_label_inicial(string nome, int label)
{
	if (nome == "if")
		label_if++;
	else if (nome == "else")
		label_else++;
	else if (nome == "while")
		label_while++;
	else if (nome == "for")
		label_for++;
		
	string ret =  "%";
	return ret + nome + "_" + to_string(label);
}

string gera_label_final(string nome, int label)
{
	if (nome == "if")
		label_if--;
	else if (nome == "else")
		label_else--;
	else if (nome == "while")
		label_while--;
	else if (nome == "for")
		label_for--;
		
	string ret = "%";
	return ret + nome + "_" + to_string(label);
}

void print(string s)
{
	cout << s << " ";
}

void yyerror( const char* st ) {
	puts( st ); 
	printf( "Proximo a: %s\n Linha:%d\n", yytext, linha );
	exit( 0 );
}

void gera_codigo(vector<string> codigo)
{
	for (string s : codigo)
		print(s);
}

vector<string> concatena_vetor(vector<string> v1, vector<string> v2)
{
	vector<string> temp = v1;
	
	temp.insert( temp.end(), v2.begin(), v2.end() );
	
	return temp;
}

void resolve_enderecos(vector<string> &codigo)
{
	for (int i = 0 ; i < codigo.size() ; i++)
	{
		if (codigo[i][0] == '%')
		{
			if (codigo[i][1] == 'f' || codigo[i][1] == 'w')
			{
				int offset = stoi(codigo[i].substr(codigo[i].find("-") + 1)); 
				codigo[i] = to_string(i - offset);				
			}
			
			else
			{
				int offset = stoi(codigo[i].substr(codigo[i].find("+")));
				codigo[i] = to_string(i + offset);
			}
		}
	}
	
}

int main( int argc, char* argv[] ) {

	map <string, Atributos> global;
	escopos.push_back(global);
	
	yyparse();
	
	escopos.pop_back();
  return 0;
}
