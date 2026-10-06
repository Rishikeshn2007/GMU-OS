# GMU-OS
qemu-system-i386 \
  -drive file=disk_images/gmuos.flp,format=raw,if=floppy \
  -audiodev pa,id=spk \
  -machine pc,pcspk-audiodev=spk

# References:
System call information:
/OS-PBL/doc/handbook-appdev-asm.html

Memory usage and commands:
/OS-PBL/doc/handbook-appdev-basic.html

Clear memory usage information:
/OS-PBL/doc/handbook-sysdev.html


