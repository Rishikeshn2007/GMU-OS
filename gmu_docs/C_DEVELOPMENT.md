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
