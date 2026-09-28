/* Linker script for small GCC -m16 GMU OS applications.
 * The original MikeOS loader places external programs at offset 0x8000.
 */
OUTPUT_FORMAT(binary)
ENTRY(_start)
SECTIONS
{
    . = 0x8000;
    .text : { *(.text.start*) *(.text*) }
    .rodata : { *(.rodata*) }
    .data : { *(.data*) }
    .bss : { *(.bss*) *(COMMON) }
    /DISCARD/ : { *(.comment*) *(.note*) *(.eh_frame*) *(.got*) *(.got.plt*) }
}
