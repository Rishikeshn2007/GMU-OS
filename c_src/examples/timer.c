#include "gmuos.h"

#define MAX_TIMER_SECONDS 3599u
#define BIOS_TICKS_PER_DAY 0x1800B0UL
#define BIOS_TICK_FRACTION_SCALE 100000UL
#define BIOS_TICK_FRACTION 20648UL

static char timer_input[64];
static char number_text[5];

static gmu_u32 read_bios_ticks(void)
{
    gmu_u16 ax = 0;
    gmu_u16 high;
    gmu_u16 low;

    __asm__ volatile (
        "int $0x1A"
        : "+a" (ax), "=c" (high), "=d" (low)
        :
        : "cc", "memory"
    );

    return ((gmu_u32)high << 16) | low;
}

static gmu_u32 ticks_since(gmu_u32 start)
{
    gmu_u32 current = read_bios_ticks();

    if (current >= start)
        return current - start;

    return BIOS_TICKS_PER_DAY - start + current;
}

static void wait_until_elapsed(gmu_u32 start, gmu_u32 target)
{
    while (ticks_since(start) < target)
        __asm__ volatile ("hlt");
}

static int parse_duration(const char *input, gmu_u16 *seconds)
{
    gmu_u32 value = 0;
    gmu_u16 length = 0;

    while (input[length] != 0) {
        gmu_u8 character = (gmu_u8)input[length];
        gmu_u32 digit;

        if (character < '0' || character > '9')
            return 0;

        digit = character - '0';
        if (value > (MAX_TIMER_SECONDS - digit) / 10u)
            return 0;

        value = value * 10u + digit;
        length++;
    }

    if (length == 0 || length == 63 || value == 0)
        return 0;

    *seconds = (gmu_u16)value;
    return 1;
}

static gmu_u16 prompt_for_duration(void)
{
    gmu_u16 seconds;

    for (;;) {
        gmu_print(" Duration in seconds [1-3599]: ");
        gmu_input_string(timer_input, sizeof(timer_input));
        gmu_newline();

        if (parse_duration(timer_input, &seconds))
            return seconds;

        gmu_print(" Invalid time. Enter a whole number from 1 to 3599.");
        gmu_newline();
    }
}

static void print_number(gmu_u16 number)
{
    gmu_u16 position = sizeof(number_text) - 1;

    number_text[position] = 0;
    do {
        number_text[--position] = (char)('0' + number % 10);
        number /= 10;
    } while (number != 0);

    gmu_print(&number_text[position]);
}

static void run_timer(gmu_u16 seconds)
{
    gmu_u32 start = read_bios_ticks();
    gmu_u32 target_ticks = 0;
    gmu_u32 fractional_ticks = 0;
    gmu_u16 remaining;

    gmu_newline();
    gmu_print(" Starting countdown...");
    gmu_newline();
    gmu_newline();

    for (remaining = seconds; remaining > 0; remaining--) {
        gmu_print("   ");
        print_number(remaining);
        gmu_newline();

        target_ticks += 18;
        fractional_ticks += BIOS_TICK_FRACTION;
        if (fractional_ticks >= BIOS_TICK_FRACTION_SCALE) {
            target_ticks++;
            fractional_ticks -= BIOS_TICK_FRACTION_SCALE;
        }

        wait_until_elapsed(start, target_ticks);
    }

    gmu_newline();
    gmu_print("========================================");
    gmu_newline();
    gmu_print("              TIME UP!");
    gmu_newline();
    gmu_print("========================================");
    gmu_newline();
    gmu_speaker_tone(880);
    start = read_bios_ticks();
    wait_until_elapsed(start, 3);
    gmu_speaker_off();
}

__attribute__((used, noinline))
void gmu_main(void)
{
    gmu_u16 seconds;

    gmu_clear();
    gmu_print("========================================");
    gmu_newline();
    gmu_print("             GMU OS TIMER");
    gmu_newline();
    gmu_print("========================================");
    gmu_newline();
    gmu_newline();
    gmu_print(" Set a countdown from 1 to 3599 seconds.");
    gmu_newline();
    gmu_newline();
    seconds = prompt_for_duration();
    run_timer(seconds);
}

GMU_C_ENTRY(gmu_main)