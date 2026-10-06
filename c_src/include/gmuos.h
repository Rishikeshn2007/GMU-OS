/*
 * GMU OS - small C interface for the MikeOS 4.7.0 execution environment
 *
 * GMU modifications: 2026, GM University, Davanagere.
 * Base OS: MikeOS 4.7.0 (Copyright 2006-2022 MikeOS Developers).
 * The original MikeOS license is retained in doc/LICENSE.TXT.
 *
 * Why there is a tiny amount of inline assembly here:
 * MikeOS exposes kernel services at fixed 16-bit offsets. C code can use
 * those services, but a few machine instructions are required to place
 * arguments in the exact registers expected by the original ABI.
 * Student-facing applications can otherwise remain in C.
 */
#ifndef GMUOS_H
#define GMUOS_H

typedef unsigned char  gmu_u8;
typedef unsigned short gmu_u16;
typedef unsigned int   gmu_u32;

/* MikeOS/GMU OS API vector offsets (API v19). */
#define GMU_OS_PRINT_STRING   0x0003u
#define GMU_OS_CLEAR_SCREEN   0x0009u
#define GMU_OS_PRINT_NEWLINE  0x000Fu
#define GMU_OS_WAIT_FOR_KEY   0x0012u
#define GMU_OS_SPEAKER_TONE   0x001Bu
#define GMU_OS_SPEAKER_OFF    0x001Eu
#define GMU_OS_GET_API_VER    0x0057u
#define GMU_OS_GET_TIME_STR   0x0054u
#define GMU_OS_GET_DATE_STR   0x005Du
#define GMU_OS_INPUT_STRING   0x0036u
#define GMU_OS_GET_BOOT_DEVICE 0x00D5u
#define GMU_OS_GET_MEMORY_SIZE 0x00D8u
#define GMU_OS_GET_VIDEO_MODE  0x00DBu
#define GMU_OS_GET_UPTIME      0x00DEu
#define GMU_OS_BIOS_HARDWARE_FLAG 0x00E1u

/* Convert a linked program-data pointer to the 16-bit offset used inside
 * the common MikeOS/GMU OS segment. Stack pointers use a different segment. */
static inline gmu_u16 gmu_offset(const void *p)
{
    return (gmu_u16)((gmu_u32)p & 0xFFFFu);
}

static inline void gmu_print(const char *text)
{
    gmu_u16 off = gmu_offset(text);
    __asm__ volatile (
        "movw %0, %%si\n\t"
        "movw $0x0003, %%bx\n\t"
        "callw *%%bx"
        :
        : "rm" (off)
        : "ax", "bx", "cx", "dx", "si", "di", "cc", "memory"
    );
}

static inline void gmu_newline(void)
{
    __asm__ volatile (
        "movw $0x000f, %%bx\n\t"
        "callw *%%bx"
        : : : "ax", "bx", "cx", "dx", "si", "di", "cc", "memory"
    );
}

static inline void gmu_clear(void)
{
    __asm__ volatile (
        "movw $0x0009, %%bx\n\t"
        "callw *%%bx"
        : : : "ax", "bx", "cx", "dx", "si", "di", "cc", "memory"
    );
}

static inline gmu_u16 gmu_wait_key(void)
{
    gmu_u16 key;
    __asm__ volatile (
        "movw $0x0012, %%bx\n\t"
        "callw *%%bx"
        : "=a" (key)
        :
        : "bx", "cx", "dx", "si", "di", "cc", "memory"
    );
    return key;
}

static inline gmu_u8 gmu_get_api_version(void)
{
    gmu_u16 version;
    __asm__ volatile (
        "movw $0x0057, %%bx\n\t"
        "callw *%%bx"
        : "=a" (version)
        :
        : "bx", "cx", "dx", "si", "di", "cc", "memory"
    );
    return (gmu_u8)version;
}

static inline gmu_u8 gmu_get_boot_device(void)
{
    gmu_u16 device;
    __asm__ volatile (
        "movw $0x00D5, %%bx\n\t"
        "callw *%%bx"
        : "=a" (device)
        :
        : "bx", "cx", "dx", "si", "di", "cc", "memory"
    );
    return (gmu_u8)device;
}

static inline gmu_u16 gmu_get_memory_size(void)
{
    gmu_u16 memory_kb;
    __asm__ volatile (
        "movw $0x00D8, %%bx\n\t"
        "callw *%%bx"
        : "=a" (memory_kb)
        :
        : "bx", "cx", "dx", "si", "di", "cc", "memory"
    );
    return memory_kb;
}

static inline gmu_u8 gmu_get_video_mode(void)
{
    gmu_u16 mode;
    __asm__ volatile (
        "movw $0x00DB, %%bx\n\t"
        "callw *%%bx"
        : "=a" (mode)
        :
        : "bx", "cx", "dx", "si", "di", "cc", "memory"
    );
    return (gmu_u8)mode;
}

/* Approximately 18.2 BIOS timer ticks elapse per second. */
static inline gmu_u32 gmu_get_uptime(void)
{
    gmu_u32 ticks;
    __asm__ volatile (
        "movw $0x00DE, %%bx\n\t"
        "callw *%%bx"
        : "=a" (ticks)
        :
        : "bx", "cx", "dx", "si", "di", "cc", "memory"
    );
    return ticks;
}

/* BIOS INT 11h equipment-list word; see gmu_docs/C_DEVELOPMENT.md. */
static inline gmu_u16 gmu_bios_hardware_flags(void)
{
    gmu_u16 flags;
    __asm__ volatile (
        "movw $0x00E1, %%bx\n\t"
        "callw *%%bx"
        : "=a" (flags)
        :
        : "bx", "cx", "dx", "si", "di", "cc", "memory"
    );
    return flags;
}

static inline void gmu_input_string(char *buffer, gmu_u16 max_length)
{
    gmu_u16 offset = gmu_offset(buffer);
    __asm__ volatile (
        "movw %0, %%ax\n\t"
        "movw %1, %%bx\n\t"
        "movw $0x0036, %%di\n\t"
        "callw *%%di"
        :
        : "rm" (offset), "rm" (max_length)
        : "ax", "bx", "cx", "dx", "si", "di", "cc", "memory"
    );
}

static inline void gmu_speaker_tone(gmu_u16 frequency)
{
    __asm__ volatile (
        "movw $0x001B, %%di\n\t"
        "callw *%%di"
        :
        : "a" (frequency)
        : "bx", "cx", "dx", "si", "di", "cc", "memory"
    );
}

static inline void gmu_speaker_off(void)
{
    __asm__ volatile (
        "movw $0x001E, %%di\n\t"
        "callw *%%di"
        :
        :
        : "ax", "bx", "cx", "dx", "si", "di", "cc", "memory"
    );
}

/* C program entry helper.
 * MikeOS loads .BIN programs at offset 0x8000 and invokes them with a
 * 16-bit CALL. GCC -m16 generated C functions use a 32-bit stack model,
 * so this small naked entry stub initializes ESP, calls C main with a
 * 32-bit call, and returns to the OS with a 16-bit RET.
 */
#define GMU_C_ENTRY(main_function) \
    __attribute__((naked, section(".text.start"), used)) \
    void _start(void) { \
        __asm__ volatile ( \
            "movw %sp, %bx\n\t" \
            "movl $0x0000fff0, %esp\n\t" \
            "calll " #main_function "\n\t" \
            "movw %bx, %sp\n\t" \
            "retw\n\t" \
        ); \
    }

#endif /* GMUOS_H */
