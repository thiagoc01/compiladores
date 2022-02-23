all: programa clean

programa: y.tab.c
	g++ y.tab.c -o programa -lfl

y.tab.c : lex.yy.c mini_js.y
	yacc mini_js.y

lex.yy.c : mini_js.l
	lex mini_js.l;

clean:
	rm lex.yy.c;
	rm y.tab.c;