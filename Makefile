# general tools and flags used
ASSEMBLER = nasm
ASM_FLAGS = -felf64
LINKER = ld

all: a.out
	./a.out
	
main.o: main.asm
	$(ASSEMBLER) $(ASM_FLAGS) $< -o $@

a.out: main.o
	$(LINKER) $<
