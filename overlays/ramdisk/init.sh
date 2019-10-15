#!/bin/sh

PATH="/rescue"

if [ "`ps -o command 1 | tail -n 1 | ( read c o; echo ${o} )`" = "-s" ]; then
	echo "==> Running in single-user mode"
	SINGLE_USER="true"
fi

echo "==> Remount rootfs as read-write"
mount -u -w /

echo "==> Make mountpoints"
mkdir -p /cdrom /memdisk /sysroot

echo "Waiting for LIVEBSD media to initialize"
while : ; do
    [ -e "/dev/iso9660/LIVEBSD" ] && echo "found /dev/iso9660/LIVEBSD" && break
    sleep 1
done

echo "==> Mount cdrom"
mount_cd9660 /dev/iso9660/LIVEBSD /cdrom
mdmfs -P -F /cdrom/data/system.uzip -o ro md.uzip /sysroot

echo "--> Remount tmp with tmpfs"
mount -t tmpfs tmpfs /sysroot/tmp

echo "->> Remount var with tmpfs"
mount -t tmpfs tmpfs /sysroot/var

echo "->> Remount home with tmpfs"
mount -t tmpfs tmpfs /sysroot/usr/home

echo "--> Extract etc from uzip"
tar -zcf /sysroot/tmp/etc.txz -C /sysroot/etc .

echo "--> Extract root from uzip"
tar -zcf /sysroot/tmp/root.txz -C /sysroot/root .

echo "--> Extract prefix from uzip"
tar -zcf /sysroot/tmp/prefix.txz -C /sysroot/usr/local .

echo "--> Remount etc with tmpfs"
mount -t tmpfs tmpfs /sysroot/etc

echo "--> Remount root with tmpfs"
mount -t tmpfs tmpfs /sysroot/root

echo "--> remount prefix with tmpfs"
mount -t tmpfs tmpfs /sysroot/usr/local

echo "--> Restore etc into writable layer"
tar -xf /sysroot/tmp/etc.txz -C /sysroot/etc/

echo "--> Restore root into writable layer"
tar -xf /sysroot/tmp/root.txz -C /sysroot/root/

echo "->> Restore prefix into writable layer"
tar -xf /sysroot/tmp/prefix.txz -C /sysroot/usr/local/

echo "==> Mount devfs"
mount -t devfs devfs /sysroot/dev

if [ "$SINGLE_USER" = "true" ]; then
	echo "Starting interactive shell in temporary rootfs ..."
	sh
fi

kenv init_shell="/bin/sh"
exit 0
