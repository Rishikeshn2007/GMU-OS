#!/bin/sh
# Build GMU OS C applications with a GCC toolchain that supports -m16.
# This builds ONLY the C applications. The base OS is still built by the
# original MikeOS NASM scripts.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CC=${CC:-gcc}
LD=${LD:-ld}
CFLAGS="-m16 -march=i386 -ffreestanding -fno-pic -fno-pie -fno-stack-protector -fno-asynchronous-unwind-tables -fomit-frame-pointer -Os -nostdlib -Wall -Wextra"
mkdir -p "$ROOT/c_src/build"
for src in "$ROOT"/c_src/examples/*.c; do
    name=$(basename "$src" .c)
    obj="$ROOT/c_src/build/$name.o"
    bin="$ROOT/c_src/build/$(echo "$name" | tr '[:lower:]' '[:upper:]').BIN"
    echo ">>> C compile: $(basename "$src")"
    "$CC" $CFLAGS -I"$ROOT/c_src/include" -c "$src" -o "$obj"
    "$LD" -m elf_i386 -T "$ROOT/c_src/gmu16.ld" -o "$bin" "$obj"
    cp "$bin" "$ROOT/programs/"
    echo "    created: $bin"
done
printf '%s\n' '>>> GMU OS C applications built and copied to programs/'
