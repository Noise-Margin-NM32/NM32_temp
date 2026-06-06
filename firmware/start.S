.section .text
.global _start

_start:
    /* 1. Setup the stack pointer (defined in sections.ld) */
    la sp, _stack_start

    /* 2. Copy the .data section from ROM (Flash) to SRAM */
    la a0, _data_load_start
    la a1, _data_start
    la a2, _data_end
    bge a1, a2, end_init_data
loop_init_data:
    lw a3, 0(a0)
    sw a3, 0(a1)
    addi a0, a0, 4
    addi a1, a1, 4
    blt a1, a2, loop_init_data
end_init_data:

    /* 3. Zero out the .bss section in SRAM */
    la a0, _bss_start
    la a1, _bss_end
    bge a0, a1, end_init_bss
loop_init_bss:
    sw zero, 0(a0)
    addi a0, a0, 4
    blt a0, a1, loop_init_bss
end_init_bss:

    /* 4. Jump to your C main() function */
    call main

    /* 5. Infinite trap loop if main() ever accidentally returns */
trap:
    j trap