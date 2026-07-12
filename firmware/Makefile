# Define the RISC-V GCC toolchain prefix
PREFIX ?= riscv64-unknown-elf-
CC      = riscv64-unknown-elf-gcc
OBJCOPY = $(PREFIX)objcopy 
OBJDUMP = $(PREFIX)objdump

# PicoRV32 specific flags: 32-bit integer instructions only (RV32I)
CFLAGS = -mabi=ilp32 -march=rv32i -Os -ffreestanding -nostdlib

# Default target (Removed commas from target names)
all: bootrom.hex firmware_flash.hex firmware.asm

# Step 1: Compile and link ALL source files together in one shot.
# This allows the linker script to properly route code sections using VMA/LMA.
firmware.elf: start.o bootloader.o main.o sections.ld
	$(CC) $(CFLAGS) -T sections.ld -o firmware.elf start.o bootloader.o main.o

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
	$(CC) $(CFLAGS) -c $< -o $@

# Step 2: Extract the Boot ROM binary segment (.boot section only)
bootrom.bin: firmware.elf
	$(OBJCOPY) -O binary -j .boot firmware.elf bootrom.bin

# Step 3: Extract the External Flash binary segment (.text and .data sections)
firmware_flash.bin: firmware.elf
	$(OBJCOPY) -O binary -j .text -j .data firmware.elf firmware_flash.bin

# Step 4: Convert raw binaries into 32-bit Verilog-readable hex patterns
bootrom.hex: bootrom.bin
	@echo "Generating Verilog hex file for internal Boot ROM..."
	hexdump -v -e '1/4 "%08X\n"' bootrom.bin > bootrom.hex

firmware_flash.hex: firmware_flash.bin
	@echo "Generating Verilog hex file for external SPI Flash..."
	hexdump -v -e '1/4 "%08X\n"' firmware_flash.bin > firmware_flash.hex

firmware.asm: firmware.elf
	@echo "Generating mixed source/assembly disassembly listing..."
	$(OBJDUMP) -d -S firmware.elf > firmware.asm
    
clean:
	rm -f *.elf *.bin *.hex *.asm *.o