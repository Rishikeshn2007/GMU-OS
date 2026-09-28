# GMU OS 0.1 Architecture

GMU OS 0.1 is a **C-oriented learning derivative** of MikeOS 4.7.0.
It deliberately preserves the original boot/kernel architecture while adding
a student-facing C development layer.

## Execution path

```text
BIOS
  -> source/bootload/bootload.asm
  -> KERNEL.BIN (source/kernel.asm + source/features/*.asm)
  -> MikeOS-compatible API vectors at fixed offsets
  -> external program loaded at offset 0x8000
  -> GMU C entry stub
  -> C function gmu_main()
```

## Why assembly is still present

MikeOS is a 16-bit real-mode x86 operating system. Its bootloader, BIOS
interrupt use, segment setup and fixed system-call ABI are inherently tied to
machine-level behavior. Rewriting all of that in ordinary hosted C would no
longer be a small modification of MikeOS.

For this first GMU edition, the assembly code is treated as the low-level
platform layer. Students can progressively read it, but most early extension
work can be done in C.

## C application model

MikeOS loads a `.BIN` program at offset `0x8000` and invokes it with a 16-bit
`CALL`. GCC `-m16` generated C uses a 32-bit stack convention internally.
`c_src/include/gmuos.h` therefore provides a tiny entry bridge that:

1. initializes a known 32-bit ESP value,
2. calls the student's C function,
3. returns to the OS with a 16-bit `RET`.

The same header also contains small wrappers that call selected MikeOS API
vectors such as print-string, clear-screen and wait-for-key.

## Important constraints

- This environment targets a 386-or-better x86 processor in 16-bit real mode.
- Programs are linked at offset `0x8000`.
- There is no standard C library (`stdio.h`, `malloc`, etc.) in this first edition.
- C programs are freestanding and use GMU OS / MikeOS services through
  `gmuos.h`.
- Keep programs small; the original MikeOS memory model is intentionally tiny.
