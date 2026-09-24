#!/bin/sh
# GMU OS 0.1 convenience build for Linux / WSL-like GCC environments.
#
# 1) Build student-facing C applications using gcc -m16.
# 2) Invoke the original MikeOS NASM build to rebuild bootloader/kernel/image.
# 3) Add the GMU identity text file and create disk_images/gmuos.flp.
#
# Note: the upstream build-linux.sh requires root for loopback mounting.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$ROOT"
./c_src/build-c-linux.sh
./build-linux.sh

mkdir -p tmp-gmu-loop
mount -o loop -t vfat disk_images/mikeos.flp tmp-gmu-loop
cp gmu_docs/GMU_OS.TXT tmp-gmu-loop/GMU_OS.TXT
cp programs/*.BIN tmp-gmu-loop/
umount tmp-gmu-loop
rmdir tmp-gmu-loop
cp disk_images/mikeos.flp disk_images/gmuos.flp
printf '%s\n' '>>> GMU OS image ready: disk_images/gmuos.flp'
