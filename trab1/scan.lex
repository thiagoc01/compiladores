/* Coloque aqui definições regulares */

WS	[ \t\n]

DIGITO  [0-9]

LETRA   [A-Za-z_]

INT {DIGITO}*

FLOAT   {INT}(\.{INT}+)?([Ee](\+|\-)?{INT})?

FOR	(?i:for)

IF	(?i:if)

MAIG	>=

MEIG	<=

IG	==

DIF	!=

/* O comentário iniciado por // segue o padrão do C. Ele captura tudo que não seja uma quebra de * linha. O comentário iniciado por / * deve ser finalizado por * /. Nesse intervalo, basta pegar qualquer coisa que não seja *. Ao encontrar o *, devemos verificar se ele não está próximo do delimitador final, ou seja, /. Nesse caso, se quisermos escrever astericos concatenados com o * final de delimitação, basta aproveitar o final do padrão colocando um + */

COMENTARIO	(\/\*([^*]|\*+[^*\/])*\*+\/)|(\/\/[^\n]*)

/* Nessa string, há duas possibilidades: começar com ' ou ". E isso é representado no OU
mais externo. Em ambas as aspas, não podemos encontrar a quebra de linha nem a aspa que
começou a cadeia. Podemos encontrar qualquer outra coisa escapada ou não e a respectiva
aspa escapada. */

STRING	('([^'\\\n]|\\'|\"|''|\\.)*')|(\"([^"\\\n]|\\\"|'|\\.|\"\")*\")

/* Nessa string, o comportamento é mais livre. Precisamos apenas garantir que ela é lida para
qualquer coisa, exceto ` e \, e a cadeia é mantida com a quebra de linha. */

STRING2	`([^`\\]|\\`|\\.|\\)*`

/* Como há a opção de iniciar um token com $, precisamos adicionar a possibilidade dessa regra de iniciar com $ e prosseguir com letras */

ID	((\${LETRA}*)|({LETRA}({LETRA}|{DIGITO})*))



%%
    /* Padrões e ações. Nesta seção, comentários devem ter um tab antes */

{WS}	{ /* ignora espaços, tabs e '\n' */ }

{INT}	{ return _INT; }

{FLOAT}	{ return _FLOAT; }

{FOR}	{ return _FOR; }

{IF}	{ return _IF; }

{MAIG}	{ return _MAIG; }

{MEIG}	{ return _MEIG; }

{IG}	{ return _IG; }

{DIF}	{ return _DIF; }

{COMENTARIO}	{ return _COMENTARIO; }

{STRING}	{ return _STRING; }

{STRING2}	{ return _STRING2; }

{ID}	{ return _ID; }

.	{ return *yytext; 
          /* Essa deve ser a última regra. Dessa forma qualquer caractere isolado será retornado pelo seu código ascii. */ }

%%

/* Não coloque nada aqui - a função main é automaticamente incluída na hora de avaliar e dar a nota. */
