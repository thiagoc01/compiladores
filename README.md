
# Compiladores 2021/2

##### Repositório com os 5 trabalhos do período.

&nbsp;
&nbsp;

## :one: Trabalho 1

##### Esse trabalho apenas implementa regexes no Lex que interpretem:

- Comentários do estilo JavaScript
- Strings com "", '' e \`\`
- Números
- For
- If
- Alguns operadores booleanos

##### Ao fim, o programa mostra todos os tokens lidos.

&nbsp;
##  :two: Trabalho 2

##### Esse trabalho implementa um analisador recursivo descendente que enxerga apenas um símbolo a frente. Expressões aritméticas com + (também unário), - (também unário), \*, /, ^, ! (fatorial), funções e comando 'print' são aceitos pelo analisador. Ele gera um código intermediário em notação polonesa reversa.

&nbsp;


## :three: Trabalho 3

##### Esse trabalho começa a implementação de um compilador simples de JavaScript. Ele aceita expressões em geral, declarações, loops e condicionais (while, for, if e else). Possui muitos bugs e um desempenho ruim para análise de endereços. Os trabalhos 4 e 5 continuam a implementação e melhoria do compilador.

&nbsp;

## :four: Trabalho 4

##### Esse trabalho implementa funções e objetos com argumentos no compilador anterior. Ainda pode apresentar diversos bugs. Entretanto, possui uma melhoria de desempenho na resolução de endereços e corrige alguns bugs, principalmente quanto à troca de \n por ; e pós incrementos.

&nbsp;

## :five: Trabalho 5

##### Esse trabalho implementa a versão final do compilador. Apesar das limitações, possui expressões lambdas, declarações de funções anônimas (todas sem closure) e argumentos default. Corrige mais bugs e melhora o código gerador de objetos com argumentos. Ainda assim, pode possuir bugs não testados.

&nbsp;

## Como compilar?


##### Para o trabalho 1, digite:

```
$ lex scan.lex
$ g++ lex.yy.c main.cc -o <nome do programa> -ll -lfl
```

##### Para o trabalho 2, digite:

```
$ lex scan.lex
$ g++ lex.yy.c -o <nome do programa> -ll -lfl
```

##### Para os trabalhos 3, 4 e 5, esteja no diretório e digite:

```
$ make
```

##### Será gerado um executável de nome "programa". Passe o arquivo desejado utilizando o < ou utilize o "cat" ou o "echo" junto ao | (pipe).

