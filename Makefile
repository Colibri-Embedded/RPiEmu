unexport CROSS_COMPILE
unexport ARCH
unexport CC
unexport CXX
unexport CPP
unexport CFLAGS
unexport CXXFLAGS
unexport GREP_OPTIONS
unexport TAR_OPTIONS
unexport CONFIG_SITE
unexport QMAKESPEC
unexport TERMINFO
unexport MACHINE

TOP_DIR			= $(PWD)
BUILD_DIR		= $(TOP_DIR)/build
MODULES_DIR		= $(BUILD_DIR)/modules
SDCARD_DIR		= $(TOP_DIR)/sdcard
BUNDLES_DIR		= $(TOP_DIR)/sdcard/bundles

BUILD_DIR_STAMP = $(BUILD_DIR)/.build_dir_stamp
SDCARD_DIR_STAMP = $(BUILD_DIR)/.sdcard_dir_stamp
COLIBRI_STAMP = $(BUILD_DIR)/.colibri_stamp
FABTOTUM_STAMP = $(BUILD_DIR)/.fabtotum_stamp
CONFIG_TOOLCHAIN_STAMP = $(BUILD_DIR)/.config_toolchain_stamp
TOOLCHAIN_STAMP = $(BUILD_DIR)/.toolchain_stamp
SOURCES_STAMP = $(BUILD_DIR)/.sources_stamp
EXTRACT_STAMP = $(BUILD_DIR)/.extracted_stamp
PATCH_STAMP = $(BUILD_DIR)/.patched_stamp
MODULES_STAMP = $(BUILD_DIR)/.modules_stamp

COLIBRI_BUILDROOT_ROOT 	?= ../colibri-buildroot
COLIBRI_FABTOTUM_ROOT 	?= ../colibri-fabtotum
DOWNLOAD_DIR			?= ../downloads

COLIBRI_HOST_DIR		= ../../$(COLIBRI_BUILDROOT_ROOT)/output/host

# xz, gzip, lzo, lz4, lzma
SQFS_COMPRESSION		= xz
SQFS_ARGS				= -comp $(SQFS_COMPRESSION) -b 512K -no-xattrs -noappend -all-root

KERNEL_VERSION			?= 3.16.y
KERNEL_SOURCE 			= http://github.com/raspberrypi/linux/archive/rpi-$(KERNEL_VERSION).tar.gz
KERNEL_BUILD_DIR		= $(BUILD_DIR)/linux-rpi-$(KERNEL_VERSION)
KERNEL_TAR				= $(DOWNLOAD_DIR)/linux-rpi-$(KERNEL_VERSION).tar.gz
KERNEL_PATCH_DIR		= $(COLIBRI_FABTOTUM_ROOT)/board/fabtotum/v1/$(KERNEL_VERSION)
KERNEL_PATCHES			= $(wildcard $(KERNEL_PATCH_DIR)/*.patch)
KERNEL_CONFIG			= $(COLIBRI_FABTOTUM_ROOT)/board/fabtotum/v1/linux-$(KERNEL_VERSION)-qemu.config
KERNEL_ARCH				= arm
KERNEL_IMAGE			= $(SDCARD_DIR)/kernel-qemu.img

# Quotes are needed for spaces and all in the original PATH content.
COLIBRI_PATH 	= "$(COLIBRI_HOST_DIR)/bin:$(COLIBRI_HOST_DIR)/sbin:$(COLIBRI_HOST_DIR)/usr/bin:$(COLIBRI_HOST_DIR)/usr/sbin:$(PATH)"
TARGET_MAKE_ENV = PATH=$(COLIBRI_PATH)
TARGET_CROSS	= arm-colibri-linux-gnueabihf-
HOSTCC = gcc
KERNEL_MAKE_FLAGS = \
	ARCH=$(KERNEL_ARCH) \
	INSTALL_MOD_PATH=$(LINUX_TARGET_DIR) \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	DEPMOD=$(COLIBRI_HOST_DIR)/sbin/depmod \
	USER_EXTRA_CFLAGS="-DCONFIG_LITTLE_ENDIAN"

all: $(BUNDLES_DIR)/002-kernel-modules-qemu.cb

$(BUILD_DIR_STAMP):
	mkdir -p $(BUILD_DIR)
	touch $@
	
$(SDCARD_DIR_STAMP):
	mkdir -p $(SDCARD_DIR)
	touch $@
	
$(KERNEL_TAR):
	wget $(KERNEL_SOURCE) -O $@
	touch $@

$(COLIBRI_STAMP):
	if [ ! -d $(COLIBRI_BUILDROOT_ROOT) ]; then \
	git clone https://github.com/Colibri-Embedded/colibri-buildroot.git $(COLIBRI_BUILDROOT_ROOT); \
	fi
	touch $@

$(FABTOTUM_STAMP):
	if [ ! -d $(COLIBRI_FABTOTUM_ROOT) ]; then \
	git clone https://github.com/FABtotum/colibri-fabtotum.git $(COLIBRI_FABTOTUM_ROOT); \
	fi
	touch $@

$(SOURCES_STAMP): $(BUILD_DIR_STAMP) $(COLIBRI_STAMP) $(FABTOTUM_STAMP) $(KERNEL_TAR)
	touch $@

$(CONFIG_TOOLCHAIN_STAMP): $(BUILD_DIR_STAMP) $(SOURCES_STAMP)
	make -C $(COLIBRI_BUILDROOT_ROOT) BR2_EXTERNAL=$(COLIBRI_FABTOTUM_ROOT) fabtotum_v1_defconfig
	touch $@

$(TOOLCHAIN_STAMP): $(CONFIG_TOOLCHAIN_STAMP)
	make -C $(COLIBRI_BUILDROOT_ROOT) toolchain
	touch $@

$(EXTRACT_STAMP): $(TOOLCHAIN_STAMP)
	tar xf $(KERNEL_TAR) -C $(BUILD_DIR)
	for pf in $(KERNEL_PATCHES); do \
		patch -d $(KERNEL_BUILD_DIR) -Np1 -i ../../$$pf; \
	done;
	cp $(KERNEL_CONFIG) $(KERNEL_BUILD_DIR)/.config
	touch $@

$(KERNEL_IMAGE): $(BUILD_DIR_STAMP) $(SDCARD_DIR_STAMP) $(EXTRACT_STAMP) $(KERNEL_BUILD_DIR)/.config
	$(TARGET_MAKE_ENV) $(KERNEL_MAKE_FLAGS) make -C $(KERNEL_BUILD_DIR)
	cp $(KERNEL_BUILD_DIR)/arch/$(KERNEL_ARCH)/boot/zImage $(KERNEL_IMAGE)
	
$(MODULES_STAMP): $(KERNEL_IMAGE)
	$(TARGET_MAKE_ENV) $(KERNEL_MAKE_FLAGS) make -C $(KERNEL_BUILD_DIR) \
		INSTALL_MOD_PATH=$(MODULES_DIR) \
		INSTALL_MOD_STRIP=1 \
		modules_install
	touch $@
		
$(BUNDLES_DIR)/002-kernel-modules-qemu.cb: $(MODULES_STAMP)
	mkdir -p $(BUNDLES_DIR)
	mksquashfs $(MODULES_DIR) $@ $(SQFS_ARGS)

menuconfig:
	$(TARGET_MAKE_ENV) $(KERNEL_MAKE_FLAGS) make -C $(KERNEL_BUILD_DIR) menuconfig

clean:
	rm -rf $(BUILD_DIR)
	
distclean: clean
	rm $(KERNEL_IMAGE)

help:
	@echo "Cleaning:"
	@echo "    clean                  - delete all files created by build"
	@echo ""
	@echo "Build:"
	@echo "    all                    - make world"
	@echo "    toolchain              - build toolchain"
