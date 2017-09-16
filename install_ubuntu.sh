#!/bin/bash
DEVICE="sda6"
RELEASE=xenial
# RELEASE=artful

set -ex

if [ "$1" != "step2" ]
then
  if [ ! "$(ls -A | grep -v install_ubuntu.sh | grep -cv "$RELEASE".tar)" -eq 0 ]
  then
    echo "folder not empty";
    exit
  fi
  debootstrap "$RELEASE" .
  env -i LANG=C.UTF-8 TERM=$TERM http_proxy=$http_proxy HOME=/root /usr/sbin/chroot . /install_ubuntu.sh "step2"
  exit
fi

(cd /dev && MAKEDEV -v generic)

mount none /proc -t proc
mount devpts /dev/pts -t devpts
mount -t sysfs sysfs /sys

export PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin'

cat << EOF > /etc/fstab
# <file system>                                 <mount point>   <type>        <options>             <dump>  <pass>
UUID=$(blkid /dev/"$DEVICE" -s UUID -o value)   /               $(blkid /dev/"$DEVICE" -s TYPE -o value)   async,discard,noatime 0       1
EOF


echo "Europe/Paris" > /etc/timezone
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

export LANGUAGE=en_US.UTF-8;
export LANG=en_US.UTF-8;
export LC_ALL=en_US.UTF-8;
locale-gen en_US.UTF-8
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales

# cat << EOF > /etc/network/interfaces
# auto lo
# iface lo inet loopback
# EOF

echo ubuntu > /etc/hostname
echo "127.0.0.1       $(cat /etc/hostname)" >> /etc/hosts

cat << EOF > /etc/apt/sources.list
# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
# newer versions of the distribution.
deb http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE" main restricted
# deb-src http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE" main restricted
## Major bug fix updates produced after the final release of the
## distribution.
deb http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE"-updates main restricted
# deb-src http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE"-updates main restricted
## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team, and may not be under a free licence. Please satisfy yourself as to
## your rights to use the software. Also, please note that software in
## universe WILL NOT receive any review or updates from the Ubuntu security
## team.
deb http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE" universe
# deb-src http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE" universe
deb http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE"-updates universe
# deb-src http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE"-updates universe
## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team, and may not be under a free licence. Please satisfy yourself as to
## your rights to use the software. Also, please note that software in
## multiverse WILL NOT receive any review or updates from the Ubuntu
## security team.
deb http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE" multiverse
# deb-src http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE" multiverse
deb http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE"-updates multiverse
# deb-src http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE"-updates multiverse
## N.B. software from this repository may not have been tested as
## extensively as that contained in the main release, although it includes
## newer versions of some applications which may provide useful features.
## Also, please note that software in backports WILL NOT receive any review
## or updates from the Ubuntu security team.
deb http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE"-backports main restricted universe multiverse
# deb-src http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE"-backports main restricted universe multiverse
## Uncomment the following two lines to add software from Canonical's
## 'partner' repository.
## This software is not part of Ubuntu, but is offered by Canonical and the
## respective vendors as a service to Ubuntu users.
# deb http://archive.canonical.com/ubuntu "$RELEASE" partner
# deb-src http://archive.canonical.com/ubuntu "$RELEASE" partner

deb http://security.ubuntu.com/ubuntu "$RELEASE"-security main restricted
# deb-src http://security.ubuntu.com/ubuntu "$RELEASE"-security main restricted
deb http://security.ubuntu.com/ubuntu "$RELEASE"-security universe
# deb-src http://security.ubuntu.com/ubuntu "$RELEASE"-security universe
deb http://security.ubuntu.com/ubuntu "$RELEASE"-security multiverse
# deb-src http://security.ubuntu.com/ubuntu "$RELEASE"-security multiverse
deb http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE"-proposed multiverse restricted universe main
EOF

cat << EOF > /etc/default/keyboard
# KEYBOARD CONFIGURATION FILE

# Consult the keyboard(5) manual page.

XKBMODEL="pc105"
XKBLAYOUT="fr"
XKBVARIANT=""
XKBOPTIONS=""

BACKSPACE="guess"
EOF

cat << EOF >> /etc/initramfs-tools/initramfs.conf

#
# KEYMAP: [ y | n ]
#
# Load a keymap during the initramfs stage.
#

KEYMAP=y
EOF

apt update
apt upgrade -y


apt install -y --no-install-recommends \
  linux-image-4.11.0-13-generic \
  linux-headers-4.11.0-13-generic \
  linux-image-extra-4.11.0-13-generic \
  linux-firmware

apt install -y \
  btrfs-tools \
  casper \
  ubuntu-standard \
  curl \
  gpm \
  vim \
  git

adduser antoine --gecos "Antoine" --disabled-password
addgroup --system admin
adduser antoine admin
sed -i "/^%admin/s/ALL$/NOPASSWD:ALL/g" /etc/sudoers

apt install -y ubuntu-desktop

echo "Password for Antoine:"
passwd antoine
echo "Openning a shell in chroot"
bash
