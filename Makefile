# qemu-system-x86_64 build/nomados.raw -m 512M
SHELL := /bin/bash

build/nomados.raw: build/dep/linux/arch/x86_64/boot/bzImage build/initramfs.cpio
	dd if=/dev/zero of=build/nomados.raw bs=1M count=128
	mkfs -t fat build/nomados.raw
	syslinux build/nomados.raw
	mmd -i build/nomados.raw ::syslinux
	mcopy -i build/nomados.raw build/dep/linux/arch/x86_64/boot/bzImage ::syslinux/bzImage
	mcopy -i build/nomados.raw build/initramfs.cpio ::syslinux/initramfs.cpio
	mcopy -i build/nomados.raw config/syslinux.cfg ::syslinux/syslinux.cfg

build/initramfs.cpio: build/dep/linux/arch/x86_64/boot/bzImage build/dep/busybox/busybox build/dep/sdhcp/sdhcp build/dep/nomad/bin/nomad
	make -C build/dep/busybox CONFIG_STATIC=y CONFIG_PREFIX=$$PWD/build/initramfs install
	make -C build/dep/linux INSTALL_MOD_PATH=$$PWD/build/initramfs modules_install
	cp helpers/init build/initramfs/init
	cp build/dep/sdhcp/sdhcp build/initramfs/sbin/sdhcp
	cp build/dep/nomad/bin/nomad build/initramfs/usr/bin/nomad
	cp -r config/etc build/initramfs/etc
	cd build/initramfs \
	 && mkdir -p {dev,proc,sys,tmp} \
	 && find . | cpio -o -H newc | zstd > ../initramfs.cpio

build/dep/linux/arch/x86_64/boot/bzImage:
	-git clone --depth 1 --branch v6.8.2 https://github.com/gregkh/linux.git build/dep/linux
	-git clone --depth 1 --branch 6.8.2-1420 https://github.com/clearlinux-pkgs/linux.git build/dep/clearlinux-linux
	cd build/dep/linux \
	   && git apply ../clearlinux-linux/0101-i8042-decrease-debug-message-level-to-info.patch \
	    ../clearlinux-linux/0102-increase-the-ext4-default-commit-age.patch \
	    ../clearlinux-linux/0108-smpboot-reuse-timer-calibration.patch \
	    ../clearlinux-linux/0112-init-wait-for-partition-and-retry-scan.patch \
	    ../clearlinux-linux/0114-add-boot-option-to-allow-unsigned-modules.patch \
	    ../clearlinux-linux/0115-enable-stateless-firmware-loading.patch \
	    ../clearlinux-linux/0116-migrate-some-systemd-defaults-to-the-kernel-defaults.patch \
	    ../clearlinux-linux/0117-xattr-allow-setting-user.-attributes-on-symlinks-by-.patch \
	    ../clearlinux-linux/0120-do-accept-in-LIFO-order-for-cache-efficiency.patch \
	    ../clearlinux-linux/0121-locking-rwsem-spin-faster.patch \
	    ../clearlinux-linux/0122-ata-libahci-ignore-staggered-spin-up.patch \
	    ../clearlinux-linux/0123-print-CPU-that-faults.patch \
	    ../clearlinux-linux/0125-nvme-workaround.patch \
	    ../clearlinux-linux/0126-don-t-report-an-error-if-PowerClamp-run-on-other-CPU.patch \
	    ../clearlinux-linux/0127-lib-raid6-add-patch.patch \
	    ../clearlinux-linux/0130-itmt2-ADL-fixes.patch \
	    ../clearlinux-linux/0131-add-a-per-cpu-minimum-high-watermark-an-tune-batch-s.patch \
	    ../clearlinux-linux/0133-novector.patch \
	    ../clearlinux-linux/0134-md-raid6-algorithms-scale-test-duration-for-speedier.patch \
	    ../clearlinux-linux/0135-initcall-only-print-non-zero-initcall-debug-to-speed.patch \
	    ../clearlinux-linux/libsgrowdown.patch \
	    ../clearlinux-linux/epp-retune.patch \
	    ../clearlinux-linux/0002-sched-core-add-some-branch-hints-based-on-gcov-analy.patch \
	    ../clearlinux-linux/0136-crypto-kdf-make-the-module-init-call-a-late-init-cal.patch \
	    ../clearlinux-linux/ratelimit-sched-yield.patch \
	    ../clearlinux-linux/scale-net-alloc.patch \
	    ../clearlinux-linux/0158-clocksource-only-perform-extended-clocksource-checks.patch \
	    ../clearlinux-linux/better_idle_balance.patch \
	    ../clearlinux-linux/0162-extra-optmization-flags.patch \
	    ../clearlinux-linux/0163-thermal-intel-powerclamp-check-MWAIT-first-use-pr_wa.patch \
	    ../clearlinux-linux/0164-KVM-VMX-make-vmx-init-a-late-init-call-to-get-to-ini.patch \
	    ../clearlinux-linux/0166-sched-fair-remove-upper-limit-on-cpu-number.patch
	# cp build/dep/clearlinux-linux/config build/dep/linux/.config
	make -C build/dep/linux defconfig
	make -C build/dep/linux -j8

build/dep/sdhcp/sdhcp:
	-git clone --depth 1 git://git.2f30.org/sdhcp build/dep/sdhcp
	make -C build/dep/sdhcp
	cd build/dep/sdhcp && gcc -s -static -o sdhcp sdhcp.c util.a

build/dep/nomad/bin/nomad:
	-git clone --depth 1 --branch v1.7.6 https://github.com/hashicorp/nomad.git build/dep/nomad
	cd build/dep/nomad   ../../../helpers/nomad.patch
	make -C build/dep/nomad deps
	make -C build/dep/nomad dev

build/dep/busybox/busybox:
	-git clone --depth 1 -- https://git.busybox.net/busybox build/dep/busybox
	make -C build/dep/busybox defconfig
	make -C build/dep/busybox CONFIG_STATIC=y -j8

build/init:
	gcc src/nomadinit.c -static -o build/init

clean:
	rm -rf build/initramfs* build/nomados.raw