OUTPUT_ARCH( "riscv" )
ENTRY(_start)

/* ======================================================================= */
/* 1. PHYSICAL MEMORY DEFINITION                                           */
/* ======================================================================= */
MEMORY
{
    /* 4KB Boot ROM at 0x0000_0000. Read & Executable only */
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 4K
    
    /* 4KB Data SRAM at 0x3000_0000. Read, Write & Executable */
    RAM (rwx) : ORIGIN = 0x30000000, LENGTH = 4K
}

/* ======================================================================= */
/* 2. SECTION PLACEMENT CODE                                               */
/* ======================================================================= */
SECTIONS
{
    /* --- Output Section 1: The Code Base --- */
    .text : {
        . = ALIGN(4);      /* Ensure 32-bit alignment */
        *(.text)           /* Include all instruction blocks */
        *(.text.*)         
        *(.rodata)         /* Include hardcoded constants */
        *(.rodata.*)
        . = ALIGN(4);
    } > ROM                /* Force this entire block into the Boot ROM */

    /* --- Output Section 2: Initialized Variables --- */
    /* AT> ROM sets the LMA (storage location). > RAM sets the VMA (runtime location) */
    .data : {
        . = ALIGN(4);
        _data_start = .;   /* TAG: Start of RAM data for start.S */
        *(.data)           
        *(.data.*)
        . = ALIGN(4);
        _data_end = .;     /* TAG: End of RAM data for start.S */
    } > RAM AT> ROM        

    /* TAG: Where the data's backup image sits in the ROM for start.S to copy from */
    _data_load_start = LOADADDR(.data);

    /* --- Output Section 3: Zero-Initialized Variables --- */
    .bss : {
        . = ALIGN(4);
        _bss_start = .;    /* TAG: Start of uninitialized data for start.S */
        *(.bss)
        *(.bss.*)
        *(COMMON)          
        . = ALIGN(4);
        _bss_end = .;      /* TAG: End of uninitialized data for start.S */
    } > RAM

    /* --- Output Section 4: System Stack Placement --- */
    /* The stack pointer starts at the very top of memory and grows downwards */
    PROVIDE(_stack_start = ORIGIN(RAM) + LENGTH(RAM));
}
