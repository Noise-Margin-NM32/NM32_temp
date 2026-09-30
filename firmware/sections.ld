OUTPUT_ARCH( "riscv" )
ENTRY(_start)

/* ======================================================================= */
/* 1. PHYSICAL MEMORY DEFINITION                                           */
/* ======================================================================= */
MEMORY
{
    /* 4KB Boot ROM. Houses only the bootloader code */
    ROM (rx)   : ORIGIN = 0x00000000, LENGTH = 4K
    
    /* 32KB Internal SRAM (ITCM). Main application executes here */
    RAM (rwx)  : ORIGIN = 0x30000000, LENGTH = 32K

    /* External SPI Flash memory footprint mapped image */
    FLASH (rx) : ORIGIN = 0x80000000, LENGTH = 64K
}

/* ======================================================================= */
/* 2. SECTION PLACEMENT CODE                                               */
/* ======================================================================= */
SECTIONS
{
    /* --- 1. Bootloader Code Section --- */
    /* This section goes entirely into the Boot ROM and runs from there */
    .boot : {
        . = ALIGN(4);
        *start.o(.text .text.*)     /* Pull text from start assembly file */
        *start.o(.rodata .rodata.*) 
        *bootloader.o(.text .text.*) /* Pull text from C bootloader */
        *bootloader.o(.rodata .rodata.*) 
        . = ALIGN(4);
    } > ROM

    /* Ibex resets to boot_addr + 0x80: start.S puts a 32-entry vector table
       first, so _start must land exactly there. */
    ASSERT(_start == 0x80, "_start must be at 0x80 (Ibex reset vector)")

    /* --- 2. Main Application Code Section (.text) --- */
    /* VMA (Runtime) = RAM (0x30000000) | LMA (Storage) = FLASH (0x80000000) */
    .text : {
        . = ALIGN(4);
        _text_ram_start = .;       /* Start address in RAM */
        *(.text)                   /* All application code instructions */
        *(.text.*)
        *(.rodata)                 /* Constant globals and strings */
        *(.rodata.*)
        *(.srodata)                /* Small constants (gp-relative)     */
        *(.srodata.*)
        *(.eh_frame)
        . = ALIGN(4);
        _text_ram_end = .;        /* End address in RAM */
    } > RAM AT> FLASH

    /* Location of the .text binary payload inside the external Flash */
    _text_flash_start = LOADADDR(.text);


    /* --- 3. Initialized Application Variables (.data) --- */
    /* VMA (Runtime) = RAM | LMA (Storage) = FLASH */
    .data : {
        . = ALIGN(4);
        _data_ram_start = .;       /* Start of mutable data in RAM */
        *(.data)                   /* Initialized variables (e.g., int x = 5;) */
        *(.data.*)
        *(.sdata)                  /* Small initialized globals: must be  */
        *(.sdata.*)                /* inside the range the bootloader copies */
        . = ALIGN(4);
        _data_ram_end = .;         /* End of mutable data in RAM */
    } > RAM AT> FLASH

    /* Location of the .data initialization bytes inside the external Flash */
    _data_flash_start = LOADADDR(.data);


    /* --- 4. Uninitialized Variables (.bss) --- */
    /* Stays strictly in RAM; filled with zeroes during boot */
    .bss : {
        . = ALIGN(4);
        _bss_start = .;
        *(.bss)
        *(.bss.*)
        *(.sbss)                   /* Small zero-init globals: must be   */
        *(.sbss.*)                 /* inside the range start.S clears    */
        *(COMMON)
        . = ALIGN(4);
        _bss_end = .;
    } > RAM


    /* --- 5. Stack Pointer Initialization --- */
    /* Top of the 4KB RAM block growing downward */
    /* The top 256 bytes of SRAM (0x3000_7F00-0x3000_7FFF) are the testbench
       mailbox: +0x00 handshake, +0x20/+0x24/+0x28 trap mcause/mepc/mtval.
       The stack starts below it, so ordinary stack writes can never look
       like a mailbox write. main() alone needs ~4.2 KB of stack. */
    PROVIDE(_mailbox_base = ORIGIN(RAM) + LENGTH(RAM) - 256);
    PROVIDE(_stack_top = _mailbox_base);
    ASSERT(_bss_end + 4608 <= _stack_top, "less than 4.5 KB left for the stack: SRAM is full")
}