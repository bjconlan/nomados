# qemu-system-x86_64 build/nomados.raw -m 512M
SHELL := /bin/bash

build/nomados.raw: build/dep/linux/arch/x86_64/boot/bzImage build/initramfs.cpio
	dd if=/dev/zero of=build/nomados.raw bs=1M count=64
	mkfs -t fat build/nomados.raw
	syslinux build/nomados.raw
	mmd -i build/nomados.raw ::syslinux
	mcopy -i build/nomados.raw build/dep/linux/arch/x86_64/boot/bzImage ::syslinux/bzImage
	mcopy -i build/nomados.raw build/initramfs.cpio ::syslinux/initramfs.cpio
	mcopy -i build/nomados.raw config/syslinux.cfg ::syslinux/syslinux.cfg

build/initramfs.cpio: build/dep/busybox/busybox build/dep/sdhcp/sdhcp build/dep/nomad/bin/nomad
	make -C build/dep/busybox CONFIG_STATIC=y CONFIG_PREFIX=$$PWD/build/initramfs install
	mkdir -p build/initramfs
	cp helpers/init build/initramfs/init
	cp build/dep/sdhcp/sdhcp build/initramfs/sbin/sdhcp
	cp build/dep/nomad/bin/nomad build/initramfs/usr/bin/nomad
	cp -r config/etc build/initramfs/etc
	cd build/initramfs \
	 && mkdir -p {dev,proc,sys,tmp} \
	 && find . | cpio -o -H newc | gzip > ../initramfs.cpio

build/dep/linux/arch/x86_64/boot/bzImage:
	-git clone --depth 1 --branch v6.8 https://github.com/torvalds/linux.git build/dep/linux
	make -C build/dep/linux defconfig
	make -C build/dep/linux -j8

build/dep/sdhcp/sdhcp:
	-git clone --depth 1 git://git.2f30.org/sdhcp build/dep/sdhcp
	make -C build/dep/sdhcp
	cd build/dep/sdhcp && gcc -s -static -o sdhcp sdhcp.c util.a

build/dep/nomad/bin/nomad:
	-git clone --depth 1 --branch v1.7.6 https://github.com/hashicorp/nomad.git build/dep/nomad
	cd build/dep/nomad && git apply ../../../helpers/nomad.patch
	make -C build/dep/nomad deps
	make -C build/dep/nomad dev

build/dep/busybox/busybox:
	-git clone --depth 1 -- https://git.busybox.net/busybox build/dep/busybox
	make -C build/dep/busybox defconfig
	make -C build/dep/busybox CONFIG_STATIC=y -j8

build/init:
	gcc src/nomadinit.c -static -o build/init

clean:
	rm -rf build/initramfs* nomados.raw