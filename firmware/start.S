/*
 * start.S - NM32 reset entry and trap vectors (first code in the Boot ROM)
 *
 * Ibex (boot_addr_i = 0x0) resets to boot_addr + 0x80 and resets mtvec to
 * boot_addr in VECTORED mode. So the ROM starts with a 32-entry vector table
 * at 0x00-0x7C (entry n is taken for interrupt cause n; all exceptions use
 * entry 0), and _start sits at exactly 0x80. sections.ld asserts this.
 *
 * Boot sequence:
 *   1. Stack just below the 256-byte mailbox at the top of SRAM
 *   2. Copy the application from SPI flash to SRAM (bootloader.c).
 *      tb.sv's NM32_FAST_BOOT mode NOPs this call (it must stay at 0x88).
 *   3. Clear .bss
 *   4. Jump to main() in SRAM
 *
 * Any trap before main() installs its own handler lands in trap_dump, which
 * writes mcause / mepc / mtval to the SRAM mailbox (0x3000_7F20..28) and
 * spins. tb.sv reports the values and ends the run.
 */

    .section .text
    .global _start

    /* ---- 0x00: vector table (32 x 4 bytes) ---- */
    .option norvc
vectors:
    .rept 32
    j trap_dump
    .endr

    /* ---- 0x80: reset entry ---- */
_start:
    la   sp, _stack_top                 /* 0x80, 0x84 (auipc + addi) */
    call hardware_spi_bootloader        /* 0x88: NOP'd by tb in NM32_FAST_BOOT */

    la   a0, _bss_start
    la   a1, _bss_end
    bge  a0, a1, end_init_bss
loop_init_bss:
    sw   zero, 0(a0)
    addi a0, a0, 4
    blt  a0, a1, loop_init_bss
end_init_bss:

    la   a0, main
    jalr ra, a0, 0

    /* main() returned: park here */
park:
    j park

    /* ---- Fatal trap: dump cause to the mailbox and spin ---- */
trap_dump:
    li   t0, 0x30007F20
    csrr t1, mcause
    sw   t1, 0(t0)
    csrr t1, mepc
    sw   t1, 4(t0)
    csrr t1, mtval
    sw   t1, 8(t0)
trap_spin:
    j trap_spin
