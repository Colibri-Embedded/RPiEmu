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

SDCARD_SIZE="4096"
SDCARD_IMG="sdcard.img"
SDCARD_PARTNUM=1

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
		-sdpart)
			shift
			SDCARD_PARTNUM=$1
			;;
		*)
			echo "Unknown parameter \'$1\'"
			;;
	esac
	
	shift
done

if [ -e ${SDCARD_IMG} ]; then
	# real hw, partitions have probably been mounted
	if [ -b ${SCARD_IMG} ]; then
		# umount all SDCARD_IMG partitions
		for p in ls ${SDCARD_IMG}*; do
			umount -l ${p} &> /dev/null
		done
	else
		# sdcard image file, just destroy MBR
		dd if=/dev/zero of=${SDCARD_IMG} conv=notrunc bs=1M count=1	
	fi
	
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
if [ -f ${SDCARD_IMG} ]; then
	# regular file, sdcard image file
	LODEV=$(get_loopdev)
elif [ -b ${SDCARD_IMG} ]; then
	# block device, real hw
	LODEV=${SDCARD_IMG}${SDCARD_PARTNUM}
fi

v=($($FDISK -v))
v=${v[2]}
# TODO select right version

if [ -f ${SDCARD_IMG} ]; then
	sector_size=$( ${FDISK} -lu $SDCARD_IMG | grep "Units = sectors" | sed -e 's/.*=//;s/ bytes//')
	#sector_size=$( ${FDISK} -lu $SDCARD_IMG | grep "Units: sectors" | sed -e 's/.*=//;s/ bytes//')
	start_sector=$( ${FDISK} -lu $SDCARD_IMG | grep "${SDCARD_IMG}${SDCARD_PARTNUM}" | awk '{print $2}' )

	losetup $LODEV $SDCARD_IMG -o $(($start_sector * $sector_size))
fi

${MKVFAT} -n BOOT $LODEV

if [ -f ${SDCARD_IMG} ]; then
	losetup -d $LODEV
fi

sync

