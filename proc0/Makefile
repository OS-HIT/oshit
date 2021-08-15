all: proc0 proc0.asm proc0.sym

proc0: proc0.c
	riscv64-unknown-elf-gcc -Wall -O -fno-omit-frame-pointer -ggdb -MD -mcmodel=medany -ffreestanding -fno-common -nostdlib -mno-relax -fno-pie -no-pie -fno-stack-protector -march=rv64g -nostdinc -c proc0.c -o proc0.o
	riscv64-unknown-elf-ld -o proc0 -T linker.ld proc0.o

proc0.asm: proc0
	rust-objdump -S proc0 > proc0.asm

proc0.sym: proc0
	rust-objdump -t proc0 | sed '1,/SYMBOL TABLE/d; s/ .* / /; /^$$/d' | sort > proc0.sym

clean:
	rm -rf proc0 proc0.d proc0.o proc0.asm proc0.sym

.PHONY: proc0 clean all
