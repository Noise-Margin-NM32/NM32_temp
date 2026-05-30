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

# Step 2: Extract the raw machine code into a Verilog-readable HEX format
firmware.hex: firmware.elf
	$(OBJCOPY) -O verilog firmware.elf firmware.hex

# Cleanup command
clean:
	rm -f firmware.elf firmware.hex