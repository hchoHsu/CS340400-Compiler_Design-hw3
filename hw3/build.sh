rm codegen y.tab.c y.tab.h lex.yy.c
make
./codegen < test.c > ./build/codegen.S