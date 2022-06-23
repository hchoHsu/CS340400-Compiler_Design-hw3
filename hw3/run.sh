riscv64-unknown-elf-gcc -o ./build/sample_prog ./build/main.c ./build/codegen.S
spike pk ./build/sample_prog