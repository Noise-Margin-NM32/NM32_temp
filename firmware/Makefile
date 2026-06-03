# Define the RISC-V GCC toolchain prefix
# (If your installation uses riscv32-unknown-elf-, change this accordingly)
PREFIX ?= riscv64-unknown-elf-
CC = $(PREFIX)gcc
OBJCOPY = $(PREFIX)objcopy 

# PicoRV32 specific flags: 32-bit integer instructions only (RV32I)
CFLAGS = -mabi=ilp32 -march=rv32im -Os -ffreestanding -nostdlib

# Default target
all: firmware.hex

# Step 1: Compile and link everything into an ELF binary
firmware.elf: start.S main.c sections.ld
	$(CC) $(CFLAGS) -T sections.ld -o firmware.elf start.S main.c
# Step 1.5: Convert ELF to raw binary
firmware.bin: firmware.elf
	$(OBJCOPY) -O binary firmware.elf firmware.bin
	
# Step 2: Extract the raw machine code into a Verilog-readable HEX format
#firmware.hex: firmware.elf
#	$(OBJCOPY) -O verilog --verilog-data-width=4 firmware.elf firmware.hex
firmware.hex: firmware.bin
	@echo "Generating Verilog hex file..."
	@echo "@00000000" > firmware.hex
	hexdump -v -e '1/4 "%08X\n"' firmware.bin >> firmware.hex
	
# Cleanup command
clean:
	rm -f firmware.elf firmware.hex
