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

    /* --- 2. Main Application Code Section (.text) --- */
    /* VMA (Runtime) = RAM (0x30000000) | LMA (Storage) = FLASH (0x80000000) */
    .text : {
        . = ALIGN(4);
        _text_ram_start = .;       /* Start address in RAM */
        *(.text)                   /* All application code instructions */
        *(.text.*)
        *(.rodata)                 /* Constant globals and strings */
        *(.rodata.*)
        . = ALIGN(4);
        _text_ram_end = .;         /* End address in RAM */
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
        *(COMMON)
        . = ALIGN(4);
        _bss_end = .;
    } > RAM


    /* --- 5. Stack Pointer Initialization --- */
    /* Top of the 4KB RAM block growing downward */
    PROVIDE(_stack_top = ORIGIN(RAM) + LENGTH(RAM));
}