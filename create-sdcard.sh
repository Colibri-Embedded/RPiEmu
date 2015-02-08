#!/bin/bash

. ./rpi-qemu/bootloaderlib.sh

SDCARD_SIZE="4096"
SDCARD_IMG="sdcard.img"
SDCARD_BOOT_PARTNUM=1

FDISK=fdisk
MKVFAT=mkfs.vfat

dd if=/dev/zero of=${SDCARD_IMG} bs=1M count=${SDCARD_SIZE}

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

#sector_size=$( ${FDISK} -lu $SDCARD_IMG | grep "Units = sectors" | sed -e 's/.*=//;s/ bytes//')
sector_size=$( ${FDISK} -lu $SDCARD_IMG | grep "Units: sectors" | sed -e 's/.*=//;s/ bytes//')
start_sector=$( ${FDISK} -lu $SDCARD_IMG | grep "${SDCARD_IMG}${SDCARD_BOOT_PARTNUM}" | awk '{print $2}' )

losetup $LODEV $SDCARD_IMG -o $(($start_sector * $sector_size))

${MKVFAT} -n boot $LODEV

losetup -d $LODEV
