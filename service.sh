MODDIR=${0%/*}
ROOTFS=$MODDIR/rootfs

mount -o remount,suid /data
mount --bind /dev $ROOTFS/dev
mount -t proc proc $ROOTFS/proc
mount -t sysfs sysfs $ROOTFS/sys
mount -t tmpfs tmpfs $ROOTFS/tmp
mount -t devpts devpts $ROOTFS/dev/pts

mkdir -p $ROOTFS/dev/shm
mount -t tmpfs -o size=256M tmpfs $ROOTFS/dev/shm
mount --bind /storage/emulated/0 $ROOTFS/sdcard

PATH=/usr/bin:/usr/sbin chroot $ROOTFS serviced
