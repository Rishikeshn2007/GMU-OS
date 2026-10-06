# Writing a C Program for GMU OS

## 1. Start from the supplied example

Open:

`c_src/examples/gmuinfo.c`

The program contains an ordinary C function:

```c
void gmu_main(void)
{
    gmu_clear();
    gmu_print("Hello from C");
    gmu_newline();
}

GMU_C_ENTRY(gmu_main)
```

`GMU_C_ENTRY()` creates the small low-level entry bridge required by the
MikeOS-compatible loader.

## 2. Available starter functions

From `c_src/include/gmuos.h`:

- `gmu_print(text)`
- `gmu_newline()`
- `gmu_clear()`
- `gmu_wait_key()`
- `gmu_get_boot_device()` returns the BIOS boot-drive ID (`0x00` for the
  first floppy, commonly `0x80` for the first hard disk).
- `gmu_get_memory_size()` returns conventional/base memory in KB using BIOS
  INT 12h.
- `gmu_get_video_mode()` returns the current BIOS video-mode number.
- `gmu_get_uptime()` returns elapsed BIOS timer ticks since OS startup
  (approximately 18.2 ticks per second).
- `gmu_get_api_version()` returns the API version reported by the running
  kernel.
- `gmu_bios_hardware_flags()` returns the raw equipment-list word from BIOS
  INT 11h. Common fields include floppy presence/count (bits 0 and 7-6),
  coprocessor (bit 1), pointing device (bit 2), serial-port count (bits 11-9),
  game port (bit 12), and parallel-port count (bits 15-14). BIOS/QEMU reports
  may vary; these are reported BIOS flags, not direct port probes.

Uptime accumulates the BIOS ticks observed by calls to `gmu_get_uptime()`.
Call it periodically if the program needs accurate elapsed time across
midnight; a gap of a full day or longer between calls cannot be distinguished
from fewer BIOS tick-counter rollovers.

These are intentionally few. Students can add wrappers for more MikeOS API
vectors as they learn how the kernel interface works.

## 3. Compile

On a GCC/binutils environment where `gcc -m16` is supported:

```bash
./c_src/build-c-linux.sh
```

The script compiles all `c_src/examples/*.c` files, links them as flat binaries
at `0x8000`, and copies the resulting `.BIN` files into `programs/`.

## 4. Rebuild the OS image

After the C binaries exist in `programs/`, use the normal GMU/MikeOS base OS
build workflow so the programs are copied into the floppy image.

## 5. Test in QEMU first

Never go directly to a physical USB after a source change. Boot the generated
image in QEMU, verify the application, and only then prepare physical media.
