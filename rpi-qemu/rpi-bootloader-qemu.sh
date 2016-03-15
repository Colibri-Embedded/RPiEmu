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
SCRIPT_PATH="${BASH_SOURCE[0]}"
if ([ -h "${SCRIPT_PATH}" ]) then
	while([ -h "${SCRIPT_PATH}" ]) do
		SCRIPT_PATH=`readlink "${SCRIPT_PATH}"` 
	done
fi
pushd . > /dev/null
cd `dirname ${SCRIPT_PATH}` > /dev/null
SCRIPT_PATH=`pwd`;
popd  > /dev/null
########################################################################

. ${SCRIPT_PATH}/bootloaderlib.sh

#NETWORK="-net nic -net user,hostfwd=tcp::50022-:22,hostfwd=tcp::80-:80"
TAP_IFUP=${PWD}/qemu-ifup
TAP_IFDOWN=${PWD}/qemu-ifdown
TAP_DEV=colibri0
NETWORK="-net nic,model=smc91c111, -net tap,vlan=0,ifname=${TAP_DEV},script=${TAP_IFUP},downscript=${TAP_IFDOWN}"

#USBDEV="-usbdevice host:0bda:8176"

SDCARD_IMG="sdcard.img"
SDCARD_BOOT_PARTNUM=1
RAMSIZE=256
SERIAL=
MODEL_PID=

while (( "$#" )); do
	case $1 in
		-sdimg)
			shift
			SDCARD_IMG=$1
			;;
		-bootpart)
			shift
			SDCARD_BOOT_PARTNUM=$1
			;;
		-ramsize)
			shift
			RAMSIZE=$1
			;;
		-tcpserial)
			shift
			SERIAL="-serial tcp::$1,server"
			;;
		-modelpid)
			shift
			MODEL_PID=$1
			;;
		*)
			echo "Unknown parameter \'$1\'"
			;;
	esac
	
	shift
done

BOOT_DIR=$(mktemp -d)
QEMU_ARGS="${SERIAL} -hda ${SDCARD_IMG} -clock dynticks -no-reboot -cpu arm1176 -m ${RAMSIZE} -M versatilepb ${NETWORK} ${USBDEV}"

# Check if all the tools are available
check_tools

# Copy needed content from the SD card image to BOOT_DIR
copy_boot_from_sdimage $SDCARD_IMG $SDCARD_BOOT_PARTNUM $BOOT_DIR

# Start qemu
echo qemu-system-arm ${QEMU_ARGS} -append ${CMDLINE}
qemu-system-arm ${QEMU_ARGS} -append "${CMDLINE}" 

# Cleanup the boot directory
bootloader_cleanup $BOOT_DIR

# Stop the model simulator
kill -9 ${MODEL_PID}

