#!/bin/bash

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
. ${SCRIPT_PATH}/../rpi-qemu/bootloaderlib.sh

check_root $0

SDCARD_IMG="sdcard.img"
SDCARD_SRC="../colibri-buildroot/output/sdcard"
FABUI_SRC="../colibri-fabui"
SDCARD_BOOT_PARTNUM=1

while (( "$#" )); do
	case $1 in
		-sdimg)
			shift
			SDCARD_IMG=$1
			;;
		-size)
			shift
			SDCARD_SIZE=$1
			;;
		-bootpart)
			shift
			SDCARD_BOOT_PARTNUM=$1
			;;
		-fabui_src)
			shift
			FABUI_SRC=$1
			;;
		*)
			echo "Unknown parameter \'$1\'"
			;;
	esac
	
	shift
done

# Get SDCard image info
sector_size=$( ${FDISK} -lu $SDCARD_IMG | grep "Units = sectors" | sed -e 's/.*=//;s/ bytes//')
#sector_size=$(fdisk -lu $SDCARD_IMG | grep "Units: sectors" | sed -e 's/.*=//;s/ bytes//')
start_sector=$( ${FDISK} -lu $SDCARD_IMG | grep "${SDCARD_IMG}${SDCARD_BOOT_PARTNUM}" | awk '{print $2}' )

LODEV=$(get_loopdev)
MNT=$(mktemp -d)

losetup $LODEV $SDCARD_IMG -o $(($start_sector * $sector_size))
mount $LODEV $MNT

rm -rf $MNT/*
# If there is colibri-buildroot around, copy bundles from there
if [ -e $SDCARD_SRC ]; then
	cp -LR $SDCARD_SRC/* $MNT
else
	echo "No colibri-buildroot found. Using only local ./sdcard content."
fi
cp -R sdcard/* $MNT
cp -LRf $FABUI_SRC/*.cb $MNT/bundles/
cp -LRf $FABUI_SRC/*.cb.md5sum $MNT/bundles/

sync

umount $MNT
rm -rf $MNT
losetup -d $LODEV
