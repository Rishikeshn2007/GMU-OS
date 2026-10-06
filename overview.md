# GMU OS Overview

## 1. What this OS is

GMU OS 0.1 is a small, bootable teaching OS derived from MikeOS 4.7.0. It
retains MikeOS's 16-bit x86 real-mode bootloader and assembly kernel, with a
small C interface added so that student applications can be written in C.
It is designed to make the boot process, kernel routines, and application
interface approachable—not to provide the process isolation and multitasking
features of a modern desktop or server OS.

The core implementation is in `source/`: a one-sector bootloader, a kernel,
and assembly modules for the kernel's features. The `programs/` directory
contains utilities, games, interpreters, and example applications. `c_src/`
contains the GMU C application interface and C examples.

## 2. What “16-bit” means here

The kernel is assembled with 16-bit code (`BITS 16`) and runs in the x86
processor's **real mode**. Most of its instructions and registers—such as
`AX`, `BX`, `CX`, `DX`, `SI`, and `DI`—are used as 16-bit values. A 16-bit
offset can represent 65,536 positions, so the kernel and its programs use a
small, constrained memory layout.

Real-mode addresses use a segment and an offset. In the usual real-mode
address calculation, the physical address is:

```text
physical address = segment * 16 + offset
```

The kernel sets its data segments to the segment where it was loaded and
expects its environment to fit within a small memory area. The boot and
kernel sources require a 386-or-newer processor: they are 16-bit code, but
also use some 386 instructions and registers. “16-bit OS” therefore describes
the execution mode and programming model; it does not mean every operation or
every data value is limited to 16 bits.

The C examples use GCC's `-m16` option. They are freestanding programs, not
ordinary hosted C applications: there is no standard C library such as
`stdio`, `malloc`, or an operating-system process runtime. The small adapter
in `c_src/include/gmuos.h` bridges the program's C entry point and the
kernel's 16-bit calling convention.

## 3. Boot: from power-on to the GMU OS menu

The normal boot sequence is:

1. **BIOS starts the boot device.** For the floppy image, the BIOS reads its
   first 512-byte sector into memory at the conventional boot address and
   transfers control to it.
2. **The boot sector runs `source/bootload/bootload.asm`.** It sets up a
   temporary stack, uses BIOS disk services (`INT 13h`), reads the FAT12
   root directory, and searches for `KERNEL.BIN`.
3. **The bootloader follows the FAT12 file allocation table.** It reads the
   kernel's disk sectors and loads the kernel at segment `0x2000`, offset
   `0x0000`. The boot sector is limited to one 512-byte sector and ends with
   the boot signature `0xAA55`.
4. **The bootloader transfers control to the kernel.** The kernel's first
   fixed call vector jumps to `os_main`.
5. **The kernel initializes its environment.** It establishes a stack,
   initializes its segment registers, records the boot drive, sets up text
   display behavior, and seeds the random-number generator.
6. **The OS checks for autorun files.** `AUTORUN.BIN`, if present, is loaded
   and run. Otherwise, `AUTORUN.BAS`, if present, is loaded and interpreted.
   If neither exists, the welcome screen offers a program selector or a
   command-line interface.

The kernel also uses BIOS services directly for hardware operations. For
example, BIOS disk calls are used by the disk code, and the screen, keyboard,
and clock-related routines use the available BIOS/platform facilities. This
keeps the implementation compact, but differs from a modern OS with its own
large device-driver stack.

## 4. Kernel services and the program interface

The kernel exposes a **fixed table of call vectors** at the beginning of
`source/kernel.asm`. Each entry is a short jump to a kernel routine; the
entries must stay at their documented offsets because existing programs call
them by address. A program supplies arguments in registers and calls a vector.
For example, the C helper `gmu_print(text)` places the string's offset in
`SI` and calls the print-string vector at offset `0x0003`.

These calls play a role similar to system calls in the sense that an
application asks the OS to perform a service. They are **not** the protected
system-call mechanism used by a modern OS. There is no user-mode/kernel-mode
privilege transition here: real mode has no such separation, and applications
can access the same low-level environment as the kernel. The call-vector table
is a small, fixed assembly ABI (application binary interface).

Kernel services are grouped into these areas:

| Area | Examples of services |
|---|---|
| Screen and text | Print strings, clear the screen, move the cursor, draw lines/blocks/backgrounds/dialogs, display decimal or hexadecimal values, and read a string |
| Keyboard and timing | Wait for a key, check for a key, pause, and obtain formatted date/time strings |
| Disk and files | List files, load and write files, check whether a file exists, create/remove/rename files, and get file size |
| Strings and numbers | Copy, compare, join, parse, tokenize, change case, convert numbers to/from strings, and convert BCD values |
| BASIC | Run the kernel's BASIC interpreter on a loaded `.BAS` program |
| Sound | Turn the PC speaker on with a tone or turn it off |
| Serial and ports | Enable/use serial communication and read/write bytes to hardware I/O ports |
| Miscellaneous | Get the API version, display fatal errors, dump registers, and generate random numbers |

The complete callable service list is the vector table in
`source/kernel.asm`; the implementations are in the modules under
`source/features/`. Programs should use the documented calling convention
and API version rather than assuming registers survive a call.

The C header intentionally wraps only a few services at present:
`gmu_print`, `gmu_newline`, `gmu_clear`, `gmu_wait_key`,
`gmu_input_string`, `gmu_speaker_tone`, and `gmu_speaker_off`. It demonstrates
how a C program can reach the assembly kernel; it is not a full C standard
library.

## 5. How programs are loaded and “processes” are managed

When a user selects a `.BIN` file, the kernel loads it into RAM at offset
`0x8000` in the shared kernel segment, clears the screen, and calls that
address. A program is expected to finish with a 16-bit `RET`, returning to
the kernel's caller. The kernel then displays a completion prompt and returns
to the application selector. A `.BAS` file is loaded to the same area and
passed to the kernel's BASIC interpreter instead.

For the C examples, `GMU_C_ENTRY()` creates a small `_start` routine. It
sets up the stack expected by the 32-bit stack operations generated for
GCC's `-m16` C code, calls `gmu_main()`, restores the 16-bit stack pointer,
and returns to the OS.

This is a **single-tasking program execution model**, not a general process
manager. The kernel does not create a process table/PCB for each application,
save multiple process contexts, or switch between runnable programs. It has
no CPU scheduler, time-slicing, user/kernel protection, virtual memory,
per-process address spaces, or process isolation. The application is simply
loaded into a known RAM location, called, and expected to return. A program
that corrupts shared memory or fails to return can hang or crash the OS.

Likewise, the OS does not implement an IPC framework or a dedicated shared
memory facility. The kernel and application use the same small real-mode
memory environment, but that is shared access—not isolated processes
communicating through an OS-managed IPC mechanism. Scheduling algorithms
such as FCFS, SJF, priority scheduling, and round-robin are useful concepts
for comparison, but they are not implemented by this OS.

## 6. User-facing programs and system programs

The kernel itself includes the command-line interpreter and BASIC interpreter.
It also offers a file selector. The CLI commands implemented in
`source/features/cli.asm` include:

- `HELP`, `ABOUT`, `PBL`, `VER`, `TIME`, `DATE`, `EXIT`
- `CLS`, `DIR` (also `LS`), `CAT`, `SIZE`
- `COPY`, `REN`, and `DEL`
- A `/?` help form for supported commands

External files under `programs/` are loaded like applications; they are not
kernel services. The repository includes, among others:

- **Utilities and tools:** file manager, text and binary editors, viewer,
  terminal, monitor, keyboard tester, and code-byte utility.
- **Interpreters/languages:** BASIC example programs and a Forth interpreter
  with a sample Forth program.
- **Games and demonstrations:** Pong, Life, Hangman, Fisher, Lines, and other
  BASIC or assembly examples.
- **C examples:** `GMUINFO.BIN` and `TIMER.BIN`, with C source under `c_src/`.

The program selector permits `.BIN` and `.BAS` files. These applications
extend what a user can do, but are not all resident kernel components.

## 7. Building and exploring the repository

The implementation is primarily NASM assembly:

- `source/bootload/bootload.asm` — FAT12 boot sector and kernel loader.
- `source/kernel.asm` — fixed service vectors, startup, program selection,
  and the feature-module includes.
- `source/features/` — command line, disk/files, keyboard, math,
  miscellaneous, ports, screen, sound, strings, and BASIC routines.
- `programs/` — external assembly, BASIC, Forth, and binary programs.
- `c_src/` — C examples, `gmuos.h`, linker script, and C build helper.
- `disk_images/` — bootable disk and ISO images.

The normal upstream-style build uses NASM to assemble the bootloader, kernel,
and assembly programs, then places them in a FAT12 floppy image. The GMU
workflow also builds C applications using GCC/binutils with `-m16` and links
them as flat binaries at `0x8000`. The scripts are
`build-linux.sh` / `build-gmu-linux.sh` (Linux), the Windows batch build
scripts, and the platform-specific build scripts in the repository root.
Build requirements and exact steps can vary by platform; inspect the relevant
script before running it.

For a useful study path, start with `source/bootload/bootload.asm`, follow its
transfer into `source/kernel.asm`, trace `execute_bin_program`, and then pick
one service such as `os_print_string` or `os_load_file` in `source/features/`.
Compare its register-based interface with a C wrapper in
`c_src/include/gmuos.h` and its use in `c_src/examples/gmuinfo.c`.

## 8. Connecting GMU OS to OS-class concepts

| Concept from class | How it relates here |
|---|---|
| Booting | BIOS loads a boot sector; the bootloader finds and loads the kernel; kernel initialization starts the user interface. |
| Kernel services | Fixed call vectors provide screen, input, file, string, sound, and other routines. |
| System calls | Applications call kernel vectors, but these do not switch from user mode to kernel mode. |
| I/O operations | BIOS and basic hardware interfaces are used for disk, screen, keyboard, speaker, serial, and ports. |
| Process life cycle | Simplified to load → call/run → return to the selector. There is no full process abstraction or scheduler. |
| CPU scheduling | Not implemented: there is no multiprogramming or time-sharing scheduler. |
| IPC/shared memory | No IPC subsystem; kernel and program operate in a common real-mode memory environment. |
| Firmware | The BIOS is firmware that performs early hardware initialization and provides basic services used during boot and runtime. |
| 16-bit processing | The OS executes 16-bit real-mode code with segment:offset addressing and a small memory model, on a 386-or-newer target. |

The main lesson is to distinguish **a kernel routine that provides a useful OS
service** from **a complete modern OS mechanism**. GMU OS has kernel services
and an application loader, but deliberately does not implement protected
processes, concurrency, or CPU scheduling.


Search for `0x8000|32768|load_position|os_load_file|exec|program`

Read , lines 1 to 100
Completed with input: {
  "path": "c:\\Users\\Rishikesh N\\Desktop\\sem-3\\PBL\\OS-PBL\\overview.md",
  "view_range": [
    1,
    100
  ]
}

Read , lines 1 to 45
Completed with input: {
  "path": "c:\\Users\\Rishikesh N\\Desktop\\sem-3\\PBL\\OS-PBL\\source\\kernel.asm",
  "view_range": [
    1,
    45
  ]
}

Read , lines 245 to 285
Completed with input: {
  "path": "c:\\Users\\Rishikesh N\\Desktop\\sem-3\\PBL\\OS-PBL\\source\\kernel.asm",
  "view_range": [
    245,
    285
  ]
}

Read , lines 255 to 330
Completed with input: {
  "path": "c:\\Users\\Rishikesh N\\Desktop\\sem-3\\PBL\\OS-PBL\\source\\features\\cli.asm",
  "view_range": [
    255,
    330
  ]
}

Read , lines 160 to 180
Completed with input: {
  "path": "c:\\Users\\Rishikesh N\\Desktop\\sem-3\\PBL\\OS-PBL\\source\\features\\disk.asm",
  "view_range": [
    160,
    180
  ]
}

Search for `mov ds|mov ss|mov sp|mov es`

Read , lines 110 to 138
Completed with input: {
  "path": "c:\\Users\\Rishikesh N\\Desktop\\sem-3\\PBL\\OS-PBL\\source\\kernel.asm",
  "view_range": [
    110,
    138
  ]
}

In this OS, **processes don’t get separate RAM allocations**. It doesn’t support multitasking: it loads **one program at a time** into the same slot, runs it, and returns to the shell when it finishes.

`0x8000` is an **offset**, not a physical address. The kernel sets its data segment to `0x2000`, so the program’s physical load address is:

```text
0x2000 × 16 + 0x8000 = 0x28000
```

The kernel’s intended layout within that 64 KB segment is:

| Offset range | Purpose | Size |
|---|---|---:|
| `0x0000`–`0x5FFF` | Kernel code and data | 24 KB |
| `0x6000`–`0x7FFF` | Disk buffer | 8 KB |
| `0x8000`–`0xFFFF` | Program load area | 32 KB |

So a program can use **up to about 32 KB** in that slot; its actual loaded bytes depend on the file. This is not a share of all installed RAM—just the memory area this OS reserves for programs. The kernel defines the disk buffer at offset 24 KB in `kernel.asm`, and the shell loads and calls programs at offset 32 KB in `cli.asm`. The `OS overview` also describes its real-mode memory model.

A **disk buffer** is a temporary area in RAM where the OS stores data while reading from or writing to the disk. Here, it’s an 8 KB workspace used during disk operations—not memory assigned to a running program.

GMU-OS is built to run from a **1.44 MB floppy disk image** (`disk_images/gmuos.flp`), not installed as a partition on your hard drive. The image contains the OS kernel and the programs/files bundled with it; the actual files take less than the image’s full 1.44 MB capacity.

What if programs need more RAM and more disk space than 1.44 MB ?

- **More disk space:** A 1.44 MB floppy image can’t hold more than that. You’d need to support a larger disk or image, and update the disk and filesystem code to use it. The OS currently uses floppy-style FAT12 routines.
- **More RAM for a program:** The current layout gives a program a 32 KB load area. A larger program won’t fit there; the memory layout and loading code would need to change. Real mode also limits how memory is conveniently addressed.

So, increasing the disk image size alone would give the OS more room for files, but **wouldn’t give a running program more RAM**.