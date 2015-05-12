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

TOP_DIR			= .
BUILD_DIR		= $(TOP_DIR)/build
SDCARD_DIR		= $(TOP_DIR)/sdcard

BUILD_DIR_STAMP = $(BUILD_DIR)/.build_dir_stamp
SDCARD_DIR_STAMP = $(BUILD_DIR)/.sdcard_dir_stamp
COLIBRI_STAMP = $(BUILD_DIR)/.colibri_stamp
FABTOTUM_STAMP = $(BUILD_DIR)/.fabtotum_stamp
CONFIG_TOOLCHAIN_STAMP = $(BUILD_DIR)/.config_toolchain_stamp
TOOLCHAIN_STAMP = $(BUILD_DIR)/.toolchain_stamp
SOURCES_STAMP = $(BUILD_DIR)/.sources_stamp
EXTRACT_STAMP = $(BUILD_DIR)/.extracted_stamp
PATCH_STAMP = $(BUILD_DIR)/.patched_stamp

COLIBRI_BUILDROOT_ROOT 	?= ../colibri-buildroot
COLIBRI_FABTOTUM_ROOT 	?= ../colibri-fabtotum
DOWNLOAD_DIR			?= ../downloads

COLIBRI_HOST_DIR		= ../../$(COLIBRI_BUILDROOT_ROOT)/output/host

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
	DEPMOD=$(COLIBRI_HOST_DIR)/sbin/depmod

all:

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

kernel: $(BUILD_DIR_STAMP) $(SDCARD_DIR_STAMP) $(EXTRACT_STAMP)
	$(TARGET_MAKE_ENV) $(KERNEL_MAKE_FLAGS) make -C $(KERNEL_BUILD_DIR)
	cp $(KERNEL_BUILD_DIR)/arch/$(KERNEL_ARCH)/boot/zImage $(KERNEL_IMAGE)
	

clean:
	rm -rf $(BUILD_DIR)

help:
	@echo "Cleaning:"
	@echo "    clean                  - delete all files created by build"
	@echo ""
	@echo "Build:"
	@echo "    all                    - make world"
	@echo "    toolchain              - build toolchain"
