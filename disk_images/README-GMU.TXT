GMU OS disk image notes
=======================

gmuos.flp  - GMU OS 0.1 bootable floppy-style image. This is the
             recommended image for QEMU/USB testing.

mikeos.flp - Working image name retained because the original MikeOS
             build scripts expect it. In this GMU package it is also
             initialized with the GMU OS branded kernel and GMUINFO.BIN.

mikeos.iso and mikeos.dmg are upstream MikeOS 4.7.0 artifacts included
for reference. They become GMU-branded only after a successful rebuild
using an appropriate build workflow that regenerates them.

upstream_original/ contains the untouched upstream mikeos.flp and
kernel.bin for before/after comparison.
