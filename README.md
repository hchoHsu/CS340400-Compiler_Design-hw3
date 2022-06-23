# CS340400-Compiler_Design-hw3

## Prerequisite
1. Lex
2. Yacc
3. RISC-V Spike Simulator (https://github.com/riscv-software-src/riscv-tools)

## Discription
This is a Yacc/Lex Based C Compiler that compiles C into RISC-V assembly code to run a Arduino Simulator
The Code itself is specified to pass the testcases provided.

## Compile
To compile the c code, run
```
./hw3/build.sh ${your-c-code}
```
The output assembly codes will be at ./hw3/build/codegen.S

## Run the Arduino Simulator
```
./hw3/run.sh
```
