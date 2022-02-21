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
  bool e_func;
  int num_args;
};

#define YYSTYPE Atributos

vector< map<string, Atributos> > escopos;
map<string, int> posicoes_labels_iniciais;
vector<string> codigo_funcoes;
map<string, bool> funcao_tem_retorno;
vector<int> inicio_funcao; // Guarda o começo de cada função para troca no label
vector<string> incremento;
int label_if = 1;
int label_else = 1;
int label_for = 1;
int label_while = 1;
int label_func = 1;
int escopo_funcao = 0;

int yylex();
int yyparse();
void yyerror(const char *);
void declara_variavel(string nome, int linha, string tipo_declarado);
void cria_escopo();
void deleta_escopo();
void checa_condicao_variavel(string nome, bool rvalue);
void print(string s);
vector<string> concatena_vetor(vector<string> v1, vector<string> v2);
void gera_codigo(vector<string> codigo);
string gera_label_inicial(string nome, int label);
string gera_label_final(string nome, int label);
vector<string> realiza_pos_incremento(int posicao, bool obj);
void resolve_enderecos(vector<string> &codigo, int tamanho_vetor_codigo);
string ultimo_obj;

extern int linha;
extern int ultimo_token;

string ultimo_tipo_declarado; // Referencial para declarações, em caso de haver várias seguidas na mesma linha

%}

%token tk_let tk_var tk_const tk_int tk_float tk_str tk_str2 tk_id tk_ponto tk_igual tk_incremento tk_incremento_um tk_diferente
%token tk_if tk_for tk_while tk_else tk_func tk_return	tk_bloco_vazio	tk_abre_obj
// Start indica o símbolo inicial da gramática
%start FIM

%%


FIM : S {$1.c.push_back("."); int tam_vetor_codigo = $1.c.size(); $1.c = concatena_vetor($1.c, codigo_funcoes); resolve_enderecos($1.c, tam_vetor_codigo); gera_codigo($1.c);};

S :  CMD S {$1.c = concatena_vetor($1.c, $2.c); $$ = $1; $1.c.clear();} 
	| CMD ;

CMD : declaracao_const';' {
				
				$$ = $1;
				$1.c.clear();
			}
	| declaracao ';'{
				$$ = $1;
				$1.c.clear();
			}
	| E  ';' { 
			$1.c.push_back("^"); 
			$$ = $1;
			$1.c.clear();
		}			
	| decl_func {$$ = $1; $1.c.clear();}
	| retorno_func {if (escopo_funcao) $$ = $1; else {cout << "Erro : chamada de retorno fora de uma função. " << endl; exit(1);} $1.c.clear();}
	| chamada_if {$$ = $1;  $1.c.clear();}
	| chamada_for {$$ = $1;  $1.c.clear();}
	| chamada_while {$$ = $1;  $1.c.clear();}
	| bloco {$$ = $1;  $1.c.clear();};
	
	
bloco : '{' ';' '}'
	| '{' {cria_escopo(); $1.c.push_back("<{"); } mult_CMD  '}' {$1.c = concatena_vetor($1.c, $3.c); $1.c.push_back("}>"); ultimo_token = -1; deleta_escopo(); $$ = $1; $1.c.clear(); $3.c.clear();}
	| tk_bloco_vazio '}' ;

mult_CMD : CMD mult_CMD {$1.c = concatena_vetor($1.c, $2.c); $$ = $1; $1.c.clear(); $2.c.clear();} 
		| CMD {$$ = $1; $1.c.clear();};

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

declaracao_const : tk_const {ultimo_tipo_declarado = "const";} decl_atrib multi_decl_const {$3.c = concatena_vetor($3.c, $4.c); $$ = $3; $3.c.clear(); $4.c.clear();};

multi_decl_const : ',' decl_atrib multi_decl_const {$2.c = concatena_vetor($2.c, $3.c); $$ = $2; $2.c.clear(); $3.c.clear();} 
			| /* Vazio */;
			
atribuicao : LVALUEPROP {checa_condicao_variavel($1.e, true); } '=' E {$1.c = concatena_vetor($1.c, $4.c); $1.c.push_back("[=]"); $$ = $1;  $1.c.clear(); $4.c.clear();}
			| LVALUE {checa_condicao_variavel($1.e, false);  ultimo_obj = $1.e;} '=' E  {$1.c = concatena_vetor($1.c, $4.c); if ($4.c[0] != "{}") $1.c.push_back("=");  $$ = $1;   $1.c.clear(); $4.c.clear();}
			| LVALUE {checa_condicao_variavel($1.e, false); $1.c.push_back($1.e); $1.c.push_back("@"); ultimo_obj = $1.e;} tk_incremento E {$1.c = concatena_vetor($1.c, $4.c); $1.c.push_back("+"); if ($4.c[0] != "{}") $1.c.push_back("=");  $$ = $1;  $1.c.clear(); $4.c.clear();}
			| LVALUEPROP { checa_condicao_variavel($1.e, true); $1.c = concatena_vetor($1.c, $1.c); $1.c.push_back("[@]");} tk_incremento E {$1.c = concatena_vetor($1.c, $4.c); $1.c.push_back("+"); $1.c.push_back("[=]");  $$ = $1;  $1.c.clear(); $4.c.clear();};

decl_atrib : LVALUE {declara_variavel($1.e, linha, ultimo_tipo_declarado); $1.c.push_back("&"); $1.c.push_back($1.e); ultimo_obj = $1.e;} '=' E {$1.c = concatena_vetor($1.c, $4.c); if ($4.c[0] != "{}") $1.c.push_back("="); $1.c.push_back("^"); $$ = $1;  $1.c.clear(); $4.c.clear();};
			
E : '!'E 	{
		$2.c.push_back("!");
		if (incremento.size())
		{
			for (int i = 0 ; i < incremento.size() ; i++)
			{
				if (incremento[i].find("[@]") != string::npos)
				{
					incremento[i] = incremento[i].substr(0, incremento[i].size() - 3);
					$1.c = concatena_vetor($1.c, realiza_pos_incremento(i, true));
				}
				else
					$1.c = concatena_vetor($1.c, realiza_pos_incremento(i, false));		
			}
		}
		$$ = $2;
		$2.c.clear();
		} 
	| F 
		{
			if (incremento.size())
			{
				for (int i = 0 ; i < incremento.size() ; i++)
				{
					if (incremento[i].find("[@]") != string::npos)
					{
						incremento[i] = incremento[i].substr(0, incremento[i].size() - 3);
						$1.c = concatena_vetor($1.c, realiza_pos_incremento(i, true));
					}
					else
						$1.c = concatena_vetor($1.c, realiza_pos_incremento(i, false));		
				}
			}
			
			$$ = $1;
			$1.c.clear();
		}
	 | atribuicao 	{
				if (incremento.size())
				{
					for (int i = 0 ; i < incremento.size() ; i++)
					{
						if (incremento[i].find("[@]") != string::npos)
						{
							incremento[i] = incremento[i].substr(0, incremento[i].size() - 3);
							$1.c = concatena_vetor($1.c, realiza_pos_incremento(i, true));
						}
						else
							$1.c = concatena_vetor($1.c, realiza_pos_incremento(i, false));		
					}
				}
				$$ = $1;
				$1.c.clear();
			};

F : F '|' '|' G {$1.c = concatena_vetor($1.c, $4.c); $1.c.push_back("||"); $$ = $1; $4.c.clear();} 
			| F '&''&' G {$1.c = concatena_vetor($1.c, $4.c); $1.c.push_back("&&"); $$ = $1; $4.c.clear();} 
			| G {$$ = $1; $1.c.clear();};

G : G '<' H {$1.c = concatena_vetor($1.c, $3.c); $1.c.push_back("<"); $$ = $1; $3.c.clear();} 
			| G '>' H {$1.c = concatena_vetor($1.c, $3.c); $1.c.push_back(">"); $$ = $1; $3.c.clear();} 
			| G '>''=' H {$1.c = concatena_vetor($1.c, $4.c); $1.c.push_back(">="); $$ = $1; $4.c.clear();} 
			| G '<''=' H {$1.c = concatena_vetor($1.c, $4.c); $1.c.push_back("<="); $$ = $1; $4.c.clear();} 
			| G tk_igual H {$1.c = concatena_vetor($1.c, $3.c); $1.c.push_back("=="); $$ = $1; $3.c.clear();} 
			| G tk_diferente H {$1.c = concatena_vetor($1.c, $3.c); $1.c.push_back("!="); $$ = $1; $3.c.clear();} 
			| H;

H : H '+' I {$1.c = concatena_vetor($1.c, $3.c); $1.c.push_back("+"); $$ = $1; $3.c.clear();} 
			| H '-' I {$1.c = concatena_vetor($1.c, $3.c); $1.c.push_back("-"); $$ = $1; $3.c.clear();}
			| I;

I : I '*' J {$1.c = concatena_vetor($1.c, $3.c); $1.c.push_back("*"); $$ = $1; $3.c.clear(); $1.c.clear();} 
			| I '/' J {$1.c = concatena_vetor($1.c, $3.c); $1.c.push_back("/"); $$ = $1; $3.c.clear(); $1.c.clear();} 
			| J ;

J : '+'K {$$ = $2;} 
			| '-'K { $1.c.push_back("0"); $1.c = concatena_vetor($1.c, $2.c); $1.c.push_back("-"); $$ = $1; } 
			| K ;

K : LVALUE {checa_condicao_variavel($1.e, true); $1.c.push_back("@");  $$ = $1;}
			| tk_int {$1.c.push_back($1.e);  $$ = $1; } 
			| tk_float {$1.c.push_back($1.e);  $$ = $1; } 
			| tk_str {$1.c.push_back($1.e); $$ = $1; } 
			| tk_str2 {$1.c.push_back($1.e); $$ = $1; } 
			| '('E')' {$$ = $2; } 
			| LVALUEPROP {checa_condicao_variavel($1.e, true); $1.c.push_back("[@]"); $$ = $1; }
			| Objetos {$$ = $1; $1.c.clear();}
			| chamada_funcao
			| LVALUE tk_incremento_um {checa_condicao_variavel($1.e, true); $1.c.push_back("@"); incremento.push_back($1.e); $$ = $1; }
			| LVALUEPROP tk_incremento_um 	{
								checa_condicao_variavel($1.e, true);
								$1.c.push_back("[@]");
								vector<string> pos = $1.c;
								string temp;
								
								for (int i = 0 ; i < pos.size() ; i++)
								{
									temp += pos[i];
									temp += " ";
								}
									
								incremento.push_back(temp);
								$$ = $1; 
							} ;

Objetos : '['']' {$2.c.push_back("[]"); $$ = $2;}
		| '{' '}' {ultimo_token = '}'; $1.c.push_back("{}"); $1.c.push_back("="); $$ = $1; $1.c.clear();}
		| tk_abre_obj args_dict '}' {$1.c.push_back("{}"); $1.c.push_back("="); $1.c = concatena_vetor($1.c, $2.c); $1.c.push_back(ultimo_obj); $1.c.push_back("@"); $$ = $1; $1.c.clear(); $2.c.clear();};
		
args_dict :	LVALUE ':' E mult_args_dict {$1.c = concatena_vetor($1.c, $3.c); $1.c.push_back("[=]"); $1.c.push_back("^"); $1.c = concatena_vetor($1.c, $4.c);  $$ = $1; $1.c.clear(); $4.c.clear();$3.c.clear();};

mult_args_dict :	',' LVALUE ':' E mult_args_dict {$1.c.push_back(ultimo_obj); $1.c.push_back("@"); $1.c = concatena_vetor($1.c, $2.c); $1.c = concatena_vetor($1.c, $4.c);  $1.c.push_back("[=]"); $1.c.push_back("^"); $1.c = concatena_vetor($1.c, $5.c);  $$ = $1; $1.c.clear(); $2.c.clear(); $4.c.clear(); $5.c.clear();} | /* Vazio */ ;
			
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

decl_func : tk_func LVALUE {
				declara_variavel($2.e, linha, "func");
				escopo_funcao++;
				cria_escopo();
				$1.c.push_back($2.e);
				$1.c.push_back("&");
				$1.c.push_back($2.e);
				$1.c.push_back("{}");
				$1.c.push_back("=");
				$1.c.push_back("'&funcao'");
				
				string label = ";";
				$1.c.push_back(label + "func" + "_" + to_string(label_func));
				$1.c.push_back("[=]");
				$1.c.push_back("^");
				
			} '(' func_args ')' {ultimo_token = -1;} '{' 
									
									{
										
										inicio_funcao.push_back(codigo_funcoes.size());
										int args = 0;
										
										for (string arg : $5.c)
										{										
											declara_variavel(arg, linha, "let");
											codigo_funcoes.push_back(arg);
											codigo_funcoes.push_back("&");
											codigo_funcoes.push_back(arg);
											codigo_funcoes.push_back("arguments");
											codigo_funcoes.push_back("@");
											codigo_funcoes.push_back(to_string(args));
											codigo_funcoes.push_back("[@]");
											codigo_funcoes.push_back("=");
											codigo_funcoes.push_back("^");
											args++;							
										}									
									}
									
									
									mult_CMD
									{
										codigo_funcoes = concatena_vetor(codigo_funcoes, $10.c);
									}						 	
									 
								'}'
								
								{										
									
									escopo_funcao--;
									deleta_escopo();
									$$ = $1;
									$1.c.clear();
									$2.c.clear();
									$5.c.clear();
									$10.c.clear();
								};

func_args : LVALUE mult_func_args {$1.c = concatena_vetor($1.c, $2.c); $$ = $1; $1.c.clear(); $2.c.clear();} | ;

mult_func_args : ',' LVALUE mult_func_args { $2.c = concatena_vetor($2.c, $3.c); $$ = $2; $2.c.clear(); $3.c.clear();} | /* Vazio */;

retorno_func : tk_return E';' {$2.c.push_back("'&retorno'"); $2.c.push_back("@"); $2.c.push_back("~"); $$ = $2; $2.c.clear();};

chamada_funcao : LVALUE'(' func_args_chamada ')' {$3.c.push_back(to_string($3.num_args)); $3.c.push_back($1.e); $3.c.push_back("@"); $3.c.push_back("$"); $$ = $3; $3.c.clear(); $3.num_args = 0;}
		| LVALUEPROP '(' func_args_chamada ')' {$3.c.push_back(to_string($3.num_args)); $3.c = concatena_vetor($3.c, $1.c); $3.c.push_back("[@]"); $3.c.push_back("$"); $$ = $3; $3.c.clear(); $3.num_args = 0;};

func_args_chamada : E {$1.num_args = 1;} mult_func_args_chamada {$1.num_args += $3.num_args; $1.c = concatena_vetor($1.c, $3.c); $$ = $1; $1.c.clear(); $3.c.clear(); $1.num_args = 0; $3.num_args = 0;} | {$$.num_args = 0;};

mult_func_args_chamada : ',' E {$2.num_args = 1;} mult_func_args_chamada {$2.num_args += $4.num_args; $2.c = concatena_vetor($2.c, $4.c); $$ = $2; $2.c.clear(); $4.c.clear(); $2.num_args = 0; $4.num_args = 0;} | {$$.num_args = 0;} /* Vazio */ ;

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
				$6.c.clear();
				$8.c.clear();
			};

chamada_else: tk_else {ultimo_token = -1;} CMD {$$ = $3; $3.c.clear();}
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
			$2.c.clear();
			$3.c.clear();
			$6.c.clear();
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
			$10.c.clear();
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

void checa_condicao_variavel(string nome, bool rvalue)
{
	map <string, Atributos> escopo;
	
	for (int i = escopos.size() - 1 ; i >= 0 ; i--)
	{
		escopo = escopos[i];
		
		if (escopo.count(nome) != 0)
		{
			Atributos a = escopo[nome];
			
			if (a.e_const && !escopo_funcao && !rvalue)
			{
				string erro = "Erro: tentativa de modificar uma variável constante ('";
			
				cout << erro + nome + "').\n";
				
				exit(1);
			}
			
			return;
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
		
		if (a.e_func)
		{
			string erro = "Erro : " + nome + " declarado previamente como uma função.";
			cout << erro << endl;
			exit(1);
		}
			
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
		atributos.e_func = false;
	}
	
	else if (tipo_declaracao == "var")
	{
		atributos.declarada_let = false;
		atributos.e_const = false;
		atributos.e_func = false;
	}
	
	else if (tipo_declaracao == "const")
	{
		atributos.declarada_let = true;
		atributos.e_const = true;
		atributos.e_func = false;
	}
	
	else if (tipo_declaracao == "func")
	{
		atributos.declarada_let = true;
		atributos.e_const = true;
		atributos.e_func = true;
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
	print(to_string(ultimo_token));
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

void resolve_enderecos(vector<string> &codigo, int tamanho_vetor_codigo)
{
	int funcoes_mapeadas = 0;
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
		
		else if (codigo[i][0] == ';')
			codigo[i] = to_string(tamanho_vetor_codigo + inicio_funcao[funcoes_mapeadas++]);
	}
	
}

vector<string> realiza_pos_incremento(int posicao, bool obj)
{
	vector<string> ret;
	
	if (obj)
	{
		string temp = incremento[posicao];

		int pos = 0;
		string var;
		
		while ((pos = temp.find(" ")) != string::npos) 
		{
		    var = temp.substr(0, pos);
		    ret.push_back(var);
		    temp.erase(0, pos + 1);
		}
		
		ret = concatena_vetor(ret, ret);
		ret.push_back("[@]");
		ret.push_back("1");
		ret.push_back("+");
		ret.push_back("[=]");
		ret.push_back("^");
		incremento.erase(incremento.begin() + posicao);
	}
	
	else
	{
		ret.push_back(incremento[posicao]);
		ret.push_back(incremento[posicao]); 
		ret.push_back("@");
		ret.push_back("1"); 
		ret.push_back("+");
		ret.push_back("="); 
		ret.push_back("^");
		incremento.erase(incremento.begin() + posicao);
	}
	
	return ret;
}
int main( int argc, char* argv[] ) {

	map <string, Atributos> global;
	escopos.push_back(global);
	
	yyparse();
	
	escopos.pop_back();
  return 0;
}
