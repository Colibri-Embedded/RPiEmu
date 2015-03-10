#!/bin/bash

. ./rpi-qemu/bootloaderlib.sh

SDCARD_IMG="sdcard.img"
SDCARD_SRC="sdcard"
SDCARD_BOOT_PARTNUM=1
#INITRAMFS_IMG="initramfs.img"
#KERNEL="../packages/qemu-kernel/qemu/_install/zImage"

# Copy new kernel and initramfs images
#cp $KERNEL $SDCARD_SRC/kernel.img
#cp -L $INITRAMFS_IMG $SDCARD_SRC/initramfs

# Get SDCard image info
sector_size=$(fdisk -lu $SDCARD_IMG | grep "Units: sectors" | sed -e 's/.*=//;s/ bytes//')
start_sector=$(fdisk -lu $SDCARD_IMG | grep "${SDCARD_IMG}${SDCARD_BOOT_PARTNUM}" | awk '{print $2}' )

LODEV=$(get_loopdev)
MNT=$(mktemp -d)

losetup $LODEV $SDCARD_IMG -o $(($start_sector * $sector_size))
mount $LODEV $MNT

rm -rf $MNT/*
cp -LR $SDCARD_SRC/* $MNT

umount $MNT
rm -rf $MNT
losetup -d $LODEV

sync

