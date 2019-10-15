# livebsd
Live image maker for FreeBSD

## Recommended Requirements for building image
* FreeBSD 12.0-RELEASE or higher
* 20GB Storage

## Recommend Memory Requirements for using image
* 4G RAM for Xorg and a few packages

## Customize
Add more packages:
```
edit settings/packages
```

Enable or disable services:
```
edit settings/rc
```

## Build
See a list of supported releases and architectures:
```
sh ./livebsd.sh
```
Build an ISO with packages for a supported release and architecture:
```
sh ./livebsd 12.0 AMD64
```

## Burn
Burn the image to cd:
```
pkg install cdrtools
```
```
cdrecord /usr/local/livebsd/iso/livebsd.iso
```

Write the image to usb stick:
```
dd if=/dev/usr/local/livebsd/iso/livebsd.iso of=/dev/da0 bs=4m
```

## Credentials for live media
User: liveuser

Password: freebsd

Note the root user password is also freebsd unless changed using instructions above.

## Ideas for use cases

* Test your your hardware.
* Use bsdconfig to test setting up interfaces, users, enabling base services, etc.
* Install your favorite desktop packages after boot with 16GB ram or more, and rsync installed system when happy with results.
* Build your own custom rescue cd.
* Use as a platform to build live media with preinstalled packages for a desktop distribution.

## Wishlist

* Fix PXE boot support without breaking Optical & USB use cases.
* Validation of FreeBSD distribution sets without additional packages required on the host.
* Dynamic listing of FreeBSD latest releases without additional packages required on the host.
