# qemu-system-x86_64 boot -nographic -serial mon:stdio
SHELL := /bin/bash

build/nomados.raw: build/dep/linux/arch/x86/boot/bzImage build/initramfs.cpio
	dd if=/dev/zero of=build/nomados.raw bs=1M count=64
	mkfs -t fat build/nomados.raw
	syslinux build/nomados.raw
	mmd -i build/nomados.raw ::syslinux
#	mmd -i build/nomados.raw ::etc ::etc/{nomad,dhcp}
#	mmd -i build/nomados.raw ::run ::run/{systemd,systemd/journal}
#	mmd -i build/nomados.raw ::sys ::sys/{fs,fs/selinux,kernel,kernel/security,/kernel/tracing}
#	mmd -i build/nomados.raw ::usr ::usr/{bin,lib,lib64,local,local/bin,sbin}
#	mmd -i build/nomados.raw ::var ::var/{lib,log,run,tmp} ::var/lib/{dhclient,nomad,nomad/data,nomad/data/{plugins,allocations}}
#	mmd -i build/nomados.raw ::{bin,sbin,lib,lib64}
#	mcopy -i build/nomados.raw build/init ::sbin
	mcopy -i build/nomados.raw build/dep/linux/arch/x86_64/boot/bzImage ::syslinux/bzImage
#	mcopy -i build/nomados.raw build/dep/nomad/bin/nomad ::usr/bin
#	mcopy -i build/nomados.raw build/dep/busybox/busybox ::usr/bin
#	mcopy -i build/nomados.raw build/dep/sdhcp/sdhcp ::sbin
	mcopy -i build/nomados.raw build/initramfs.cpio ::syslinux/initramfs.cpio
#	mcopy -i build/nomados.raw config/init.json ::etc/nomad
	mcopy -i build/nomados.raw config/syslinux.cfg ::syslinux/syslinux.cfg

build/initramfs.cpio: build/dep/busybox/busybox build/dep/sdhcp/sdhcp build/dep/nomad/bin/nomad
	make -C build/dep/busybox CONFIG_STATIC=y CONFIG_PREFIX=$$PWD/build/initramfs install
	mkdir -p build/initramfs
	cp init build/initramfs/init
	cp build/dep/sdhcp/sdhcp build/initramfs/sbin/sdhcp
	# cp build/dep/nomad/bin/nomad build/initramfs/usr/bin/nomad
	cp -r config/etc build/initramfs/etc
	cd build/initramfs \
	 && mkdir -p {dev,proc,sys,tmp} \
	 && find . | cpio -o -H newc | gzip > ../initramfs.cpio

# build/initramfs.cpio: build/dep/sdhcp/sdhcp build/dep/nomad/bin/nomad build/init
# 	mkdir -p build/dist
# 	cd build/dist \
# 	 && mkdir -p \
# 	  boot \
# 	  dev \
# 	  etc/{nomad,dhcp} \
# 	  proc/sys/fs/binfmt_misc \
# 	  run/systemd/journal \
# 	  sys/{fs/fuse/connections,kernel/{security,tracing}} \
# 	  tmp \
# 	  usr/{bin,lib,lib64,local/bin,sbin} \
# 	  var/{lib/{dhclient,nomad/data{plugins,allocations}},log,run,tmp}
# 	cd build/dist \
# 	 && ln -s usr/bin bin \
# 	 && ln -s usr/sbin sbin \
# 	 && ln -s usr/lib lib \
# 	 && ln -s usr/lib64 lib64
# 	cp build/dep/sdhcp/sdhcp build/dist/usr/sbin/
# 	cp build/dep/nomad/bin/nomad build/dist/usr/bin/
# 	cp build/init build/dist/usr/sbin/
# 	cp config/init.json build/dist/etc/nomad/
# 	cd build/dist \
# 	 && find . | cpio -o -H newc > ../initramfs.cpio

build/dep/linux/arch/x86/boot/bzImage:
	-git clone --depth 1 --branch v6.8 https://github.com/torvalds/linux.git build/dep/linux
#	make -C build/dep/linux allnoconfig
#	make -C build/dep/linux kvm_guest.config
	make -C build/dep/linux defconfig
	make -C build/dep/linux -j8

build/dep/sdhcp/sdhcp:
	-git clone --depth 1 git://git.2f30.org/sdhcp build/dep/sdhcp
	make -C build/dep/sdhcp
	cd build/dep/sdhcp && gcc -s -static -o sdhcp sdhcp.c util.a

build/dep/nomad/bin/nomad:
	-git clone --depth 1 --branch v1.7.6 https://github.com/hashicorp/nomad.git build/dep/nomad
	make -C build/dep/nomad deps
	make -C build/dep/nomad dev

build/dep/busybox/busybox:
	-git clone --depth 1 -- https://git.busybox.net/busybox build/dep/busybox
	make -C build/dep/busybox defconfig
	make -C build/dep/busybox CONFIG_STATIC=y -j8

build/init:
	gcc nomadinit.c -static -o build/init

