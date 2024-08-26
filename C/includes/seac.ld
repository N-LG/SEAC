OUTPUT_FORMAT(elf32-i386)
SECTIONS
{
    . = 0x0;
    .text : ALIGN(16)
    {
        *(.text);
    }

    .data : 

    {
        *(.data);
        *(.rodata);
        *(.bss);
    }
}
