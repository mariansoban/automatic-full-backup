#!/bin/sh
#

VERSION="25/25/2016\ncreators of the script Pedro_Newbie and Dimitrij (http://forums.openpli.org)\n"
DIRECTORY="$1"
START=$(date +%s)
DATE=`date +%Y%m%d_%H%M`
IMAGEVERSION=`date +%Y%m%d`
MKFS=/usr/sbin/mkfs.ubifs
UBINIZE=/usr/sbin/ubinize
NANDDUMP=/usr/sbin/nanddump
WORKDIR="$DIRECTORY/bi"

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

echo "Script date = $VERSION\n"
echo "Back-up media = $DIRECTORY\n"
df -h "$DIRECTORY"
echo "Back-up date_time = $DATE\n"
echo "Working directory = $WORKDIR\n"
echo -n "Drivers = "
opkg list-installed | grep dvb-modules
CREATE_ZIP="$2"
IMAGENAME="$3"

if grep rootfs /proc/mounts | grep ubifs > /dev/null; then
	ROOTFSTYPE=ubifs
else
	echo "NO UBIFS, THEN JFFS2 BUT NOT SUPPORTED ANYMORE\n"
	exit 0
fi
	## TESTING THE XTREND, CLARK TECH AND XP MODELS
if [ -f /proc/stb/info/boxtype ] ; then
	MODEL=$( cat /proc/stb/info/boxtype )
	if grep et /proc/stb/info/boxtype > /dev/null ; then
		TYPE=ET
		MKUBIFS_ARGS="-m 2048 -e 126976 -c 4096"
		if [ $MODEL = "et10000" -o $MODEL = "et8000" -o $MODEL = "et8500" -o $MODEL = "et7000" -o $MODEL = "et7500" -o $MODEL = "et7000mini" ] ; then
			MKUBIFS_ARGS="-m 2048 -e 126976 -c 8192"
		fi
		if [ $MODEL = "et10000" -o $MODEL = "et8000" -o $MODEL = "et8500" ] ; then
			echo " "
		elif [ $MODEL = "et7000mini" ] ; then
			MODEL="et7x00"
		else
			MODEL=${MODEL:0:3}x00
		fi
		UBINIZE_ARGS="-m 2048 -p 128KiB"
		SHOWNAME="ET/Xtrend $MODEL"
		MAINDEST="$DIRECTORY/$MODEL"
		EXTRA="$DIRECTORY/automatic_fullbackup/$DATE"
		echo "Destination        = $MAINDEST\n"
		if grep boot /proc/mtd > /dev/null ; then
			exit 0
		fi
	elif grep xp /proc/stb/info/boxtype > /dev/null ; then
		TYPE=XP
		MKUBIFS_ARGS="-m 2048 -e 126976 -c 4096"
		UBINIZE_ARGS="-m 2048 -p 128KiB"
		SHOWNAME="MK-Digital $MODEL"
		MAINDEST="$DIRECTORY/$MODEL"
		EXTRA="$DIRECTORY/automatic_fullbackup/$DATE"
		echo "Destination        = $MAINDEST\n"
	elif grep ini /proc/stb/info/boxtype > /dev/null ; then
		TYPE=XPEED
		MKUBIFS_ARGS="-m 2048 -e 126976 -c 4096"
		UBINIZE_ARGS="-m 2048 -p 128KiB"
		if [ $MODEL = "ini-9000de" ] ; then 
			MKUBIFS_ARGS="-m 4096 -e 1040384 -c 1984"
			UBINIZE_ARGS="-m 4096 -p 1024KiB"
		fi
		SHOWNAME="Golden Interstar Xpeed LX or LX3 $MODEL"
		MAINDEST="$DIRECTORY/$MODEL"
		EXTRA="$DIRECTORY/automatic_fullbackup/$DATE"
		echo "Destination        = $MAINDEST\n"
	elif grep xpeedlx /proc/stb/info/boxtype > /dev/null ; then
		TYPE=XPEED
		MKUBIFS_ARGS="-m 2048 -e 126976 -c 4096"
		UBINIZE_ARGS="-m 2048 -p 128KiB"
		SHOWNAME="Golden Interstar Xpeed LX Class S2 or C $MODEL"
		MAINDEST="$DIRECTORY/$MODEL"
		EXTRA="$DIRECTORY/automatic_fullbackup/$DATE"
		echo "Destination        = $MAINDEST\n"
	elif grep formuler /proc/stb/info/boxtype > /dev/null ; then
		TYPE=FORMULER
		MKUBIFS_ARGS="-m 2048 -e 126976 -c 8192"
		UBINIZE_ARGS="-m 2048 -p 128KiB"
		SHOWNAME="Openbox (Formuler1/3/4) $MODEL"
		MAINDEST="$DIRECTORY/$MODEL"
		EXTRA="$DIRECTORY/automatic_fullbackup/$DATE"
		echo "Destination        = $MAINDEST\n"
	elif grep spycat /proc/stb/info/boxtype > /dev/null ; then
		TYPE=SPYCAT
		MKUBIFS_ARGS="-m 2048 -e 126976 -c 4096 -F"
		UBINIZE_ARGS="-m 2048 -p 128KiB"
		SHOWNAME="Spycat (mini)"
		MAINDEST="$DIRECTORY/$MODEL"
		EXTRA="$DIRECTORY/automatic_fullbackup/$DATE"
		echo "Destination        = $MAINDEST\n"
	elif grep osm /proc/stb/info/boxtype > /dev/null ; then
		TYPE=EDISION
		MKUBIFS_ARGS="-m 2048 -e 126976 -c 4096 -F"
		UBINIZE_ARGS="-m 2048 -p 128KiB"
		SHOWNAME="Edision OS mega / mini(+)"
		MAINDEST="$DIRECTORY/$MODEL"
		EXTRA="$DIRECTORY/automatic_fullbackup/$DATE"
		echo "Destination        = $MAINDEST\n"
	elif grep h3 /proc/stb/info/boxtype > /dev/null ; then
		TYPE=ZGEMMA
		MKUBIFS_ARGS="-m 2048 -e 126976 -c 8192"
		UBINIZE_ARGS="-m 2048 -p 128KiB"
		SHOWNAME="Zgemma H.S / H.2S / H.2H $MODEL"
		MAINDEST="$DIRECTORY/zgemma/$MODEL"
		EXTRA="$DIRECTORY/automatic_fullbackup/$DATE/zgemma"
		echo "Destination        = $MAINDEST\n"
	elif grep h5 /proc/stb/info/boxtype > /dev/null ; then
		TYPE=ZGEMMA
		MKUBIFS_ARGS="-m 2048 -e 126976 -c 8192"
		UBINIZE_ARGS="-m 2048 -p 128KiB"
		SHOWNAME="Zgemma H5 $MODEL"
		MAINDEST="$DIRECTORY/zgemma/$MODEL"
		EXTRA="$DIRECTORY/automatic_fullbackup/$DATE/zgemma"
		echo "Destination        = $MAINDEST\n"
	elif grep sh1 /proc/stb/info/boxtype > /dev/null ; then
		TYPE=ZGEMMA
		MKUBIFS_ARGS="-m 2048 -e 126976 -c 4096"
		UBINIZE_ARGS="-m 2048 -p 128KiB"
		SHOWNAME="Zgemma Star S / Star 2S $MODEL"
		MAINDEST="$DIRECTORY/zgemma/$MODEL"
		EXTRA="$DIRECTORY/automatic_fullbackup/$DATE/zgemma"
		echo "Destination        = $MAINDEST\n"
	elif grep i55 /proc/stb/info/boxtype > /dev/null ; then
		TYPE=ZGEMMA
		MKUBIFS_ARGS="-m 2048 -e 126976 -c 8192"
		UBINIZE_ARGS="-m 2048 -p 128KiB"
		SHOWNAME="Zgemma I 55"
		MAINDEST="$DIRECTORY/zgemma/$MODEL"
		EXTRA="$DIRECTORY/automatic_fullbackup/$DATE/zgemma"
		echo "Destination        = $MAINDEST\n"
	elif grep hd /proc/stb/info/boxtype > /dev/null ; then
		TYPE=MUTANT
		if [ $MODEL = "hd51" ] || [ $MODEL = "hd52" ] ; then
			echo "No supported receiver found!\nSorri, please wait new version this plugin!\n"
			exit 0
		fi
		if [ $MODEL = "hd2400" ] || [ $MODEL = "hd1200" ] || [ $MODEL = "hd1500" ] || [ $MODEL = "hd1265" ] || [ $MODEL = "hd11" ] ; then
			MKUBIFS_ARGS="-m 2048 -e 126976 -c 8192"
		else
			MKUBIFS_ARGS="-m 2048 -e 126976 -c 4096"
		fi
		UBINIZE_ARGS="-m 2048 -p 128KiB"
		SHOWNAME="HD2400/HD1100/HD500C/HD1200/HD1500/HD1265/HD11 $MODEL"
		MAINDEST="$DIRECTORY/$MODEL"
		EXTRA="$DIRECTORY/automatic_fullbackup/$DATE"
		echo "Destination        = $MAINDEST\n"
	elif grep 7000S /proc/stb/info/boxtype > /dev/null ; then
		TYPE=MIRACLEBOX
		MKUBIFS_ARGS="-m 2048 -e 126976 -c 8192"
		UBINIZE_ARGS="-m 2048 -p 128KiB"
		SHOWNAME="Miraclebox Premium Micro"
		MAINDEST="$DIRECTORY/miraclebox/micro"
		EXTRA="$DIRECTORY/automatic_fullbackup/$DATE"
		echo "Destination        = $MAINDEST\n"
	elif grep g300 /proc/stb/info/boxtype > /dev/null ; then
		TYPE=MIRACLEBOX
		MKUBIFS_ARGS="-m 2048 -e 126976 -c 8192"
		UBINIZE_ARGS="-m 2048 -p 128KiB"
		SHOWNAME="Miraclebox Premium Twin+"
		MAINDEST="$DIRECTORY/miraclebox/twinplus"
		EXTRA="$DIRECTORY/automatic_fullbackup/$DATE"
		echo "Destination        = $MAINDEST\n"
	else
		echo "No supported receiver found!\n"
		exit 0
	fi
	## TESTING THE VU+ MODELS
elif [ -f /proc/stb/info/vumodel ] ; then
	MODEL=$( cat /proc/stb/info/vumodel )
	TYPE=VU
	SHOWNAME="Vu+ $MODEL"
	MAINDEST="$DIRECTORY/vuplus/$MODEL"
	EXTRA="$DIRECTORY/automatic_fullbackup/$DATE/vuplus"
	if [ $MODEL = "solo2" ] || [ $MODEL = "solose" ] ; then
		MKUBIFS_ARGS="-m 2048 -e 126976 -c 4096"
	elif [ $MODEL = "zero" ] || [ $MODEL = "duo2" ] ; then
		MKUBIFS_ARGS="-m 2048 -e 126976 -c 8192"
	else
		MKUBIFS_ARGS="-m 2048 -e 126976 -c 4096 -F"
	fi
	UBINIZE_ARGS="-m 2048 -p 128KiB"
	echo "Destination        = $MAINDEST\n"
elif [ -f /proc/stb/info/hwmodel ] ; then
	MODEL=$( cat /proc/stb/info/hwmodel )
	if grep purehd /proc/stb/info/hwmodel > /dev/null ; then
		TYPE=FUSION
		MKUBIFS_ARGS="-m 2048 -e 126976 -c 4096 -F"
		UBINIZE_ARGS="-m 2048 -p 128KiB"
		SHOWNAME="Xsarius $MODEL"
		MAINDEST="$DIRECTORY/update/$MODEL/cfe"
		EXTRA="$DIRECTORY/automatic_fullbackup/$DATE/update"
		echo "Destination        = $MAINDEST\n"
	elif grep fusion /proc/stb/info/hwmodel > /dev/null ; then
		TYPE=FUSION
		MKUBIFS_ARGS="-m 2048 -e 126976 -c 4096 -F"
		UBINIZE_ARGS="-m 2048 -p 128KiB"
		SHOWNAME="Xsarius $MODEL"
		MAINDEST="$DIRECTORY/update/$MODEL/cfe"
		EXTRA="$DIRECTORY/automatic_fullbackup/$DATE/update"
		echo "Destination        = $MAINDEST\n"
	else
		echo "No supported receiver found!\n"
		exit 0
	fi
elif [ -f /proc/stb/info/gbmodel ] ; then
	MODEL=$( cat /proc/stb/info/gbmodel )
	if grep gbquadplus /proc/stb/info/gbmodel > /dev/null ; then
		TYPE=GIGABLUE
		MKUBIFS_ARGS="-m 2048 -e 126976 -c 4096 -F"
		UBINIZE_ARGS="-m 2048 -p 128KiB"
		SHOWNAME="Gigablue Quad $MODEL"
		MAINDEST="$DIRECTORY/gigablue/quadplus"
		EXTRA="$DIRECTORY/automatic_fullbackup/$DATE/gigablue/quadplus"
		echo "Destination        = $MAINDEST\n"
	else
		echo "No supported receiver found!\n"
		exit 0
	fi
else
	echo "No supported receiver found!\n"
	exit 0
fi
## TESTING IF ALL THE TOOLS FOR THE BUILDING PROCESS ARE PRESENT
if [ ! -f $MKFS ] ; then
	echo "NO MKFS.UBIFS FOUND, ABORTING\n"
	exit 0
fi

if [ ! -f $NANDDUMP ] ; then
	echo "NO NANDDUMP FOUND, ABORTING\n"
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

echo \[ubifs\] > "$WORKDIR/ubinize.cfg"
echo mode=ubi >> "$WORKDIR/ubinize.cfg"
echo image="$WORKDIR/root.ubi" >> "$WORKDIR/ubinize.cfg"
echo vol_id=0 >> "$WORKDIR/ubinize.cfg"
echo vol_type=dynamic >> "$WORKDIR/ubinize.cfg"
echo vol_name=rootfs >> "$WORKDIR/ubinize.cfg"
echo vol_flags=autoresize >> "$WORKDIR/ubinize.cfg"
echo "UBINIZE.CFG CREATED WITH THE CONTENT:\n"
echo "$WORKDIR/ubinize.cfg\n"
touch "$WORKDIR/root.ubi"
chmod 644 "$WORKDIR/root.ubi"
echo "--------------------------"
echo "Start creating root.ubi\n"
$MKFS -r /tmp/bi/root -o "$WORKDIR/root.ubi" $MKUBIFS_ARGS
echo "Start UBINIZING\n"
$UBINIZE -o "$WORKDIR/root.ubifs" $UBINIZE_ARGS "$WORKDIR/ubinize.cfg" >/dev/null

chmod 644 "$WORKDIR/root.ubifs"
echo "Start creating kerneldump\n"
if [ $MODEL = "solo2" ] || [ $MODEL = "duo2" ] || [ $MODEL = "solose" ] || [ $MODEL = "zero" ] ; then
	$NANDDUMP /dev/mtd2 -q > "$WORKDIR/vmlinux.gz"
else 
	$NANDDUMP /dev/mtd1 -q > "$WORKDIR/vmlinux.gz"
fi

TSTAMP="$(date "+%Y-%m-%d-%Hh%Mm")"

if [ $TYPE = "ET" -o $MODEL = "xp1000" -o $TYPE = "EDISION" -o $TYPE = "SPYCAT" -o $TYPE = "GIGABLUE" ] ; then
	rm -rf "$MAINDEST"
	echo "Removed directory  = $MAINDEST\n"
	mkdir -p "$MAINDEST"
	echo "Created directory  = $MAINDEST\n"
	mv "$WORKDIR/root.ubifs" "$MAINDEST/rootfs.bin"
	mv "$WORKDIR/vmlinux.gz" "$MAINDEST/kernel.bin"
	echo "rename this file to 'force' to force an update without confirmation" > "$MAINDEST/noforce"
	echo "$MODEL-$IMAGEVERSION" > "$MAINDEST/imageversion"
	if [ -z "$CREATE_ZIP" ] ; then
		mkdir -p "$EXTRA"
		echo "Created directory  = $EXTRA\n"
		touch "$MAINDEST/$IMVER"
		cp -r "$MAINDEST" "$EXTRA"
		touch "$DIRECTORY/automatic_fullbackup/.timestamp"
	else
		if [ $CREATE_ZIP != "none" ] ; then
			echo "Create zip archive..."
			cd $DIRECTORY && $CREATE_ZIP -r $DIRECTORY/backup-$IMAGENAME-$MODEL-$TSTAMP.zip . -i /$MODEL/*
			cd
		fi
	fi
	if [ -f "$MAINDEST/rootfs.bin" -a -f "$MAINDEST/kernel.bin" -a -f "$MAINDEST/imageversion" -a -f "$MAINDEST/noforce" ] ; then
		echo " "
		echo "BACK-UP MADE SUCCESSFULLY IN: $MAINDEST\n"
	else
		echo " "
		echo "Image creation FAILED!\n"
	fi
fi

if [ $TYPE = "FUSION" ] ; then
	rm -rf "$MAINDEST"
	echo "Removed directory  = $MAINDEST\n"
	mkdir -p "$MAINDEST"
	echo "Created directory  = $MAINDEST\n"
	mv "$WORKDIR/root.ubifs" "$MAINDEST/oe_rootfs.bin"
	mv "$WORKDIR/vmlinux.gz" "$MAINDEST/oe_kernel.bin"
	echo "$MODEL-$IMAGEVERSION" > "$MAINDEST/imageversion"
	if [ -z "$CREATE_ZIP" ] ; then
		mkdir -p "$EXTRA"
		echo "Created directory  = $EXTRA\n"
		touch "$MAINDEST/$IMVER"
		cp -r "$MAINDEST" "$EXTRA"
		touch "$DIRECTORY/automatic_fullbackup/.timestamp"
	else
		if [ $CREATE_ZIP != "none" ] ; then
			echo "Create zip archive..."
			cd $DIRECTORY && $CREATE_ZIP -r $DIRECTORY/backup-$IMAGENAME-$MODEL-$TSTAMP.zip . -i /$MODEL/*
			cd
		fi
	fi
	if [ -f "$MAINDEST/oe_rootfs.bin" -a -f "$MAINDEST/oe_kernel.bin" -a -f "$MAINDEST/imageversion" ] ; then
		echo " "
		echo "BACK-UP MADE SUCCESSFULLY IN: $MAINDEST\n"
	else
		echo " "
		echo "Image creation FAILED!\n"
	fi
fi

if [ $TYPE = "FORMULER" -o $TYPE = "MUTANT" -o $TYPE = "XPEED" -o $TYPE = "ZGEMMA" -o $TYPE = "MIRACLEBOX" ] ; then
	rm -rf "$MAINDEST"
	echo "Removed directory  = $MAINDEST\n"
	mkdir -p "$MAINDEST"
	echo "Created directory  = $MAINDEST\n"
	mv "$WORKDIR/root.ubifs" "$MAINDEST/rootfs.bin"
	mv "$WORKDIR/vmlinux.gz" "$MAINDEST/kernel.bin"
	echo "rename this file to 'force' to force an update without confirmation" > "$MAINDEST/noforce";
	echo "$MODEL-$IMAGEVERSION" > "$MAINDEST/imageversion"
	if [ -z "$CREATE_ZIP" ] ; then
		mkdir -p "$EXTRA"
		echo "Created directory  = $EXTRA\n"
		touch "$MAINDEST/$IMVER"
		cp -r "$MAINDEST" "$EXTRA"
		touch "$DIRECTORY/automatic_fullbackup/.timestamp"
	else
		if [ $CREATE_ZIP != "none" ] ; then
			echo "Create zip archive..."
			cd $DIRECTORY && $CREATE_ZIP -r $DIRECTORY/backup-$IMAGENAME-$MODEL-$TSTAMP.zip . -i /$MODEL/*
			cd
		fi
	fi
	if [ -f "$MAINDEST/rootfs.bin" -a -f "$MAINDEST/kernel.bin" -a -f "$MAINDEST/imageversion" -a -f "$MAINDEST/noforce" ] ; then
		echo " "
		echo "BACK-UP MADE SUCCESSFULLY IN: $MAINDEST\n"
	else
		echo " "
		echo "Image creation FAILED!\n"
	fi
fi

if [ $TYPE = "VU" ] ; then
	rm -rf "$MAINDEST"
	echo "Removed directory  = $MAINDEST\n"
	mkdir -p "$MAINDEST"
	echo "Created directory  = $MAINDEST\n"
	echo "$MODEL-$IMAGEVERSION" > "$MAINDEST/imageversion"
	if [ $MODEL = "solo2" ] || [ $MODEL = "duo2" ] || [ $MODEL = "solose" ] || [ $MODEL = "zero" ] ; then
		mv "$WORKDIR/root.ubifs" "$MAINDEST/root_cfe_auto.bin"
	else
		mv "$WORKDIR/root.ubifs" "$MAINDEST/root_cfe_auto.jffs2"
	fi
	mv "$WORKDIR/vmlinux.gz" "$MAINDEST/kernel_cfe_auto.bin"
	if [ $MODEL = "solo2" -o $MODEL = "duo2" -o $MODEL = "ultimo" -o $MODEL = "uno" ] ; then
		touch "$MAINDEST/reboot.update"
		echo "rename this file to 'force.update' to force an update without confirmation" > "$MAINDEST/noforce.update"
		echo "and remove reboot.update, otherwise the box is flashed again after completion" >> "$MAINDEST/noforce.update"
		chmod 644 "$MAINDEST/reboot.update"
	fi
	if [ $MODEL = "solose" -o $MODEL = "zero" ] ; then
		echo "rename this file to 'force.update' to be able to flash this backup" > "$MAINDEST/noforce.update"
	fi
	if [ -z "$CREATE_ZIP" ] ; then
		mkdir -p "$EXTRA/$MODEL"
		echo "Created directory  = $EXTRA/$MODEL\n"
		touch "$MAINDEST/$IMVER"
		cp -r "$MAINDEST" "$EXTRA" 
		touch "$DIRECTORY/automatic_fullbackup/.timestamp"
	else
		if [ $CREATE_ZIP != "none" ] ; then
			echo "Create zip archive..."
			cd $DIRECTORY && $CREATE_ZIP -r $DIRECTORY/backup-$IMAGENAME-$MODEL-$TSTAMP.zip . -i /$MODEL/*
			cd
		fi
	fi
	if [ -f "$MAINDEST/root_cfe_auto"* -a -f "$MAINDEST/kernel_cfe_auto.bin" ] ; then
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