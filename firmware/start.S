.section .text
.global _start

_start:
    /* 1. Set up the stack pointer immediately so we can call C functions */
    la sp, _stack_top

    /* 2. Call the C bootloader routine to fetch code/data over SPI */
    call hardware_spi_bootloader

    /* 3. Now that the main application code/data is safely in RAM, 
          zero out the .bss section in SRAM */
    la a0, _bss_start
    la a1, _bss_end
    bge a0, a1, end_init_bss
loop_init_bss:
    sw zero, 0(a0)
    addi a0, a0, 4
    blt a0, a1, loop_init_bss
end_init_bss:

    /* 4. Jump directly to the newly copied main() application inside RAM */
    la a0, main
    jalr ra, a0, 0

    /* 5. Infinite trap loop if main ever exits */
trap:
    j trap