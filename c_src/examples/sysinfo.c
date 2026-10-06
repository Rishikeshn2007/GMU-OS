#include "gmuos.h"

static const char hex_digits[] = "0123456789ABCDEF";
static char hex_output[3];
static char decimal_digits[10];
static char decimal_output[2];

static void print_hex8(gmu_u8 value)
{
    hex_output[0] = hex_digits[(value >> 4) & 0x0F];
    hex_output[1] = hex_digits[value & 0x0F];
    hex_output[2] = '\0';
    gmu_print(hex_output);
}

static void print_hex16(gmu_u16 value)
{
    print_hex8((gmu_u8)(value >> 8));
    print_hex8((gmu_u8)value);
}

static void print_hex32(gmu_u32 value)
{
    print_hex16((gmu_u16)(value >> 16));
    print_hex16((gmu_u16)value);
}

static void print_u16(gmu_u16 value)
{
    gmu_u8 count = 0;

    if (value == 0) {
        gmu_print("0");
        return;
    }

    while (value != 0) {
        decimal_digits[count++] = (char)('0' + (value % 10));
        value /= 10;
    }
    while (count != 0) {
        decimal_output[0] = decimal_digits[--count];
        decimal_output[1] = '\0';
        gmu_print(decimal_output);
    }
}

static gmu_u32 divide_u32_u16(gmu_u32 value, gmu_u16 divisor)
{
    gmu_u32 quotient = 0;
    gmu_u16 remainder = 0;
    gmu_u8 bit;

    for (bit = 0; bit < 32; ++bit) {
        remainder = (gmu_u16)((remainder << 1) | (value >> 31));
        value <<= 1;
        quotient <<= 1;
        if (remainder >= divisor) {
            remainder -= divisor;
            quotient |= 1;
        }
    }
    return quotient;
}

static void print_u32(gmu_u32 value)
{
    gmu_u8 count = 0;

    if (value == 0) {
        gmu_print("0");
        return;
    }

    while (value != 0) {
        gmu_u32 quotient = divide_u32_u16(value, 10);
        decimal_digits[count++] = (char)('0' + (value - quotient * 10));
        value = quotient;
    }
    while (count != 0) {
        decimal_output[0] = decimal_digits[--count];
        decimal_output[1] = '\0';
        gmu_print(decimal_output);
    }
}

static gmu_u32 bios_ticks_to_seconds(gmu_u32 ticks)
{
    gmu_u32 whole_seconds = divide_u32_u16(ticks, 182);
    gmu_u32 remaining_ticks = ticks - whole_seconds * 182;
    gmu_u32 fractional_seconds =
        divide_u32_u16(remaining_ticks * 10, 182);

    return whole_seconds * 10 + fractional_seconds;
}

__attribute__((used, noinline))
void gmu_main(void)
{
    gmu_u32 uptime_ticks;
    gmu_u16 flags = gmu_bios_hardware_flags();
    gmu_u8 serial_ports = (gmu_u8)((flags >> 9) & 0x07);
    gmu_u8 parallel_ports = (gmu_u8)((flags >> 14) & 0x03);
    gmu_u8 floppy_count = (flags & 0x01)
        ? (gmu_u8)(((flags >> 6) & 0x03) + 1)
        : 0;

    gmu_newline();
    gmu_print("GMU OS SYSTEM INFO");
    gmu_newline();
    gmu_print("------------------");
    gmu_newline();

    gmu_print("Boot drive BIOS ID: 0x");
    print_hex8(gmu_get_boot_device());
    gmu_newline();

    gmu_print("Conventional memory: ");
    print_u16(gmu_get_memory_size());
    gmu_print(" KB");
    gmu_newline();

    gmu_print("BIOS video mode: 0x");
    print_hex8(gmu_get_video_mode());
    gmu_newline();

    uptime_ticks = gmu_get_uptime();
    gmu_print("Uptime BIOS ticks: 0x");
    print_hex32(uptime_ticks);
    gmu_newline();
    gmu_print("Uptime approx: ");
    print_u32(bios_ticks_to_seconds(uptime_ticks));
    gmu_print(" seconds");
    gmu_newline();

    gmu_print("BIOS equipment flags: 0x");
    print_hex16(flags);
    gmu_newline();

    gmu_print("Reported floppy drives: ");
    print_u16(floppy_count);
    gmu_newline();

    gmu_print("Reported serial ports: ");
    print_u16(serial_ports);
    gmu_newline();

    gmu_print("Reported parallel ports: ");
    print_u16(parallel_ports);
    gmu_newline();

    gmu_print("Pointing device: ");
    gmu_print((flags & 0x0004) ? "yes" : "no");
    gmu_newline();
    gmu_print("Math coprocessor: ");
    gmu_print((flags & 0x0002) ? "yes" : "no");
    gmu_newline();

    gmu_print("MikeOS API version: ");
    print_u16(gmu_get_api_version());
    gmu_newline();
}

GMU_C_ENTRY(gmu_main)