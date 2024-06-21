umount_root() {
    umount -l $ROOTFS/dev/pts
    umount -l $ROOTFS/dev/shm
    umount -l $ROOTFS/tmp
    umount -l $ROOTFS/sys
    umount -l $ROOTFS/proc
    umount -l $ROOTFS/dev
    umount -l $ROOTFS/sdcard
    umount -l $ROOTFS
}

umount_root
