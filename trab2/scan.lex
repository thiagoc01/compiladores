%{
#include <iostream>
#include <map>
#include <algorithm>
  
using namespace std; 

int token;
void S();
void A();
void B();
void C();
void D();
void F();
void E();
void P();
void G();
void I();
void J();
void H();
void K();
void L();
void M();
void N();
void O();


void casa( int esperado);

enum { tk_cte_int = 256, tk_cte_float, tk_id, tk_id_funcao, 
        tk_print, tk_str, tk_str2 };

%}


/* Coloque aqui definições regulares */

WS	[ \t\n]

DIGITO  [0-9]

LETRA   [A-Za-z_]

INT {DIGITO}*

FLOAT   {INT}(\.{INT}+)?([Ee](\+|\-)?{INT})?

STRING	('([^'\\\n]|\\'|\"|''|\\.)*')|(\"([^"\\\n]|\\\"|'|\\.|\"\")*\")

STRING2	`([^`\\]|\\`|\\.|\\)*`

ID	((\${LETRA}*)|({LETRA}({LETRA}|{DIGITO})*))

ID_PRINT    "print"

ID_FUNCAO   {LETRA}[a-zA-Z_0-9]*\(


%%
    /* Padrões e ações. Nesta seção, comentários devem ter um tab antes */

{WS}    {}

{INT}	{ return tk_cte_int; }

{FLOAT}	{ return tk_cte_float; }

{STRING}	{ return tk_str; }

{STRING2}	{ return tk_str2; }

{ID_PRINT} { return tk_print; }

{ID_FUNCAO} { return tk_id_funcao; }

{ID}	{ return tk_id; }

.	{ return *yytext; }

%%

auto p = (void *) (&yyunput);

void erro( string msg ) {
  cout << "\n*** Erro: ***" << endl << msg << "\n";
  exit( 1 );
}

void print(string s)
{
    cout << s << " ";
}

int next_token()
{
    return yylex();
}

void A()
{
    switch (token)
    {
        case tk_id:
        {
            string temp = yytext;
            casa(tk_id);
            print(temp);
            casa ('=');
            B();
            print("=");
            casa(';');
        }

        break;

        case tk_id_funcao:
            H();
            casa(';');
            break;

        case tk_print:
            P();
            casa(';');
            break;
    }
    
}

void B()
{
    C();
    K();
}

void C()
{
    D();
    L();
}

void D()
{
    
    switch (token)
    {
        case '+':
            casa('+');
            O();
            break;

        case '-':
            print("0");
            casa('-');
            O();
            print("-");
            break;

        default:
            E();
            M();
    }
}

void F()
{
    string temp = yytext;

    switch (token)
    {
        case tk_id:
            casa(tk_id);
            print(temp + " @");
            break;

        case tk_cte_float:
            casa(tk_cte_float);
            print(temp);
            break;

        case tk_cte_int:
            casa(tk_cte_int);
            print(temp);
            break;

        case tk_str:
            casa(tk_str);
            print(temp);
            break;

        case tk_str2:
            casa(tk_str2);
            print(temp);
            break;

        case '(':
            casa('(');
            B();
            casa(')');
            break;

        default:
        {   
            string errado = yytext;
            erro("Esperado inteiro, flutuante ou (. Encontrado " + errado);
        }
    }
}

void E()
{
    G();
    N();  
}

void P()
{
    if (token == tk_print)
    {
        casa(tk_print);
        B();
        print("print #");
    }

    else
    {   
        string errado = yytext;
        erro("Esperado identificador, comando print ou chamada de função. Encontrado: " + errado);
    }
}

void G()
{
    switch (token)
    {
        case tk_id_funcao:
            H();
            break;

        case tk_id:
        case tk_cte_float:
        case tk_cte_int:
        case tk_str:
        case tk_str2:
        case '(':
            F();
            break;

        default:
        {
            string errado = yytext;
            erro("Esperada chamada de função, constante ou expressão. Encontrado: " + errado);
        }


    }  
}

void I()
{
    if (token != ')')
    {
        B();
        J();
    }
}


void J()
{
    if (token == ',')
    {
        casa(',');
        B();
        J();
    }
}

void H()
{
    string temp = yytext;
    casa (tk_id_funcao);    
    temp.erase(remove(temp.begin(), temp.end(), '('), temp.end());    
    I();
    casa(')');
    print(temp + " #");
}

void K()
{
    switch (token)
    {
        case '+':
            casa('+');
            C();
            print("+");
            K();
            break;

        case '-':
            casa('-');
            C();
            print("-");
            K();
            break;

    }
}

void L()
{
    switch (token)
    {
        case '*':
            casa('*');
            D();
            print("*");
            L();
            break;

        case '/':
            casa('/');
            D();
            print("/");
            L();
            break;

    }
}

void M()
{
    if (token == '^')
    {
        casa('^');
        E();
        M();
        print("^");
    }
}

void N()
{
    if (token == '!')
    {
        casa('!');
        print("fat #");
        N();        
    }
}

void O()
{
    switch (token)
    {
        case tk_id_funcao:
        case tk_id:
        case tk_cte_float:
        case tk_cte_int:
        case tk_str:
        case tk_str2:
        case '(':
        case '+':
        case '-':
            D();
            break;
    }
}
void casa( int esperado ) {
  if( token == esperado ){
    token = next_token();
  }

  else
  {
        printf("\nEsperado: %c \t Encontrado: %c", esperado, token);
        exit(1);
  }
}

void S()
{
    while (token != 0)
        A();
}

int main()
{
    token = next_token();

    S();

    return 0;
}


