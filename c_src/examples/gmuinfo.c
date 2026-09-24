/*
 * GMUINFO.C - first C application for GMU OS
 *
 * Demonstrates that a C program can be compiled as a flat 16-bit x86
 * executable, loaded by the original MikeOS-compatible program loader,
 * and call selected OS services through the small interface in gmuos.h.
 */
#include "gmuos.h"

__attribute__((used, noinline))
void gmu_main(void)
{
    gmu_clear();
    gmu_print("========================================");
    gmu_newline();
    gmu_print("               GMU OS");
    gmu_newline();
    gmu_print("  C-Oriented Learning Edition - 0.1");
    gmu_newline();
    gmu_print("  GM University, Davanagere, Karnataka");
    gmu_newline();
    gmu_print("  UE25CS2304 - Operating System PBL");
    gmu_newline();
    gmu_print("========================================");
    gmu_newline();
    gmu_newline();
    gmu_print("Base system : MikeOS 4.7.0");
    gmu_newline();
    gmu_print("USN : U25E01CS113");
    gmu_newline();
    gmu_print("Name: : Rishikesh N");
    gmu_newline();
    gmu_print("Program     : Written in C");
    gmu_newline();
    gmu_print("Load offset : 0x8000");
    gmu_newline();
    gmu_print("Press any key to return...");
    gmu_newline();
    (void)gmu_wait_key();
}

GMU_C_ENTRY(gmu_main)
