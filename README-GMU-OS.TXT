==================================================================
GMU OS 0.1 -- C-Oriented Learning Edition
GM University, Davanagere, Karnataka, India
UE25CS2304 -- Operating System with Practice
==================================================================

PURPOSE
-------
GMU OS is a teaching-oriented derivative of MikeOS 4.7.0 prepared for
Operating Systems Project Based Learning at GM University.

The goal of this first edition is to keep the small and understandable
MikeOS boot/kernel environment while giving students a C-oriented path
for writing and extending applications. The lowest-level boot and core
OS routines remain in the original 16-bit x86 assembly because MikeOS
is architected around real-mode BIOS services and fixed assembly ABI
entry points. Student-facing extension work is moved toward C wherever
practical.

WHAT HAS BEEN CHANGED IN THIS FIRST PACKAGE
-------------------------------------------
1. Student-facing OS branding is changed to "GMU OS" in the kernel
   source and in the supplied bootable floppy image.
2. The original MikeOS 4.7.0 copyright and BSD-like license are retained.
3. A documented C application interface is added under c_src/.
4. A first C application, GMUINFO.C, is provided and a prebuilt
   GMUINFO.BIN is included.
5. The bootable image includes GMUINFO.BIN and GMU_OS.TXT.
6. Build helper scripts are provided for the GMU derivative workflow.
7. The untouched upstream kernel/image are preserved in upstream_original/
   for before/after comparison.

QUICK START
-----------
1. Boot disk_images/gmuos.flp in QEMU.
2. At the GMU OS interface, run GMUINFO.BIN from the program selector
   or command line.
3. Inspect c_src/examples/gmuinfo.c.
4. On a GCC/binutils environment that supports gcc -m16, run:
      ./c_src/build-c-linux.sh
5. Rebuild the base OS using the usual MikeOS NASM build process.

IMPORTANT
---------
This is a C-oriented derivative, not a claim that the original MikeOS
kernel has been rewritten completely in C. The bootloader and original
kernel remain low-level assembly infrastructure. The C layer is an
educational bridge that lets students work in the language they already
know while still executing inside a real bootable OS environment.

UPSTREAM ATTRIBUTION
--------------------
Base project: MikeOS 4.7.0
Copyright (C) 2006 - 2022 MikeOS Developers
Website: https://mikeos.sourceforge.net/
Original license: doc/LICENSE.TXT

The name MikeOS and contributor names are not used to endorse GMU OS.
==================================================================
