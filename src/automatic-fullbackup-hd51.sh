#!/bin/sh
#### BACKUP IMAGE ####

VERSION="HD51 - 25/11/2016\ncreator of the script Dimitrij (http://forums.openpli.org)\n"
DIRECTORY="$1"
START=$(date +%s)
DATE=`date +%Y%m%d_%H%M`
IMAGEVERSION=`date +%Y%m%d`
MKFS=/bin/tar
BZIP2=/usr/bin/bzip2
ROOTFSTYPE="rootfs.tar.bz2"
IMAGETYPE="disk.img"
WORKDIR="$DIRECTORY/bi"
RESIZE2FS=/sbin/resize2fs

echo "Script date = $VERSION\n"
echo "Back-up media = $DIRECTORY\n"
df -h "$DIRECTORY"
echo "Back-up date_time = $DATE\n"
echo "Working directory = $WORKDIR\n"
echo -n "Drivers = "
opkg list-installed | grep dvb-modules
CREATE_ZIP="$2"
IMAGENAME="$3"

if [ -f cat /proc/stb/info/boxtype ] ; then
	MODEL=$( cat cat /proc/stb/info/boxtype )
	if [ $MODEL = "hd51" ] ; then
		echo "Found Mutant HD51 4K\n"
		MTD_KERNEL="mmcblk0p2"
		KERNELNAME="kernel1.bin"
	else
		echo "No supported receiver found!\n"
		exit 0
	fi
	TYPE=MUTANT
	SHOWNAME="$TYPE $MODEL"
	MAINDEST="$DIRECTORY/$MODEL"
	EXTRA="$DIRECTORY/automatic_fullbackup/$DATE"
	echo "Destination        = $MAINDEST\n"
else
	echo "No supported receiver found!\n"
	exit 0
fi

if [ ! -f $MKFS ] ; then
	echo "NO TAR FOUND, ABORTING\n"
	exit 0
fi
if [ ! -f "$BZIP2" ] ; then 
	echo "$BZIP2 not installed yet, now installing\n"
	opkg update > /dev/null 2>&1
	opkg install bzip2 > /dev/null 2>&1
	echo "Exit, try again\n"
	sleep 10
	exit 0
fi

echo "Starting Full Backup!\nOptions control panel will not be available 2-15 minutes.\nPlease wait ..."
echo "--------------------------"

control_c(){
   echo "Control C was pressed, quiting..."
   umount /tmp/bi/root 2>/dev/null
   rmdir /tmp/bi/root 2>/dev/null
   rmdir /tmp/bi 2>/dev/null
   rm -rf "$WORKDIR" 2>/dev/null
   exit 255
}
trap control_c SIGINT

echo "\nWARNING!\n"
echo "To stop creating a backup, press the Menu button.\n"
sleep 2

## PREPARING THE BUILDING ENVIRONMENT
rm -rf "$WORKDIR"
echo "Remove directory   = $WORKDIR\n"
mkdir -p "$WORKDIR"
echo "Recreate directory = $WORKDIR\n"
mkdir -p /tmp/bi/root
echo "Create directory   = /tmp/bi/root\n"
sync
mount --bind / /tmp/bi/root

dd if=/dev/$MTD_KERNEL of=$WORKDIR/$KERNELNAME
echo "Kernel resides on /dev/$MTD_KERNEL\n" 

echo "Start creating rootfs.tar\n"
$MKFS -cf $WORKDIR/rootfs.tar -C /tmp/bi/root --exclude=/var/nmbd/* .
$BZIP2 $WORKDIR/rootfs.tar

#if [ ! -f "$RESIZE2FS" ] ; then 
#	echo "$RESIZE2FS not installed yet, now installing\n"
#	opkg update > /dev/null 2>&1
#	opkg install e2fsprogs > /dev/null 2>&1
#	echo "Exit, try again\n"
#	sleep 10
#	exit 0
#fi

#ROOTFS1=$(df | awk '$1=="/dev/root"{print$3}')
#ROOTFS_OFFSET="10000"
#echo "Start creating $IMAGETYPE\n"
#dd if=/dev/root of=$WORKDIR/$IMAGETYPE bs=1024 count="$(($ROOTFS1 + $ROOTFS_OFFSET))" #> /dev/null 2>&1
#if [ -f $WORKDIR/$IMAGETYPE ] ; then
#	echo "Start e2fsck\n"
#	e2fsck -f $WORKDIR/$IMAGETYPE
#	echo "Start resize2fs\n"
#	resize2fs -M $WORKDIR/$IMAGETYPE
#fi

TSTAMP="$(date "+%Y-%m-%d-%Hh%Mm")"

if [ $TYPE = "MUTANT" ] ; then
	rm -rf "$MAINDEST"
	echo "Removed directory  = $MAINDEST\n"
	mkdir -p "$MAINDEST" 
	echo "Created directory  = $MAINDEST\n"
	mv "$WORKDIR/$KERNELNAME" "$MAINDEST/$KERNELNAME"
	mv "$WORKDIR/$ROOTFSTYPE" "$MAINDEST/$ROOTFSTYPE"
#	if [ -f $WORKDIR/$IMAGETYPE ] ; then
#		mv "$WORKDIR/$IMAGETYPE" "$MAINDEST/$IMAGETYPE"
#	fi
	echo "$MODEL-$IMAGEVERSION" > "$MAINDEST/imageversion"
	if [ -z "$CREATE_ZIP" ] ; then
		mkdir -p "$EXTRA/$MODEL"
		echo "Created directory  = $EXTRA/$MODEL\n"
		cp -r "$MAINDEST" "$EXTRA" 
		touch "$DIRECTORY/automatic_fullbackup/.timestamp"
	else
		if [ $CREATE_ZIP != "none" ] ; then
			echo "Create zip archive..."
			cd $DIRECTORY && $CREATE_ZIP -r $DIRECTORY/backup-$IMAGENAME-$MODEL-$TSTAMP.zip . -i /$MODEL/*
			cd
		fi
	fi
	if [ -f "$MAINDEST/rootfs.tar.bz2" -a -f "$MAINDEST/$KERNELNAME" ] ; then
		echo " "
		echo "BACK-UP MADE SUCCESSFULLY IN: $MAINDEST\n"
	else
		echo " "
		echo "Image creation FAILED!\n"
	fi
fi
umount /tmp/bi/root
rmdir /tmp/bi/root
rmdir /tmp/bi
rm -rf "$WORKDIR"
sleep 5
END=$(date +%s)
DIFF=$(( $END - $START ))
MINUTES=$(( $DIFF/60 ))
SECONDS=$(( $DIFF-(( 60*$MINUTES ))))
if [ $SECONDS -le  9 ] ; then 
	SECONDS="0$SECONDS"
fi
echo "BACKUP FINISHED IN $MINUTES.$SECONDS MINUTES\n"
exit 
