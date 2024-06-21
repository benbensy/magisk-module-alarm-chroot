ROOTFS=$MODPATH/rootfs

download_file() {
    curl -skLf http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz -o $TMPDIR/rootfs.tar.gz
    curl -skLf https://github.com/smaknsk/servicectl/archive/1.0.tar.gz -o $TMPDIR/servicectl.tar.gz
}

mkroot() {
    mkdir -p $ROOTFS
    tar xpf $TMPDIR/rootfs.tar.gz -C $ROOTFS --numeric-owner
    mkdir -p $ROOTFS/dev/shm
    mkdir -p $ROOTFS/sdcard
}

init() {
    unlink $ROOTFS/etc/resolv.conf
    echo 'nameserver 8.8.8.8' >$ROOTFS/etc/resolv.conf

    tar xpf $TMPDIR/servicectl.tar.gz -C $ROOTFS/usr/lib
    ln -sf /usr/lib/servicectl-1.0/servicectl $ROOTFS/usr/bin/servicectl
    ln -sf /usr/lib/servicectl-1.0/serviced $ROOTFS/usr/bin/serviced

    sed -i '/^CheckSpace/s/^/#/' $ROOTFS/etc/pacman.conf
    sed -i '/^#IgnorePkg/a\IgnorePkg = linux-aarch64 linux-firmware' $ROOTFS/etc/pacman.conf
    sed -i '/^#.*en_US.UTF-8/s/^#//' $ROOTFS/etc/locale.gen
    sed -i '/^#.*zh_CN.UTF-8/s/^#//' $ROOTFS/etc/locale.gen
    echo 'LANG=en_US.UTF-8' >$ROOTFS/etc/locale.conf
    ln -sf /usr/share/zoneinfo/Asia/Shanghai $ROOTFS/etc/localtime

    cat >$ROOTFS/chroot-install.sh <<EOF
groupadd -g 3003 aid_inet
groupadd -g 3004 aid_net_raw
groupadd -g 1003 aid_graphics
usermod -aG aid_inet root
usermod -aG wheel,video,audio,storage,aid_inet,aid_net_raw,aid_graphics alarm
locale-gen

pacman-key --init
pacman-key --populate archlinuxarm

pacman -Sy --noconfirm archlinux-keyring archlinuxarm-keyring
pacman -Rs linux-aarch64 linux-firmware --noconfirm
pacman -Syu --noconfirm
pacman -S --noconfirm vim sudo wget curl git openssh
sed -i '/^# *%wheel *ALL=(ALL:ALL) ALL$/s/^# *//' /etc/sudoers

ssh-keygen -A
servicectl enable sshd
rm \$(readlink -f \$0)
EOF
}

run_install() {
    ui_print "Download files.."
    download_file

    if [[ ! -f "$TMPDIR/rootfs.tar.gz" ]] || [[ ! -f "$TMPDIR/servicectl.tar.gz" ]]; then
        abort "Download files failed❌"
    fi

    ui_print "Create rootfs.."
    mkroot
    ui_print "Init configuration.."
    init
    ui_print "Customize rootfs.."

    mount --bind /dev $ROOTFS/dev
    mount -t proc proc $ROOTFS/proc
    mount -t sysfs sysfs $ROOTFS/sys
    mount -t tmpfs tmpfs $ROOTFS/tmp
    mount -t devpts devpts $ROOTFS/dev/pts
    PATH=/usr/bin:/usr/sbin chroot $ROOTFS /usr/bin/bash /chroot-install.sh
    ui_print "Success!"
}

run_install
