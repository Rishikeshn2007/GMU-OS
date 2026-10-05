# GMU-OS
qemu-system-i386 \
  -drive file=disk_images/gmuos.flp,format=raw,if=floppy \
  -audiodev pa,id=spk \
  -machine pc,pcspk-audiodev=spk
