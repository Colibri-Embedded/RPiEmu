#!/bin/bash

. ./rpi-qemu/bootloaderlib.sh

check_root $0

SDCARD_SIZE="4096"
SDCARD_IMG="sdcard.img"
SDCARD_BOOT_PARTNUM=1

if [ -f ${SDCARD_IMG} ]; then
	dd if=/dev/zero of=${SDCARD_IMG} notrunc bs=1M count=1	
else
	dd if=/dev/zero of=${SDCARD_IMG} bs=1M count=${SDCARD_SIZE}
fi

echo "
o
n
p
1


t
b
w

" | ${FDISK} ${SDCARD_IMG}

# Get SDCard image info
LODEV=$(get_loopdev)

v=($($FDISK -v))
v=${v[2]}
# TODO select right version

sector_size=$( ${FDISK} -lu $SDCARD_IMG | grep "Units = sectors" | sed -e 's/.*=//;s/ bytes//')
#sector_size=$( ${FDISK} -lu $SDCARD_IMG | grep "Units: sectors" | sed -e 's/.*=//;s/ bytes//')
start_sector=$( ${FDISK} -lu $SDCARD_IMG | grep "${SDCARD_IMG}${SDCARD_BOOT_PARTNUM}" | awk '{print $2}' )

losetup $LODEV $SDCARD_IMG -o $(($start_sector * $sector_size))

${MKVFAT} -n boot $LODEV

losetup -d $LODEV

sync

