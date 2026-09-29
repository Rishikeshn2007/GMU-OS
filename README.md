# GMU-OS
qemu-system-i386 \
  -audiodev pipewire,id=spk \
  -machine pc,pcspk-audiodev=spk \
  -fda disk_images/gmuos.flp