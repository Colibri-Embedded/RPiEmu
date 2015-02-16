#!/bin/bash
########################################################################
#
# RaspberryPi bootloader emulator library.
#
# Copyright (C) 2015 Daniel Kesler <kesler.daniel@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#    
########################################################################
## @file
## @author Daniel Kesler <kesler.daniel@gmail.com>
## @brief RaspberryPi bootloader emulator library.
## @copyright GPLv2
## @version 0.2
########################################################################

## @fn check_app()
## Check if an application is available.
## @return 0 if application is found, 1 otherwise
check_app() {
	$1 -h &> /dev/null
	RETR=$?
	if [ "x$RETR" == "x0" ]; then
		return 0
	else
		$1 --help &> /dev/null
		RETR=$?
		if [ "x$RETR" == "x0" ]; then
			return 0
		else
			return 1
		fi
	fi
}

## @fn check_tools()
## Check if all tools are available.
## @return 0 if all are found, 1 otherwise
check_tools() {
	TOOLS=(mkdir rm mount umount mktemp losetup fdisk iptables brctl ifconfig sysctl)
	err=no
	missing=()
	for tool in ${TOOLS[@]}; do
		check_app $tool
		if [ "$?" != "0" ]; then
			err=yes
			missing=(${missing[@]} $tool)
		fi
	done
	
	if [ "$err" == "no" ]; then
		echo "* All tools found."
		return 0
	else
		echo "* Some tools are missing: ${missing[@]}"
		exit 1
	fi
}

## @fn get_loopdev()
## Return a free loop device filename.
## @return free loop device file
get_loopdev() {
	for i in {0..10}; do
		DEV="/dev/loop$i"
		if [ -e $DEV ]; then
			if [ "$(file -s $DEV | sed -e 's/.*: //')" == "empty" ]; then
				echo $DEV
				return
			fi
		else
			echo $DEV
			return
		fi
	done
}

## @fn config_get_kernel()
## Extract the kernel= value from config.txt file.
## @param $1 config.txt file
## @return kernel value or if not found the default value 'kernel.img'
config_get_kernel() {
	kernel=$(cat $1 | grep "^kernel=" | sed -e 's/kernel=//')
	if [ "x$kernel" != "x" ]; then
		echo "$kernel"
	else
		echo "kernel.img"
	fi
}

## @fn config_get_initramfs()
## Extract the initramfs= value from config.txt file.
## @param $1 config.txt file
## @return initramfs value
config_get_initramfs() {
	initramfs=$(cat $1 | grep "^initramfs" | sed -e 's/initramfs //')
	if [ "x$initramfs" != "x" ]; then
		echo "$initramfs"
	else
		echo ""
	fi
}

## @fn copy_boot_from_sdimage()
## Copy boot partition content from sdimage to a temp folder so that is
## is accessible by Qemu.
## @param $1 SD card image file
## @param $2 SD partition number to copy data from
## @param $3 Boot directory to copy data to
copy_boot_from_sdimage() {
	LODEV=$(get_loopdev)
	MNT=$(mktemp -d)
	# Get SDCard image info
	sector_size=$(fdisk -lu $1 | grep "Units: sectors" | sed -e 's/.*=//;s/ bytes//')
	start_sector=$(fdisk -lu $1 | grep "${1}${2}" | awk '{print $2}' )
	
	# Create rpi-bootloader directory
	mkdir -p $3

	# Mount the sdcard first partition
	losetup $LODEV $1 -o $(($start_sector * $sector_size))
	mkdir -p $MNT
	mount $LODEV $MNT

	###################################
	# Parse the bootloader config.txt #
	###################################
	CONFIG_TXT="$MNT/config.txt"
	if [ -f "$MNT/config.txt.qemu" ]; then
		CONFIG_TXT="$MNT/config.txt.qemu"
	fi
	CMDLINE_TXT=$MNT/cmdline.txt
	if [ -f "$MNT/cmdline.txt.qemu" ]; then
		CONFIG_TXT="$MNT/cmdline.txt.qemu"
	fi
	
	CMDLINE=$(cat $CMDLINE_TXT)
	KERNEL=$(config_get_kernel $CONFIG_TXT)
	INITRD=$(config_get_initramfs $CONFIG_TXT)

	# Copy the kernel to the rpi-bootloader directory
	if [ "x$KERNEL" != "x" ]; then
		cp $MNT/$KERNEL $3
		QEMU_ARGS="${QEMU_ARGS} -kernel $BOOT_DIR/$KERNEL"
	fi

	# Copy the initramfs to the rpi-bootloader directory
	if [ "x$INITRD" != "x" ]; then
		cp $MNT/$INITRD $3
		QEMU_ARGS="${QEMU_ARGS} -initrd $BOOT_DIR/$INITRD"
	fi

	umount $MNT
	rm -rf $MNT
	losetup -d $LODEV
}

## @fn copy_to_sdimage()
## Copy files to sdimage boot partition.
copy_to_sdimage() {
	LODEV=$(get_loopdev)
	MNT=$(mktemp -d)
	# Get SDCard image info
	sector_size=$(fdisk -lu $SDCARD_IMG | grep "Units: sectors" | sed -e 's/.*=//;s/ bytes//')
	start_sector=$(fdisk -lu $SDCARD_IMG | grep "${SDCARD_IMG}${SDCARD_BOOT_PARTNUM}" | awk '{print $2}' )
	
	# Create rpi-bootloader directory
	mkdir -p $BOOT_DIR

	# Mount the sdcard first partition
	losetup $LODEV $SDCARD_IMG -o $(($start_sector * $sector_size))
	mkdir -p $MNT
	mount $LODEV $MNT

	cp -R $1/* $MNT

	umount $MNT
	rm -rf $MNT
	losetup -d $LODEV
}

## @fn bootloader_cleanup()
## Cleanup temp files.
## @param $1 Boot directory
bootloader_cleanup() {
	rm -rf $1
}
