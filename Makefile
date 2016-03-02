TOP:=$(PWD)
J:=$(shell nproc)

ARCH=arm

all: binutils-gdb linux

SOURCES:=$(TOP)/sources
OBJECTS:=$(TOP)/objects
INSTALL:=$(TOP)/install

DIRS+=$(SOURCES)
DIRS+=$(OBJECTS)
DIRS+=$(INSTALL)

#### Binutils-gdb

BINUTILS_GIT=http://git.linaro.org/people/kieran.bingham/binutils-gdb
BINUTILS_BRANCH=lkd-thread-aware-c

BINUTILS_SRC=$(SOURCES)/binutils-gdb
BINUTILS_BLD=$(OBJECTS)/binutils-gdb

$(BINUTILS_SRC): | $(SOURCES)
	git clone $(BINUTILS_GIT) -b $(BINUTILS_BRANCH) $(BINUTILS_SRC)

DIRS+=$(BINUTILS_BLD)

$(BINUTILS_BLD)/Makefile binutils-configure: | $(BINUTILS_BLD) $(BINUTILS_SRC)
	cd $(BINUTILS_BLD) && \
	$(BINUTILS_SRC)/configure \
		--prefix=/usr \
		--target=$(ARCH)-linux \
		--program-prefix=$(ARCH)-linux- \
		--disable-nls \
		--enable-linux-kernel-aware \
		--enable-tui \
		--with-python=yes

binutils-gdb: | $(BINUTILS_BLD)/Makefile
	make -C $(BINUTILS_BLD)	-j $(J)
	make -C $(BINUTILS_BLD) install DESTDIR=$(INSTALL)

#### Linux

LINUX_GIT=http://git.linaro.org/people/kieran.bingham/linux.git
LINUX_BRANCH=gdb-scripts
LINUX_DEFCONFIG=multi_v7_defconfig
LINUX_CROSS_COMPILE=arm-linux-gnueabi-

LINUX_SRC=$(SOURCES)/linux
LINUX_BLD=$(OBJECTS)/linux

DIRS+=$(LINUX_BLD)

$(LINUX_SRC): | $(SOURCES)
	git clone $(LINUX_GIT) -b $(LINUX_BRANCH) $(LINUX_SRC)

LINUX_CMD=ARCH=$(ARCH) make -C $(LINUX_SRC) O=$(LINUX_BLD)

$(LINUX_BLD)/.config: | $(LINUX_SRC)
	$(LINUX_CMD) $(LINUX_DEFCONFIG)
	$(LINUX_SRC)/scripts/config --file $(LINUX_BLD)/.config \
		--enable DEBUG_INFO \
		--enable GDB_SCRIPTS
	yes "" | $(LINUX_CMD) oldconfig

linux: | $(LINUX_BLD)/.config
	ARCH=$(ARCH) make -C $(LINUX_SRC) O=$(LINUX_BLD) CROSS_COMPILE=$(LINUX_CROSS_COMPILE) -j $(J) zImage dtbs

#### QEmu

QEMU_GDB_TCP_PORT=32777

qemu-run: qemu-system-$(ARCH)

qemu-system-arm:
	qemu-system-arm \
		-kernel $(LINUX_BLD)/arch/arm/boot/zImage \
		-dtb $(LINUX_BLD)/arch/arm/boot/dts/vexpress-v2p-ca15-tc1.dtb \
		-append 'console=ttyAMA0,38400n8 ip=dhcp mem=1024M raid=noautodetect rootwait' \
		-M vexpress-a15 \
		-smp 2 \
		-m 1024 \
		-nographic \
		-gdb tcp::$(QEMU_GDB_TCP_PORT)

qemu-gdb: qemu-gdb-$(ARCH)

qemu-gdb-arm:
	$(INSTALL)/usr/bin/$(ARCH)-linux-gdb \
		$(LINUX_BLD)/vmlinux \
		-iex 'add-auto-load-safe-path $(LINUX_BLD)' \
		-ex 'target remote localhost:$(QEMU_GDB_TCP_PORT)'

#### Directories

dirs: $(DIRS)
$(DIRS):
	mkdir -p $@
