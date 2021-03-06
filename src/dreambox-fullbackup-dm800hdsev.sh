#!/bin/sh
#

VERSION="Dreambox- 25/11/2016\ncreator of the script athoik (http://forums.openpli.org)\n"
DIRECTORY="$1"
START=$(date +%s)
DATE=`date +%Y%m%d_%H%M`
IMAGEVERSION=`date +%Y%m%d`

if [ -f /etc/issue ] ; then
	ISSUE=`cat /etc/issue | grep . | tail -n 1 ` 
	IMVER=${ISSUE%?????}
elif [ -f /etc/bhversion ] ; then
	ISSUE=`cat /etc/bhversion | grep . | tail -n 1 ` 
	IMVER=${ISSUE%?????}
elif [ -f /etc/vtiversion.info ] ; then
	ISSUE=`cat /etc/vtiversion.info | grep . | tail -n 1 ` 
	IMVER=${ISSUE%?????}
elif [ -f /etc/vtiversion.info ] ; then
	ISSUE=`cat /etc/vtiversion.info | grep . | tail -n 1 ` 
	IMVER=${ISSUE%?????}
elif [ -f /proc/stb/info/vumodel ] && [ -f /etc/version ] ; then
	ISSUE=`cat /etc/version | grep . | tail -n 1 ` 
	IMVER=${ISSUE%?????}
else
	IMVER="unknown"
fi

CREATE_ZIP="$2"
IMAGENAME="$3"

echo "Script date = $VERSION\n"
echo "Back-up media = $DIRECTORY\n"
df -h "$DIRECTORY"
echo "Back-up date_time = $DATE\n"
echo -n "Drivers = "
opkg list-installed | grep dvb-modules

log() {
   echo "$(date +%H:%M) $*"
}

checkb() {
   if [ ! -f "$1" ] ; then
      echo "Error: $1 does not exist..."
      exit 4
   elif [ ! -x "$1" ] ; then
      echo "Error: $1 is not executable..."
      exit 5
   fi
}

cleanup_mounts(){
   if [ ! -z "$TBI" ] ; then
      if [ -d "$TBI/boot" ] ; then
         if grep -q "$TBI/boot" /proc/mounts ; then
            umount "$TBI/boot" 2>/dev/null || log "Cannot umount boot" && exit 6
         fi
         rmdir "$TBI/boot" 2>/dev/null
      fi
      if [ -d "$TBI/root" ] ; then
         if grep -q "$TBI/root" /proc/mounts ; then
            umount "$TBI/root" 2>/dev/null || log "Cannot umount root" && exit 7
         fi
         rmdir "$TBI/root" 2>/dev/null
      fi
      if [ -d "/data/ubifs/root" ] ; then
         if grep -q "/data/ubifs/root" /proc/mounts ; then
            umount "/data/ubifs/root" 2>/dev/null || log "Cannot umount root" && exit 7
         fi
         rmdir "/data/ubifs/root" 2>/dev/null
      fi
   fi
}

control_c(){
   log "Control C was pressed, quiting..."
   cleanup_mounts
   rm -rf "$SBI" 2>/dev/null
   rm -rf "$TBI" 2>/dev/null
   exit 255
}

trap control_c SIGINT


check_dep(){
   log "Checking Dependencies..."
   UPDATE=0
   for pkg in mtd-utils mtd-utils-jffs2 mtd-utils-ubifs dreambox-buildimage;
   do   
      opkg status $pkg | grep -q "install user installed"
      if [ $? -ne 0 ] ; then
         [ $UPDATE -eq 0 ] && opkg update && UPDATE=1
         opkg install $pkg 2>/dev/null
      fi
   done
}

if [ -f /proc/stb/info/boxtype ] ; then
   log "Not a dreambox?" 
   exit 1
fi

if [ -f /proc/stb/info/vumodel ] ; then
   log "Not a dreambox?" 
   exit 1
fi

if [ ! -f /proc/stb/info/model ] ; then
   log "Not a dreambox?" 
   exit 1
fi

#
# Checking Dependencies
#
# check_dep

#
# Checking for binaries
#
checkb /usr/sbin/nanddump
checkb /usr/sbin/mkfs.jffs2
checkb /usr/bin/buildimage
checkb /usr/bin/python

#
# Read Dreambox Model
#
MACHINE="$(cat /proc/stb/info/model)"
log "Found Dreambox $MACHINE ..."

#
# Set Backup Location
#
BACKUP_LOCATION=""

if [ -z $1 ] ; then
   if [ -d /media/usb ] && df /media/usb 1>/dev/null 2>/dev/null ; then
      BACKUP_LOCATION="/media/usb"
   elif [ -d /media/hdd ] && df /media/hdd 1>/dev/null 2>/dev/null ; then
      BACKUP_LOCATION="/media/hdd"
   else
      log "Error: Backup Location not found!"
      exit 2
   fi
elif [ -d $1 ] && [ $1 != "/" ] && df $1 1>/dev/null 2>/dev/null ; then
    BACKUP_LOCATION=$1
else
   log "Error: Invalid Backup Location $1"
   exit 2
fi

# BACKUP_LOCATION="/media/hdd/backup"

log "Backup on $BACKUP_LOCATION"

EXTRA="$BACKUP_LOCATION/automatic_fullbackup/$DATE"
MAINDEST="$BACKUP_LOCATION/$MACHINE"

SBI="$BACKUP_LOCATION/bi"

# XXX path
TBI="/tmp/bi"
# TBI="/data/backup/bi"
#
# Initialize Parameters
#
EXTRA_BUILDCMD=""
EXTRA_IMAGECMD=""

DREAMBOX_ERASE_BLOCK_SIZE=""
DREAMBOX_FLASH_SIZE=""
DREAMBOX_SECTOR_SIZE=""
MKUBIFS_ARGS=""
UBINIZE_ARGS=""

UBINIZE_VOLSIZE="0"
UBINIZE_DATAVOLSIZE="0"
UBI_VOLNAME="rootfs"

DREAMBOX_IMAGE_SIZE=""
DREAMBOX_PART0_SIZE=""
DREAMBOX_PART1_SIZE=""
DREAMBOX_PART2_SIZE=""

#
# Set parameters based on box
# dm7020hdv2 is recognized from /sys/devices/virtual/mtd/mtd0/writesize
case $MACHINE in
   dm800|dm500hd|dm800se)
      EXTRA_BUILDCMD="--brcmnand"
      DREAMBOX_ERASE_BLOCK_SIZE="0x4000"
      DREAMBOX_FLASH_SIZE="0x4000000"
      DREAMBOX_SECTOR_SIZE="512"
      MKUBIFS_ARGS="-m 512 -e 15KiB -c 3798 -x favor_lzo -X 1 -F -j 4MiB"
      UBINIZE_ARGS="-m 512 -p 16KiB -s 512"
      DREAMBOX_IMAGE_SIZE="64"
      DREAMBOX_PART0_SIZE="0x40000"
      DREAMBOX_PART1_SIZE="0x3C0000"
      DREAMBOX_PART2_SIZE="0x3C00000"
      ;;
   dm500hdv2|dm800sev2|dm7020hdv2)
      EXTRA_BUILDCMD="--hw-ecc --brcmnand"
      DREAMBOX_ERASE_BLOCK_SIZE="0x20000"
      DREAMBOX_FLASH_SIZE="0x40000000"
      DREAMBOX_SECTOR_SIZE="2048"
      MKUBIFS_ARGS="-m 2048 -e 124KiB -c 3320 -x favor_lzo -F"
      UBINIZE_ARGS="-m 2048 -p 128KiB -s 2048"
      UBINIZE_VOLSIZE="402MiB"
      UBINIZE_DATAVOLSIZE="569MiB"
      DREAMBOX_IMAGE_SIZE="1024"
      DREAMBOX_PART0_SIZE="0x100000"
      DREAMBOX_PART1_SIZE="0x700000"
      DREAMBOX_PART2_SIZE="0x3F800000"
      ;;
   dm7020hd)
      EXTRA_BUILDCMD="--hw-ecc --brcmnand"
      DREAMBOX_ERASE_BLOCK_SIZE="0x40000"
      DREAMBOX_FLASH_SIZE="0x40000000"
      DREAMBOX_SECTOR_SIZE="4096"
      MKUBIFS_ARGS="-m 4096 -e 248KiB -c 1640 -x favor_lzo -F"
      UBINIZE_ARGS="-m 4096 -p 256KiB -s 4096"
      UBINIZE_VOLSIZE="397MiB"
      UBINIZE_DATAVOLSIZE="574MiB"
      DREAMBOX_IMAGE_SIZE="1024"
      DREAMBOX_PART0_SIZE="0x100000"
      DREAMBOX_PART1_SIZE="0x700000"
      DREAMBOX_PART2_SIZE="0x3F800000"

      # dm7020hdv2 when writesize = 2048
      WRITESIZE="4096"
      if [ -f /sys/devices/virtual/mtd/mtd0/writesize ] ; then 
         WRITESIZE=$(cat /sys/devices/virtual/mtd/mtd0/writesize)
      fi
      if [ $WRITESIZE = "2048" ] ; then
         log "Found version2 of dm7020hd..."
         DREAMBOX_ERASE_BLOCK_SIZE="0x20000"
         DREAMBOX_SECTOR_SIZE="2048"
         MKUBIFS_ARGS="-m 2048 -e 124KiB -c 3320 -x favor_lzo -F"
         UBINIZE_ARGS="-m 2048 -p 128KiB -s 2048"
         UBINIZE_VOLSIZE="402MiB"
         UBINIZE_DATAVOLSIZE="569MiB"
      fi
      ;;
   dm8000)
      EXTRA_BUILDCMD=""
      DREAMBOX_ERASE_BLOCK_SIZE="0x20000"
      DREAMBOX_FLASH_SIZE="0x10000000"
      DREAMBOX_SECTOR_SIZE="2048"
      MKUBIFS_ARGS="-m 2048 -e 126KiB -c 1961 -x favor_lzo -F"
      UBINIZE_ARGS="-m 2048 -p 128KiB -s 512"
      DREAMBOX_IMAGE_SIZE="256"
      DREAMBOX_PART0_SIZE="0x100000"
      DREAMBOX_PART1_SIZE="0x700000"
      DREAMBOX_PART2_SIZE="0xF800000"
      ;;
   *)
      log "Error: Unknown dreambox?"
      exit 3
      ;;
esac

EXTRA_IMAGECMD="-e $DREAMBOX_ERASE_BLOCK_SIZE -n -l"

#
# Setup temporary files and variables
#
SECSTAGE="$SBI/secondstage.bin"
UBINIZE_CFG="$TBI/ubinize.cfg"
BOOT="$SBI/boot.jffs2"
ROOTFS="$SBI/rootfs.jffs2"

cleanup_mounts

echo "Starting Full Backup!\nOptions control panel will not be available 2-15 minutes.\nPlease wait ..."
echo "--------------------------\n"

echo "\nWARNING!\n"
echo "To stop creating a backup, press the 'Menu' button.\n"
sleep 2

rm -rf "$SBI" 2>/dev/null
rm -rf "$TBI" 2>/dev/null
mkdir -p "$SBI"
mkdir -p "$TBI"

#
# Export secondstage
#
log "Exporting secondstage"
/usr/sbin/nanddump --noecc --omitoob --bb=skipbad --file="$SECSTAGE" /dev/mtd1
if [ $? -ne 0 ] && [ ! -f "$SECSTAGE" ] ; then
   rm -rf "$SBI" 2>/dev/null
   rm -rf "$TBI" 2>/dev/null
   log "Error: nanddump failed to dump secondstage!"
   exit 8
fi

#
# Trim 0xFFFFFF from secondstage
#
/usr/bin/python -c "
data=open('$SECSTAGE', 'rb').read()
cutoff=data.find('\xff\xff\xff\xff')
if cutoff:
    open('$SECSTAGE', 'wb').write(data[0:cutoff])
"

SIZE="$(du -k "$SECSTAGE" | awk '{ print $1 }')"
if [ $SIZE -gt 200 ] ; then
   log "Error: Size of secondstage must be less than 200k"
   log "Reinstall secondstage before creating backup"
   log "opkg install --force-reinstall dreambox-secondstage-$MACHINE"
   rm -rf "$SBI" 2>/dev/null
   rm -rf "$TBI" 2>/dev/null
   exit 9
fi

#
# Export boot partition
#
log "Exporting boot partition"
mkdir -p "$TBI/boot"
# mount -t jffs2 /dev/mtdblock/2 "$TBI/boot"
mount -t jffs2 /dev/mtdblock2 "$TBI/boot"

/usr/sbin/mkfs.jffs2 \
   --root="$TBI/boot" \
   --compression-mode=none \
   --output="$BOOT" \
   $EXTRA_IMAGECMD

umount "$TBI/boot" 2>/dev/null

#
# Export root partition
#
if grep -q ubi0:rootfs /proc/mounts ; then

   checkb /usr/sbin/mkfs.ubifs
   checkb /usr/sbin/ubinize

   log "Exporting rootfs (UBI)"
   ROOTFS="$SBI/rootfs.ubi"
   # ROOTUBIFS="$SBI/rootfs.ubifs" XXX
   ROOTUBIFS="/data/ubifs/rootfs.ubifs"
   mkdir -p "/data/ubifs/root"
   # mount --bind / "$TBI/root"
   mount -t ubifs /dev/ubi0_0 /data/ubifs/root

   echo [root] > $UBINIZE_CFG
   echo mode=ubi >> $UBINIZE_CFG
   echo image=$ROOTUBIFS >> $UBINIZE_CFG
   echo vol_id=0 >> $UBINIZE_CFG
   echo vol_name=$UBI_VOLNAME >> $UBINIZE_CFG
   echo vol_type=dynamic >> $UBINIZE_CFG
   if [ "$UBINIZE_VOLSIZE" = "0" ] ; then
      echo vol_flags=autoresize >> $UBINIZE_CFG
   else
      echo vol_size=$UBINIZE_VOLSIZE >> $UBINIZE_CFG
      if [ "$UBINIZE_DATAVOLSIZE" != "0" ] ; then
         echo [data] >> $UBINIZE_CFG
         echo mode=ubi >> $UBINIZE_CFG
         echo vol_id=1 >> $UBINIZE_CFG
         echo vol_type=dynamic >> $UBINIZE_CFG
         echo vol_name=data >> $UBINIZE_CFG
         echo vol_size=$UBINIZE_DATAVOLSIZE >> $UBINIZE_CFG
         echo vol_flags=autoresize >> $UBINIZE_CFG
      fi
   fi

   # /usr/sbin/mkfs.ubifs -r "$TBI/root" -o $ROOTUBIFS $MKUBIFS_ARGS
   # echo "ARGS1 $ROOTUBIFS"
   # echo "ARGS2 $MKUBIFS_ARGS"
   /usr/sbin/mkfs.ubifs -r "/data/ubifs/root" -o $ROOTUBIFS $MKUBIFS_ARGS
   log "mkfs.ubifs return value: $?"
   /usr/sbin/ubinize -o $ROOTFS $UBINIZE_ARGS $UBINIZE_CFG
   log "ubinize return value: $?"

   # umount "$TBI/root" 2>/dev/null
   umount "/data/ubifs/root" 2>/dev/null
else
   log "Export rootfs (JFFS2)"
   mkdir -p "$TBI/root"
   # XXX chyba
   # mount -t jffs2 /dev/mtdblock/3 "$TBI/root"
   mount -t jffs2 /dev/mtdblock3 "$TBI/root"

   /usr/sbin/mkfs.jffs2 \
      --root="$TBI/root" \
      --disable-compressor=lzo \
      --compression-mode=size \
      --output=$ROOTFS \
      $EXTRA_IMAGECMD
   log "mkfs.jffs2 return value: $?"
   umount "$TBI/root" 2>/dev/null
fi

#
# Build NFI image
#
log "Building NFI image"
/usr/bin/buildimage --arch $MACHINE $EXTRA_BUILDCMD \
   --erase-block-size $DREAMBOX_ERASE_BLOCK_SIZE \
   --flash-size $DREAMBOX_FLASH_SIZE \
   --sector-size $DREAMBOX_SECTOR_SIZE \
   --boot-partition $DREAMBOX_PART0_SIZE:$SECSTAGE \
   --data-partition $DREAMBOX_PART1_SIZE:$BOOT \
   --data-partition $DREAMBOX_PART2_SIZE:$ROOTFS \
   > "$SBI/backup.nfi"

#
# Archive NFI image
#
log "Transfering image to backup folder"
TSTAMP="$(date "+%Y-%m-%d-%Hh%Mm")"
rm -rf "$MAINDEST" 2>/dev/null

mkdir -p "$MAINDEST"
NFI="$MAINDEST/$TSTAMP-$MACHINE.nfi"
mv "$SBI/backup.nfi" "$NFI"
log "Backup image created $NFI"
log "$(du -h $NFI)"


if [ -z "$CREATE_ZIP" ] ; then
   mkdir -p "$EXTRA"
   touch "$NFI/$IMVER"
   cp -r "$NFI" "$EXTRA"
   touch "$BACKUP_LOCATION/automatic_fullbackup/.timestamp"
else
   if [ $CREATE_ZIP != "none" ] ; then
      log "Create zip archive..."
      cd $BACKUP_LOCATION && $CREATE_ZIP -r $BACKUP_LOCATION/backup-$IMAGENAME-$MACHINE-$TSTAMP.zip . -i /$MACHINE/*
      cd
   fi
fi

#
# Cleanup
#
log "Remove temporary files..."
cleanup_mounts
rm -rf "$SBI" 2>/dev/null
rm -rf "$TBI" 2>/dev/null


if [ -f "$NFI" ] ; then
	echo " "
	echo "BACK-UP MADE SUCCESSFULLY IN: $MAINDEST\n"
else
	echo " "
	echo "Image creation FAILED!\n"
fi
#
# The End
#
log "Completed!"
sleep 3
END=$(date +%s)
DIFF=$(( $END - $START ))
MINUTES=$(( $DIFF/60 ))
SECONDS=$(( $DIFF-(( 60*$MINUTES ))))
if [ $SECONDS -le  9 ] ; then 
	SECONDS="0$SECONDS"
fi
echo "BACKUP FINISHED IN $MINUTES.$SECONDS MINUTES\n"
exit 0

