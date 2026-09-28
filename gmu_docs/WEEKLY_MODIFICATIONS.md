# Suggested 10-Week GMU OS Modification Path

Each week should end with a build, QEMU boot, visible demonstration and short
before/after note.

| Week | Modification | Typical source area | Visible evidence |
|---|---|---|---|
| 1 | Change GMU OS identity / welcome text | `source/kernel.asm` | Boot screen changes |
| 2 | Change the command prompt | `source/features/cli.asm` | New prompt appears |
| 3 | Customize HELP text | `source/features/cli.asm` | HELP output changes |
| 4 | Add a new CLI command | `source/features/cli.asm` | New command works |
| 5 | Modify / extend a C application | `c_src/examples/*.c` | New C program runs |
| 6 | Build a richer SYSINFO utility in C | C source + API wrappers | System information screen |
| 7 | Enhance file listing / file counts | CLI/disk routines | DIR behavior changes |
| 8 | Add one API wrapper / kernel service | `gmuos.h` + kernel vector/routine | C app calls new service |
| 9 | Add one file-management behavior | `source/features/disk.asm` + C app | Observable file feature |
| 10 | Team-defined extension | chosen subsystem | Distinct team version |

The sequence is deliberately progressive: first modify visible strings, then
behavior, then C applications, and finally an OS service/subsystem.
