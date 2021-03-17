# general tools and flags used
ASSEMBLER = nasm
ASM_FLAGS = -f elf64 -F dwarf -g
LINKER = ld

#source and object files
SRCS = main.asm util.asm math.asm

OBJS = $(SRCS:.asm=.o)

OUTPUT = ./a.out

all: $(OUTPUT)
	$(OUTPUT)

$(OUTPUT): $(OBJS)
	$(LINKER) $(OBJS)

%.o: %.asm
	$(ASSEMBLER) $(ASM_FLAGS) $< -o $@
	@echo "Compiling $<"

clean:
	rm *.o *.out
