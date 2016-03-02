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

$(LINUX_BLD)/.config: | $(LINUX_SRC)
	ARCH=$(ARCH) make -C $(LINUX_SRC) O=$(LINUX_BLD) $(LINUX_DEFCONFIG)

linux: | $(LINUX_BLD)/.config
	ARCH=$(ARCH) make -C $(LINUX_SRC) O=$(LINUX_BLD) CROSS_COMPILE=$(LINUX_CROSS_COMPILE) -j $(J) zImage

#### Directories

dirs: $(DIRS)
$(DIRS):
	mkdir -p $@
