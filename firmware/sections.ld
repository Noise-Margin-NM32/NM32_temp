ENTRY(_start)

MEMORY
{
    FLASH (rx)  : ORIGIN = 0x00000000, LENGTH = 2M
    RAM   (rwx) : ORIGIN = 0x30000000, LENGTH = 128K
}

SECTIONS
{
    .text : AT(0x00000000)
    {
        _text_ram_start = .;
        *(.text.boot)
        *(.text*)
        *(.rodata*)
        _text_ram_end = .;
    } > RAM

    _text_flash_start = 0x00000000;

    .data : AT(LOADADDR(.text) + SIZEOF(.text))
    {
        _data_ram_start = .;
        *(.data*)
        _data_ram_end = .;
    } > RAM

    _data_flash_start = LOADADDR(.data);

    .bss (NOLOAD) :
    {
        _bss_start = .;
        *(.bss*)
        *(COMMON)
        _bss_end = .;
    } > RAM

    /* Set Stack Top to the end of 128KB RAM (0x30020000) */
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
