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

-include config.mk

TOP_DIR			?= ${CURDIR}
BUILD_DIR		?= $(TOP_DIR)/build
MODULES_DIR		?= $(BUILD_DIR)/modules
SDCARD_DIR		?= $(TOP_DIR)/sdcard
BUNDLES_DIR		?= $(TOP_DIR)/sdcard/bundles
SCRIPTS_DIR		?= $(TOP_DIR)/scripts

BUILD_DIR_STAMP = $(BUILD_DIR)/.build_dir_stamp
SDCARD_DIR_STAMP = $(BUILD_DIR)/.sdcard_dir_stamp
COLIBRI_STAMP = $(BUILD_DIR)/.colibri_stamp
CONFIG_TOOLCHAIN_STAMP = $(BUILD_DIR)/.config_toolchain_stamp
TOOLCHAIN_STAMP = $(BUILD_DIR)/.toolchain_stamp
SOURCES_STAMP = $(BUILD_DIR)/.sources_stamp
EXTRACT_STAMP = $(BUILD_DIR)/.extracted_stamp
PATCH_STAMP = $(BUILD_DIR)/.patched_stamp
MODULES_STAMP = $(BUILD_DIR)/.modules_stamp


.PHONY: all run sdcard check-root-permissions

all: $(BUNDLES_DIR)/002-kernel-modules-qemu.cb

COLIBRI_BUILDROOT_ROOT		?= $(TOP_DIR)/../colibri-buildroot
COLIBRI_BUILDROOT_OUTPUT	?= $(COLIBRI_BUILDROOT_ROOT)/output
COLIBRI_BUILDROOT_SDCARD	?= $(COLIBRI_BUILDROOT_OUTPUT)/sdcard
COLIBRI_BUILDROOT_DEFCONFIG	?=
COLIBRI_BUILDROOT_EXTERNAL	?=

-include $(EXTERNAL_MK)

DOWNLOAD_DIR				?= ../downloads

COLIBRI_HOST_DIR		= $(COLIBRI_BUILDROOT_OUTPUT)/host

# xz, gzip, lzo, lz4, lzma
SQFS_COMPRESSION		?= lzo
SQFS_ARGS				?= -comp $(SQFS_COMPRESSION) -b 512K -no-xattrs -noappend -all-root

KERNEL_VERSION			?= 4.1.y
KERNEL_SOURCE 			?= http://github.com/raspberrypi/linux/archive/rpi-$(KERNEL_VERSION).tar.gz
KERNEL_BUILD_DIR		?= $(BUILD_DIR)/linux-rpi-$(KERNEL_VERSION)
KERNEL_TAR				?= $(DOWNLOAD_DIR)/rpi-$(KERNEL_VERSION).tar.gz
KERNEL_PATCH_DIR		?= $(TOP_DIR)/kernel/$(KERNEL_VERSION)
KERNEL_PATCHES			?= $(wildcard $(KERNEL_PATCH_DIR)/*.patch)
KERNEL_CONFIG			?= $(TOP_DIR)/kernel/linux-$(KERNEL_VERSION)-qemu.config

KERNEL_ARCH				?= arm
KERNEL_IMAGE			?= $(SDCARD_DIR)/kernel-qemu.img

# Quotes are needed for spaces and all in the original PATH content.
COLIBRI_PATH 	= "$(COLIBRI_HOST_DIR)/bin:$(COLIBRI_HOST_DIR)/sbin:$(COLIBRI_HOST_DIR)/usr/bin:$(COLIBRI_HOST_DIR)/usr/sbin:$(PATH)"
TARGET_MAKE_ENV = PATH=$(COLIBRI_PATH)
TARGET_CROSS	?= arm-colibri-linux-gnueabihf-
HOSTCC ?= gcc
KERNEL_MAKE_FLAGS = \
	ARCH=$(KERNEL_ARCH) \
	INSTALL_MOD_PATH=$(LINUX_TARGET_DIR) \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	DEPMOD=$(COLIBRI_HOST_DIR)/sbin/depmod \
	USER_EXTRA_CFLAGS="-DCONFIG_LITTLE_ENDIAN"
	
# SDCARD parameters
SDCARD_SIZE				?= 	4096
SDCARD_IMG				?=	sdcard.img
SDCARD_LOG				?=	sdcard.log
#SDCARD_BOOT_PARTNUM		?=	1

PYTHON_BIN					?= python
RPIEMU_RUN					?= ./rpiemu.py

info:
	echo $(KERNEL_CONFIG)

check-root-permissions:
	@echo -n "Checking for root permissions..."
	@[ $(shell id -u) = 0 ] || exit 1
	@echo "YES"

linux-menuconfig: $(EXTRACT_STAMP)
	$(TARGET_MAKE_ENV) $(KERNEL_MAKE_FLAGS) make -C $(KERNEL_BUILD_DIR) menuconfig

linux-defconfig:  $(EXTRACT_STAMP)
	$(TARGET_MAKE_ENV) $(KERNEL_MAKE_FLAGS) make -C $(KERNEL_BUILD_DIR) $(DEFCONFIG)
	
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

$(SOURCES_STAMP): $(BUILD_DIR_STAMP) $(COLIBRI_STAMP) $(EXTERNAL_STAMPS) $(KERNEL_TAR)
	touch $@

$(CONFIG_TOOLCHAIN_STAMP): $(BUILD_DIR_STAMP) $(SOURCES_STAMP)
	make -C $(COLIBRI_BUILDROOT_ROOT) BR2_EXTERNAL=$(COLIBRI_BUILDROOT_EXTERNAL) $(COLIBRI_BUILDROOT_DEFCONFIG)
	touch $@

$(TOOLCHAIN_STAMP): $(CONFIG_TOOLCHAIN_STAMP)
	make -C $(COLIBRI_BUILDROOT_ROOT) toolchain
	touch $@

$(EXTRACT_STAMP): $(TOOLCHAIN_STAMP)
	tar xf $(KERNEL_TAR) -C $(BUILD_DIR)
	for pf in $(KERNEL_PATCHES); do \
		patch -d $(KERNEL_BUILD_DIR) -Np1 -i $$pf; \
	done;
	cp $(KERNEL_CONFIG) $(KERNEL_BUILD_DIR)/.config
	touch $@

$(KERNEL_IMAGE): $(BUILD_DIR_STAMP) $(SDCARD_DIR_STAMP) $(EXTRACT_STAMP) $(KERNEL_BUILD_DIR)/.config
	$(TARGET_MAKE_ENV) $(KERNEL_MAKE_FLAGS) make -j4 -C $(KERNEL_BUILD_DIR)
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
	rm -rf $(KERNEL_IMAGE)
	rm -rf $(BUNDLES_DIR)/002-kernel-modules-qemu.cb
	rm -rf $(SDCARD_IMG)
	
run: $(BUNDLES_DIR)/002-kernel-modules-qemu.cb
	sudo PYTHONPATH=$(TOP_DIR)/python:$(MODULES_DIR) $(PYTHON_BIN) $(RPIEMU_RUN) || exit 0

sdcard:
	sudo $(SCRIPTS_DIR)/create-sdcard.sh -sdimg $(SDCARD_IMG) -size $(SDCARD_SIZE)	&> $(SDCARD_LOG)
	sudo $(SCRIPTS_DIR)/update-content.sh -sdimg $(SDCARD_IMG) -sdpart 1 \
		-external_bundles_root "$(EXTERNAL_BUNDLES)" \
		-content boot \
		-colibri_sdcard $(COLIBRI_BUILDROOT_SDCARD)

update-boot:
	sudo $(SCRIPTS_DIR)/update-content.sh -sdimg $(SDCARD_IMG) -sdpart 1 \
	-content boot \
	-colibri_sdcard $(COLIBRI_BUILDROOT_SDCARD)

update-earlyboot:
	sudo $(SCRIPTS_DIR)/update-content.sh -sdimg $(SDCARD_IMG) -sdpart 1 \
	-content earlyboot \
	-colibri_sdcard $(COLIBRI_BUILDROOT_SDCARD)

update-bundles:
	sudo $(SCRIPTS_DIR)/update-content.sh -sdimg $(SDCARD_IMG) -sdpart 2 \
	-external_bundles_root "$(EXTERNAL_BUNDLES)" \
	-content bundles \
	-colibri_sdcard $(COLIBRI_BUILDROOT_SDCARD)
	
enable-dbgconsole:
	sudo $(SCRIPTS_DIR)/update-content.sh -sdimg $(SDCARD_IMG) -sdpart 1 \
	-content enable-dbgconsole
	
disable-dbgconsole:
	sudo $(SCRIPTS_DIR)/update-content.sh -sdimg $(SDCARD_IMG) -sdpart 1 \
	-content disable-dbgconsole

help:
	@echo "== Cleaning =="
	@echo "  clean                  - Delete all temporary build files"
	@echo "  distclean              - Delete all files created by build (kenrel, modules, bundles)"
	@echo ""
	@echo "== Build =="
	@echo "  all                    - Make world"
	@echo "  + KERNEL_VERSION       - Kernel version (default: " $(KERNEL_VERSION) ")"
	@echo ""
	@echo "  menuconfig             - Start kernel menuconfig"
	@echo ""
	@echo "== Emulator =="
	@echo "  run                    - Run RPiEmu"
	@echo ""
	@echo "== SDcard =="
	@echo "  sdcard                 - Create/repartition sdcard image and copy the content to boot partition."
	@echo "                           Warning: This will erase the content of existing sdcard image."
	@echo "  + SDCARD_IMG           - sdcard image file (default: sdcard.img)"
	@echo "  + SDCARD_SIZE          - sdcard size in MB (default: 4096)" 
	@echo ""
	@echo "  update-boot            - Update content of 'boot' partition."
	@echo "                           This will overwrite all configuration files and initiate"
	@echo "                           firstboot procedures on the next boot."
	@echo "  update-earlyboot       - Update earlyboot files."
	@echo "  update-bundles         - Update bundle files on 'bundles' partition."
	@echo "  "
	@echo "  enable-dbgconsole      - Enable earlyboot debug console. "
	@echo "  disable-dbgconsole     - Disable earlyboot debug console. "
	@echo ""
	@echo "  example:"
	@echo "    make sdcard SDCARD_SIZE=8096"
