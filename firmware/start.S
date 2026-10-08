.section .boot_vectors, "ax"
.global _start
.global trap_entry

/* -------------------------------------------------------------------------
 * 1. Vector Table (Placed at ROM base 0x00000000)
 * ------------------------------------------------------------------------- */
_start:
    j reset_handler          /* 0x00000000: Power-On Reset Entry */

.org 0x00000010
irq_vector:
    j trap_entry             /* 0x00000010: Hardwired PicoRV32 PROGADDR_IRQ */

/* -------------------------------------------------------------------------
 * 2. Reset Handler (Executes in ROM)
 * ------------------------------------------------------------------------- */
reset_handler:
    /* Set up stack pointer at top of RAM (0x30020000) */
    la sp, _stack_top

    /* Zero-out .bss section in SRAM */
    la a0, _bss_start
    la a1, _bss_end
    bge a0, a1, end_init_bss
loop_init_bss:
    sw zero, 0(a0)
    addi a0, a0, 4
    blt a0, a1, loop_init_bss
end_init_bss:

    /* Jump directly to main() app */
    la a0, main
    jalr ra, a0, 0

    /* Safety fallback trap loop */
trap_loop:
    j trap_loop

/* -------------------------------------------------------------------------
 * 3. Assembly Trap Handler (PicoRV32 Custom Interrupt Return)
 * ------------------------------------------------------------------------- */
trap_entry:
    /* Allocate stack frame for caller-saved registers */
    addi sp, sp, -64
    sw   ra,  0(sp)
    sw   a0,  4(sp)
    sw   a1,  8(sp)
    sw   a2, 12(sp)
    sw   a3, 16(sp)
    sw   a4, 20(sp)
    sw   a5, 24(sp)
    sw   a6, 28(sp)
    sw   a7, 32(sp)
    sw   t0, 36(sp)
    sw   t1, 40(sp)
    sw   t2, 44(sp)
    sw   t3, 48(sp)
    sw   t4, 52(sp)
    sw   t5, 56(sp)
    sw   t6, 60(sp)

    /* Call C Interrupt Handler Routine */
    call c_irq_handler

    /* Restore caller-saved registers */
    lw   ra,  0(sp)
    lw   a0,  4(sp)
    lw   a1,  8(sp)
    lw   a2, 12(sp)
    lw   a3, 16(sp)
    lw   a4, 20(sp)
    lw   a5, 24(sp)
    lw   a6, 28(sp)
    lw   a7, 32(sp)
    lw   t0, 36(sp)
    lw   t1, 40(sp)
    lw   t2, 44(sp)
    lw   t3, 48(sp)
    lw   t4, 52(sp)
    lw   t5, 56(sp)
    lw   t6, 60(sp)
    addi sp, sp, 64

    /* FIX 2: Replace standard 'ret' with PicoRV32 'picorv32_retirq' opcode */
    .word 0x0200000b
