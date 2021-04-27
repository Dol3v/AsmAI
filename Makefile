# general tools and flags used
ASSEMBLER = nasm
ASM_FLAGS = -f elf64 -F dwarf -g
LINKER = ld

#source and object files
SRCS = main.asm util.asm math.asm approx.asm compatibility.asm activation.asm forward_prop.asm loss.asm derivatives.asm gradient_descent.asm

OBJS = $(SRCS:.asm=.o)

OUTPUT = ./a.out

.PHONY: all
all: $(OUTPUT)
	$(OUTPUT)

$(OUTPUT): $(OBJS)
	$(LINKER) $(OBJS)

%.o: %.asm
	$(ASSEMBLER) $(ASM_FLAGS) $< -o $@
	@echo "Compiling $<"

.PHONY: clean
clean:
	rm *.o *.out

install-tools: #installs all tools used in running the program
	sudo apt-get install ld
	sudo apt-get update -y
	sudo apt-get install -y nasm
	sudo apt-get install -y nasm
  