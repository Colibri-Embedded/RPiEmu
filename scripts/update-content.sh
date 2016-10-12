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
SDCARD_CONTENT=boot
SDCARD_PARTNUM=1
#~ FABUI_SRC="../colibri-fabui"

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
		-colibri_sdcard)
			shift
			SDCARD_SRC=$1
			;;
		-sdpart)
			shift
			SDCARD_PARTNUM=$1
			;;
		-external_bundles_root)
			shift
			EXTERNAL_BUNDLES_ROOT=$1
			;;
		-content)
			shift
			SDCARD_CONTENT=$1
			;;
		-bundle)
			shift
			BUNDLE_PREFIX=$1
			;;
		*)
			echo "Unknown parameter \'$1\'"
			;;
	esac
	
	shift
done

# Get SDCard image info

if [ -f ${SDCARD_IMG} ]; then
	# Regular file sdcard image
	sector_size=$( ${FDISK} -lu $SDCARD_IMG | grep "Units = sectors" | sed -e 's/.*=//;s/ bytes//')
	#sector_size=$(fdisk -lu $SDCARD_IMG | grep "Units: sectors" | sed -e 's/.*=//;s/ bytes//')
	start_sector=$( ${FDISK} -lu $SDCARD_IMG | grep "${SDCARD_IMG}${SDCARD_PARTNUM}" | awk '{print $2}' )

	LODEV=$(get_loopdev)
	MNT=$(mktemp -d)

	losetup $LODEV $SDCARD_IMG -o $(($start_sector * $sector_size))
elif [ -b ${SDCARD_IMG} ]; then
	# Block device, real hw
	LODEV=${SDCARD_IMG}${SDCARD_PARTNUM}
	MNT=$(mktemp -d)
	
	# umount all SDCARD_IMG partitions
	for p in ls ${SDCARD_IMG}*; do
		umount -l ${p} &> /dev/null
	done
else
	echo "Error: unsupported sdcard image type"
	exit 1
fi

mount $LODEV $MNT

case $SDCARD_CONTENT in
	boot)
		# Remove everything
		rm -rf $MNT/*
		# If there is colibri-buildroot around, copy bundles from there
		if [ -e $SDCARD_SRC ]; then
			cp -LR $SDCARD_SRC/* $MNT
		else
			echo "No colibri-buildroot found. Using only local ./sdcard content."
		fi
		
		# Copy sdcard content from local ./sdcard directory
		# Only if it is for qemu
		if [ -f ${SDCARD_IMG} ]; then
			cp -R sdcard/* $MNT
		fi
		
		# Copy external bundles
		if [ -n "${EXTERNAL_BUNDLES_ROOT}" ]; then
			echo "EXTERNAL_BUNDLES_ROOT" ${EXTERNAL_BUNDLES_ROOT}
			cp -LRf $EXTERNAL_BUNDLES_ROOT/*.cb $MNT/
			cp -LRf $EXTERNAL_BUNDLES_ROOT/*.cb.md5sum $MNT/
		fi
		
		du -sh $MNT
		;;
	earlyboot)
		rm -rf $MNT/earlyboot
		cp -LR $SDCARD_SRC/earlyboot $MNT/
		
		rm -rf $MNT/initramfs.img
		cp -LR $SDCARD_SRC/initramfs.img $MNT/
		
		du -sh $MNT
		;;
	bundles)
		# Remove all bundles
		rm -rf $MNT/*
		# If there is colibri-buildroot around, copy bundles from there
		if [ -e $SDCARD_SRC/bundles ]; then
			cp -LR $SDCARD_SRC/bundles/* $MNT/
		else
			echo "No colibri-buildroot found. Using only local ./sdcard content."
		fi
		# Copy sdcard content from local ./sdcard directory
		# Only if it is for qemu
		if [ -f ${SDCARD_IMG} ]; then
			cp -R sdcard/bundles/* $MNT/
		fi
		
		# Copy external bundles
		if [ -n "${EXTERNAL_BUNDLES_ROOT}" ]; then
			cp -LRf $EXTERNAL_BUNDLES_ROOT/*.cb $MNT/
			cp -LRf $EXTERNAL_BUNDLES_ROOT/*.cb.md5sum $MNT/
		fi
		
		du -sh $MNT
		;;
	single-bundle)
		# Remove old bundle
		rm -rf $MNT/${BUNDLE_PREFIX}-*
		# Copy new FABUI bundle
		cp -R ${EXTERNAL_BUNDLES_ROOT}/${BUNDLE_PREFIX}-* $MNT
		
		;;
	fabui)
		# Remove old FABUI bundle
		rm -rf $MNT/*-fabui-*
		# Copy new FABUI bundle
		cp -R ${FABUI_SRC}/090-fabui-* $MNT
		
		;;
	enable-dbgconsole)
		sed -i $MNT/cmdline.txt -e 's/colibri.debug_console=0/colibri.debug_console=1/'
		sleep 1
		;;
	disable-dbgconsole)
		sed -i $MNT/cmdline.txt -e 's/colibri.debug_console=1/colibri.debug_console=0/'
		sleep 1
		;;
esac

sync

umount $MNT
rm -rf $MNT

if [ -f ${SDCARD_IMG} ]; then
	losetup -d $LODEV
fi
