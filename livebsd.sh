#!/bin/sh

cwd="`realpath | sed 's|/scripts||g'`"
workdir="/usr/local"
livecd="${workdir}/livebsd"
cache="${livecd}/cache"
version=$1
arch=$2
base="${cache}/${version}/base"
packages="${cache}/${version}/packages"
iso="${livecd}/iso"
uzip="${livecd}/uzip"
cdroot="${livecd}/cdroot"
ramdisk_root="${cdroot}/data/ramdisk"
vol="livebsd"
label="LIVEBSD"
isopath="${iso}/${vol}.iso"

# Only run as superuser
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Clean up any sentinals from previous validation checks
if [ -f "/tmp/badver" ] ; then
  rm /tmp/badver
fi

if [ -f "/tmp/badarch" ] ; then
  rm /tmp/badarch
fi

# Functions to print supported and create sentinal when bad input is chosen
print_supported_versions()
{
  echo "Please specify a FreeBSD release to fetch..."
  echo "Supported versions are:"
  echo "12.0"
  touch "/tmp/badver"
}

print_supported_arch()
{
  echo "Please specify which architecture"
  echo "Supported architectures are:"
  echo "AMD64"
  touch "/tmp/badarch"
}

# Check for valid input and print supported using functions above
case $version in
   12.0) echo "12.0-RELEASE selected" ;;
      *) print_supported_versions ;;
esac

case $arch in
  AMD64) echo "AMD64 selected" ;;
      *) print_supported_arch ;;
esac

# Check for sentinals and exit here if input is bad
if [ -f "/tmp/badver" ] ; then
  exit 1
fi

if [ -f "/tmp/badarch" ] ; then
  exit 1
fi

workspace()
{
  umount ${uzip}/var/cache/pkg >/dev/null 2>/dev/null
  umount ${uzip}/dev >/dev/null 2>/dev/null
  if [ -d "${livecd}" ] ;then
    chflags -R noschg ${uzip} ${cdroot} >/dev/null 2>/dev/null
    rm -rf ${uzip} ${cdroot} >/dev/null 2>/dev/null
  fi
  mkdir -p ${livecd} ${base} ${iso} ${packages} ${uzip} ${ramdisk_root}/dev ${ramdisk_root}/etc >/dev/null 2>/dev/null
}

base()
{
  if [ ! -f "${base}/base.txz" ] ; then 
    cd ${base}
    fetch http://ftp.freebsd.org/pub/FreeBSD/releases/amd64/${version}-RELEASE/base.txz
  fi
  
  if [ ! -f "${base}/kernel.txz" ] ; then
    cd ${base}
    fetch http://ftp.freebsd.org/pub/FreeBSD/releases/amd64/${version}-RELEASE/kernel.txz
  fi
  cd ${base}
  tar -zxvf base.txz -C ${uzip}
  tar -zxvf kernel.txz -C ${uzip}
  touch ${uzip}/etc/fstab
}

packages()
{
  cp /etc/resolv.conf ${uzip}/etc/resolv.conf
  mkdir ${uzip}/var/cache/pkg
  mount_nullfs ${packages} ${uzip}/var/cache/pkg
  mount -t devfs devfs ${uzip}/dev
  cat ${cwd}/settings/packages | xargs pkg-static -c ${uzip} install -y
  rm ${uzip}/etc/resolv.conf
  umount ${uzip}/var/cache/pkg
  umount ${uzip}/dev || true
}

rc()
{
  if [ ! -f "${uzip}/etc/rc.conf" ] ; then
    touch ${uzip}/etc/rc.conf
  fi
  cat ${cwd}/settings/rc | xargs chroot ${uzip} sysrc -f /etc/rc.conf
}

user()
{
  chroot ${uzip} echo freebsd | chroot ${uzip} pw mod user root -h 0
  chroot ${uzip} pw useradd liveuser \
  -c "Live User" -d "/home/liveuser" \
  -g wheel -G operator -m -s /bin/csh -k /usr/share/skel -w none
  chroot ${uzip} echo freebsd | chroot ${uzip} pw mod user liveuser -h 0
}

uzip() 
{
  mkdir ${uzip}/usr/home
  ln -s /usr/home ${uzip}/home
  install -o root -g wheel -m 755 -d "${cdroot}"
  makefs "${cdroot}/data/system.ufs" "${uzip}"
  mkuzip -o "${cdroot}/data/system.uzip" "${cdroot}/data/system.ufs"
  rm -f "${cdroot}/data/system.ufs"
}

ramdisk() 
{
  cp -R ${cwd}/overlays/ramdisk/ ${ramdisk_root}
  cd "${uzip}" && tar -cf - rescue | tar -xf - -C "${ramdisk_root}"
  touch "${ramdisk_root}/etc/fstab"
  makefs -b '10%' "${cdroot}/data/ramdisk.ufs" "${ramdisk_root}"
  gzip "${cdroot}/data/ramdisk.ufs"
  rm -rf "${ramdisk_root}"
}

boot() 
{
  cp -R ${cwd}/overlays/boot/ ${cdroot}
  cd "${uzip}" && tar -cf - --exclude boot/kernel boot | tar -xf - -C "${cdroot}"
  for kfile in kernel geom_uzip.ko nullfs.ko tmpfs.ko unionfs.ko; do
  tar -cf - boot/kernel/${kfile} | tar -xf - -C "${cdroot}"
  done
}

image() 
{
  sh ${cwd}/scripts/mkisoimages.sh -b $label $isopath ${cdroot}
}

cleanup()
{
  if [ -d "${livecd}" ] ;then
    chflags -R noschg ${uzip} ${cdroot} >/dev/null 2>/dev/null
    rm -rf ${uzip} ${cdroot} >/dev/null 2>/dev/null
  fi
}

workspace
base
packages
rc
user
uzip
ramdisk
boot
image
cleanup
