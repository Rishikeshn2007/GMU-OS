# How GMU-OS Works

This guide describes the repository as it is structured now. GMU-OS is a small 16-bit real-mode x86 operating system derived from MikeOS 4.7.0. It keeps MikeOS's bootloader, kernel and system-call interface, with additional GMU documentation and a small freestanding C application path.

## The Short Version

```text
PC firmware (BIOS)
  -> reads the first 512-byte sector from the boot floppy
  -> source/bootload/bootload.asm
  -> searches the FAT12 root directory for KERNEL.BIN
  -> loads KERNEL.BIN at 2000:0000 (physical address 0x20000)
  -> jumps to the kernel's first instruction
  -> kernel initializes real-mode environment and chooses a UI
  -> user selects a program or enters the command shell
  -> kernel loads one program at offset 0x8000 and calls it
  -> program returns to the kernel, which resumes the menu/shell
```

The processor executes one instruction stream at a time. BIOS routines provide early disk, screen, keyboard and reboot services; the kernel adds reusable routines through fixed API vectors.

## What Runs on the Processor?

The target is an Intel-compatible x86 processor that supports the 80386 instruction set or later. The kernel begins with `BITS 16` and `CPU 386`: it runs in **16-bit real mode**, while being allowed to use some 386 instructions and 32-bit registers. This is not a 32-bit protected-mode OS. The C build also uses `-m16 -march=i386`.

The included `README.md` launches QEMU with `qemu-system-i386`, which emulates a PC-compatible x86 machine. On real hardware, the BIOS performs the initial boot handoff; on QEMU, the emulated BIOS does it. The BIOS normally loads the boot sector to physical address `0x7C00` and supplies the boot drive number in `DL`.

The bootloader and kernel use BIOS interrupts, including:

- `INT 13h`: floppy disk services used to read sectors and drive geometry.
- `INT 10h`: text/video services used to print characters and set display attributes.
- `INT 16h`: keyboard services used for waiting for a key during reboot/error handling.
- `INT 19h`: BIOS bootstrap service used to reboot after a fatal boot error.

These are BIOS services, not modern protected-mode device drivers.

## Bootloader: Finding and Loading the Kernel

The boot code lives in [source/bootload/bootload.asm](source/bootload/bootload.asm). The build assembles it as a flat binary and writes it into the first sector of the floppy image. It must be exactly one 512-byte sector, with the boot signature `0xAA55` in its last two bytes. The first sector also contains FAT12/BIOS disk geometry information.

At a high level, the loader does this:

1. Establishes a stack and data segment, saves the BIOS boot-drive number, and asks the BIOS for drive geometry when needed.
2. Reads the FAT12 root directory. For a 1.44 MiB floppy this directory starts at logical sector 19 and occupies 14 sectors.
3. Searches the 224 root-directory entries for the 8.3 filename `KERNEL  BIN`.
4. Reads the first FAT into a temporary buffer, uses the kernel file's first cluster to find its data, then follows the FAT12 cluster chain until the end-of-file marker.
5. Loads each 512-byte cluster/sector consecutively into memory starting at `2000:0000`.
6. Passes the boot drive in `DL` and jumps to `2000:0000`.

A FAT12 cluster is 512 bytes on this image. The loader uses BIOS CHS disk reads (cylinder/head/sector), converting a logical sector number with its `l2hts` routine. If a read fails, it resets and retries the floppy; unrecoverable errors or a missing kernel display a message and reboot.

`2000:0000` is a segment:offset address. In real mode, the physical address is approximately `segment * 16 + offset`, so `0x2000 * 16 + 0 = 0x20000` (128 KiB). The loader does not load the kernel as a file into a modern virtual-memory system; it copies its sectors into physical RAM and jumps to that address.

## Kernel Startup and Program Execution

The main kernel is [source/kernel.asm](source/kernel.asm). It starts with a table of fixed-position API jump vectors, then reaches `os_main`. The vector offsets are part of the program ABI: application code can call stable offsets such as `0x0003` for `os_print_string`. Moving or reordering those vectors would break programs built against them.

The kernel startup code:

1. Sets up the stack and the data segments. `DS`, `ES`, `FS`, and `GS` are set to segment `0x2000`; the kernel and its loaded programs share this small real-mode environment.
2. Stores boot-device details and configures text output, then seeds its random-number generator.
3. Looks for `AUTORUN.BIN`, then `AUTORUN.BAS`. If either exists, it runs that first.
4. Otherwise displays a choice between the program selector and command-line interface.
5. Loads selected `.BIN` programs at offset `0x8000` (32 KiB into the kernel segment) and calls them. A well-behaved assembly/C binary returns with `RET`; the kernel then returns to the selector. BASIC files are passed to the built-in BASIC interpreter.

The C path is described in [gmu_docs/C_DEVELOPMENT.md](gmu_docs/C_DEVELOPMENT.md). `c_src/build-c-linux.sh` compiles freestanding C with GCC's 16-bit mode, and [c_src/gmu16.ld](c_src/gmu16.ld) links applications at offset `0x8000`. [c_src/include/gmuos.h](c_src/include/gmuos.h) defines a small entry stub and wrappers around selected API vectors. This does not add a C runtime, standard library, heap allocator, or a separate process environment.

## Process Manager and Scheduling

**There is no process manager or scheduling algorithm in this OS.** There is no round-robin scheduler, priority queue, process table, PID management, preemptive multitasking, or memory protection in the code described here.

Execution is sequential:

- The kernel runs the shell or program selector.
- It loads one application into the program area and calls its entry point.
- The application runs until it returns (or otherwise hands control back through the OS's expected flow).
- The kernel resumes the menu or shell.

A program that loops forever can keep the machine busy. BIOS keyboard waits and interrupts do not mean there is a process scheduler; they are services used by the current execution path. Think of it as a single-user, single-task teaching OS, not as a small version of Linux or Windows process management.

## Memory: What Is Used?

The source uses fixed addresses and buffers rather than a general memory manager. The important values are:

| Area | Size / address | Meaning |
|---|---:|---|
| Boot sector | 512 bytes at the BIOS boot location | Boot code and disk parameter table. |
| Bootloader work buffer | 8 KiB | Temporary root-directory/FAT data and sector handling during boot. |
| Kernel load address | `2000:0000`, physical `0x20000` | Beginning of the kernel's 64 KiB real-mode segment window. |
| Kernel disk buffer | offset `24576` (`0x6000`), 8 KiB | Reserved for disk operations; `disk_buffer` is defined in `source/kernel.asm`. |
| Program load address | offset `32768` (`0x8000`) | `.BIN` programs and BASIC source are loaded here. |
| Program region | `0x8000` through below `0x10000` | At most about 32 KiB of offset space before the end of the 64 KiB segment. |

The bootloader's own stack is placed above its temporary buffer. The kernel sets `SS:SP` during startup; the C entry macro in `gmuos.h` additionally initializes `ESP` to `0x0000FFF0` for the generated C code's stack convention. Real-mode segment registers matter: an offset is not by itself a physical address.

The existing `source/kernel.bin` file in this workspace is **22,753 bytes**. That is an artifact measurement, not a guarantee about a future build from edited source. The kernel disk buffer begins at offset 24,576 (`0x6000`), so this measured kernel is 1,823 bytes below that boundary. After changing kernel source, a build should confirm the kernel still fits before the reserved disk buffer. The `.BIN` program area starts at offset `0x8000`; program size and stack use must also stay within the small available memory layout.

The OS does not query and report total installed RAM, dynamically allocate memory, or track a live RAM-usage percentage. So there is no truthful single number for “RAM being used” independent of the running machine and workload. The table gives the statically reserved areas and the available address-space limits instead.

## Disk: Current Floppy Image Snapshot

The image is FAT12 with 512-byte sectors and clusters, 2,880 sectors total, so its nominal capacity is **1,474,560 bytes (1.44 MiB)**. A read-only inspection of the existing `disk_images/gmuos.flp` in this workspace reported:

- 32 files in the root directory.
- 177,358 bytes total file contents.
- 362 allocated data clusters: 185,344 bytes allocated, because disk allocation is in 512-byte clusters.
- 1,272,320 bytes free in the data area.

The difference between file-content bytes and allocated bytes is cluster rounding. The FATs, boot sector and root directory also consume image space, so capacity minus free data space is not the same as the sum of file lengths. These values describe the current image snapshot and can change after rebuilding or copying files. `disk_images/mikeos.iso` is a separate bootable CD image; it is 4,788,224 bytes in the current workspace and contains a floppy image as its boot image.

## How the Build Connects the Pieces

- [build-linux.sh](build-linux.sh) assembles the bootloader and kernel, assembles assembly applications in `programs/`, writes the boot sector into `disk_images/mikeos.flp`, and copies the kernel and applications into the FAT image. Its Linux workflow mounts the image and requires root privileges.
- [c_src/build-c-linux.sh](c_src/build-c-linux.sh) builds only the C examples and copies their `.BIN` files into `programs/`; it does not build the kernel or floppy image.
- [build-gmu-linux.sh](build-gmu-linux.sh) runs the C build and base OS build, then adds the GMU identity text file and produces `disk_images/gmuos.flp`.
- [README.md](README.md) shows the QEMU launch command.

A useful mental model is: assembly source makes the boot sector, assembly kernel and system API; the C toolchain makes ordinary application binaries; the image build puts those binaries and data files onto a FAT12 floppy that the bootloader can read.

## Project Hierarchy

```text
GMU-OS/
|-- source/
|   |-- bootload/
|   |   |-- bootload.asm       BIOS boot sector; finds and loads KERNEL.BIN
|   |   `-- bootload.bin       Existing assembled 512-byte boot sector
|   |-- kernel.asm             Kernel entry, API vectors, startup, menus, includes
|   |-- kernel.bin             Existing assembled flat kernel artifact
|   `-- features/              Kernel routines included into kernel.asm
|       |-- cli.asm            Command-line interface and built-in commands
|       |-- disk.asm           Disk and file operations
|       |-- keyboard.asm       Keyboard-related routines
|       |-- math.asm           Numeric/math routines
|       |-- misc.asm           Miscellaneous kernel routines
|       |-- ports.asm          Hardware port I/O helpers
|       |-- screen.asm         Text screen and display routines
|       |-- sound.asm          Speaker/sound routines
|       |-- string.asm         String helpers
|       `-- basic.asm          BASIC interpreter
|-- programs/                  Assembly and BASIC applications/data copied into image
|-- c_src/
|   |-- examples/              C application source
|   |-- include/gmuos.h        C entry bridge and selected API wrappers
|   |-- gmu16.ld               Links C binaries at offset 0x8000
|   |-- build-c-linux.sh       Builds C examples only
|   |-- build/                 Generated C objects and binaries
|   `-- prebuilt/              Supplied prebuilt C binary
|-- disk_images/               FAT12 floppy images and bootable ISO
|-- gmu_docs/                  GMU architecture, C guide, OS info, study plan
|-- doc/                        Upstream MikeOS handbook, history, credits, license
|-- assets/                     Project screenshots
|-- upstream_original/           Preserved original upstream disk image
|-- build-linux.sh               Base NASM/image build workflow
|-- build-gmu-linux.sh           GMU C + OS image workflow
|-- build-macos.sh               macOS build workflow
|-- build-openbsd.sh             OpenBSD build workflow
|-- buildwin.bat                 Windows build workflow
|-- build-gmu-win.bat            GMU Windows build workflow
`-- test-linux.sh                Linux test/launch helper
```

`kernel.asm` uses NASM `%INCLUDE` statements to assemble the routines in `source/features/` into the same flat `KERNEL.BIN`. These are source modules, not separately loaded kernel drivers. The shell and BASIC interpreter are therefore part of the kernel binary.

## Common Assembly Instructions in This Project

Assembly instructions are operations executed by the CPU. The examples below describe common uses in this codebase; register width depends on the operand and current code mode.

| Instruction | What it does | Typical use here |
|---|---|---|
| `MOV` | Copies a value from a register/memory/immediate into another destination. It does not copy memory-to-memory directly. | Set segment registers, pass string addresses and load constants. |
| `LEA` | Calculates an effective address and puts that address in a register; it does not read the memory at that address. | Build pointers to buffers/fields. |
| `ADD`, `SUB` | Add or subtract operands; update CPU flags. | Advance buffer pointers or adjust lengths/addresses. |
| `INC`, `DEC` | Increase or decrease an operand by one. | Count loop entries or bytes. |
| `CMP` | Subtracts for flag-setting only; does not store the result. | Compare command strings, counters, and end markers. |
| `TEST` | Performs a bitwise AND for flags only; does not store the result. | Check attribute bits or flags. |
| `JMP` | Unconditionally changes the instruction address. | Continue a loop or move to a handler. |
| `JE` / `JZ`, `JNE` / `JNZ`, `JC`, `JNC`, `JB`, `JAE` | Conditional jumps based on flags from a prior operation. `JE` and `JZ` are synonyms; `JB` means below in unsigned comparisons. | Branch after `CMP`, `TEST`, or a BIOS call. `JC` checks the carry flag, commonly used for BIOS/API success or error. |
| `CALL`, `RET` | `CALL` saves a return address and jumps to a routine; `RET` returns to it. | Kernel routines and running an application at `0x8000`. |
| `PUSH`, `POP` | Save/restore a value on the stack. | Preserve values across calls or temporarily save registers. |
| `PUSHA`, `POPA` | Save/restore the general-purpose 16-bit registers on a 386+. | Protect caller registers around routines. |
| `INT` | Invokes an interrupt handler; in real mode this commonly enters BIOS services. | `INT 13h` disk, `INT 10h` screen, `INT 16h` keyboard. |
| `LODSB`, `STOSB` | Load/store one byte using `DS:SI` or `ES:DI`, then move the pointer according to the direction flag. | Process strings and clear/fill buffers. |
| `REP` | Repeats a string instruction while decrementing `CX` (or `ECX` in operand-size cases). | Copy/compare/clear a known number of bytes. `CLD` makes string pointers advance. |
| `LOOP` | Decrements `CX` and jumps while it is not zero. | Small counted loops. |
| `XOR` | Bitwise exclusive OR; `XOR reg,reg` is a common way to clear a register. | Zero registers and perform bit operations. |
| `AND`, `OR` | Bitwise operations, often used to mask or test fields. | Extract FAT entries and test file attributes. |
| `SHL`, `SHR` | Shift bits left or right. | Extract packed date/time values or FAT12 cluster bits. |
| `MUL`, `DIV` | Unsigned multiply/divide using implicit registers such as `AX`, `DX:AX`. | Convert values and calculate disk coordinates. |
| `CLI`, `STI` | Disable/enable maskable hardware interrupts. | Protect stack/segment changes during startup. |
| `CLD` | Clear the direction flag so string operations advance. | Establish the expected direction for `REP` and `LODSB` operations. |
| `IN`, `OUT` | Read from/write to an x86 hardware I/O port. | Low-level hardware port routines in `source/features/ports.asm`. |

A useful reading habit is to follow the flags: for example, `CMP AX, 0` sets flags, and the next `JE`/`JNE` decides which path runs. Likewise, BIOS calls often return status in the carry flag, so `JC error_handler` means “branch if the BIOS reported an error.”

## Notes on Measurements

The byte counts above were read from files and from the existing FAT12 image; no build was run to produce this guide. A rebuilt image may differ, especially after source changes. The OS has fixed layout limits rather than a runtime RAM meter, so the RAM section reports addresses and reserved regions rather than claiming a changing live-usage figure.

## Command-Line Interface: `source/features/cli.asm`

The CLI code is part of the kernel, because `source/kernel.asm` includes `features/cli.asm` when assembling `KERNEL.BIN`. The kernel calls `os_command_line` when the user chooses the command-line option. When the user exits the CLI, `os_command_line` returns to the kernel, which displays the menu/CLI choice again.

### Input and Dispatch Flow

For each command, the shell follows this path:

1. Clears the command-name buffer, prints the prompt, and reads up to 64 characters into `input`.
2. Removes trailing spaces and repeats the prompt if the line is empty.
3. Uses `os_string_tokenize` to split the first space-delimited word from the remaining arguments. It saves the argument pointer in `param_list` and copies the command name into `command`.
4. Uppercases `input` so built-in commands are case-insensitive. Filenames and arguments remain available in their separate buffers for command handlers.
5. Checks for a command-specific help suffix, then compares the command name against built-in command strings.
6. If no built-in command matches, checks whether the command names a `.BIN` or `.BAS` program (or tries those extensions when none was provided). Unsupported names print `No such command or program`.

In the current implementation, the help suffix must be attached directly to the command, with no intervening space: `DIR/?` works, while `DIR /?` is parsed as a normal `DIR` command with an argument. The CLI removes the final `/?`, compares the remaining name against the supported commands, and prints the corresponding help string. An unknown `name/?` gets the normal invalid-command response. The help strings are static data near the bottom of `cli.asm` and show one example each.

### Built-In Commands

| Command | What its handler does |
|---|---|
| `DIR` | Calls `os_get_file_list` and prints the resulting filenames in columns. |
| `LS` | Reads the FAT root directory and prints detailed entries in pages, waiting for a key between pages. This is not an alias for `DIR`; it uses a different listing routine. |
| `COPY source destination` | Loads the source and writes a new destination; it refuses to overwrite an existing destination. |
| `REN old-name new-name` | Renames a file after checking that the destination name is not already in use. |
| `DEL filename` | Removes a file and reports success or failure. |
| `CAT filename` | Loads a file and writes its bytes to the text display. |
| `SIZE filename` | Gets and displays the file size in bytes. |
| `CLS` | Clears the display. |
| `HELP` | Prints the command summary table shown at shell startup. |
| `ABOUT`, `PBL` | Print the GMU-OS welcome/about text or project-based-learning information, respectively. |
| `TIME`, `DATE` | Print the current time/date. `DATE` can also accept `dd/mm/yyyy`; the current source checks whether the year is divisible by four and reports leap year or not. |
| `VER` | Prints the GMU-OS version string. |
| `EXIT` | Returns from the CLI routine to the kernel. |

Examples include `COPY SOURCE.TXT DEST.TXT`, `REN OLD.TXT NEW.TXT`, `DEL OLD.TXT`, and `CAT README.TXT`. Commands that need filenames print a missing-filename message when the required argument is absent. The shell's help text is descriptive, but handlers still determine the actual validation and error behavior.

### How the CLI Uses the Kernel

The CLI is not a separate program. It calls kernel routines directly because its assembled code shares the kernel's segment and fixed API. Its command path uses string services such as `os_string_chomp`, `os_string_tokenize`, `os_string_copy`, `os_string_uppercase`, `os_string_compare`, and `os_string_parse`; file commands call routines such as `os_file_exists`, `os_load_file`, `os_write_file`, `os_remove_file`, `os_rename_file`, and `os_get_file_size`. Printing, cursor positioning, keyboard input and time/date retrieval also go through kernel routines or BIOS services.

Each handler either jumps back to the `get_cmd` loop to accept another line, or, for `EXIT`, returns to the kernel caller. If the command is an external `.BIN`, the kernel loads it at offset `0x8000`, calls it, and resumes the shell after that program returns. A `.BAS` file is loaded to the same program area and run by the kernel's BASIC interpreter. Thus the command shell is one kernel interface into the same single-task execution flow described above.
