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
    char time[16];
    char date[16];
    gmu_u16 api_version;

    gmu_clear();
    gmu_get_time(time);
    gmu_get_date(date);
    api_version = gmu_get_api_version();

    gmu_print("+--------------------------------------+");
    gmu_newline();
    gmu_print("|          GMU-OS  SYSINFO             |");
    gmu_newline();
    gmu_print("+--------------------------------------+");
    gmu_newline();
    gmu_print("| Runtime snapshot from the OS kernel  |");
    gmu_newline();
    gmu_print("+--------------------------------------+");
    gmu_newline();

    gmu_print(" SYSTEM");
    gmu_newline();
    gmu_print("  OS family       : GMU-OS / MikeOS");
    gmu_newline();
    gmu_print("  OS version      : 0.1 / 4.7.0");
    gmu_newline();
    gmu_print("  API version     : ");
    if (api_version == 18)
        gmu_print("18");
    else
        gmu_print("unknown");
    gmu_newline();
    gmu_print("  Current date    : ");
    gmu_print(date);
    gmu_newline();
    gmu_print("  Current time    : ");
    gmu_print(time);
    gmu_newline();
    gmu_print("  Program address : 0x8000");
    gmu_newline();

    gmu_print(" SERVICES USED");
    gmu_newline();
    gmu_print("  clear   0x0009   screen reset");
    gmu_newline();
    gmu_print("  time    0x0054   BIOS time -> buffer");
    gmu_newline();
    gmu_print("  date    0x005D   BIOS date -> buffer");
    gmu_newline();
    gmu_print("  version 0x0057   API version -> AL");
    gmu_newline();
    gmu_print("  wait    0x0012   pause before returning");
    gmu_newline();

    gmu_print("----------------------------------------");
    gmu_newline();
    gmu_print("  Student C code running inside GMU-OS");
    gmu_newline();
    gmu_print("Press any key to return...");
    gmu_newline();
    (void)gmu_wait_key();
}

GMU_C_ENTRY(gmu_main)
