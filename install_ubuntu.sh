#!/bin/bash
set -e
set -x

 ## Manually set device
# DEVICE=sdb2

## Uncomment to use /dev/sdx format instead of UUID in fstab
# DEVICE_UUID=/dev/$DEVICE

## Manually set filesystem
# DEVICE_FILESYSTEM=ext4

## Default release, used if $RELEASE is not set
DEFAULT_RELEASE=disco
HOSTNAME=ubuntu

COLOR_ERROR='\033[0;31m'
COLOR_SUCCESS='\033[0;32m'
COLOR_WARN='\033[0;33m'
COLOR_DEFAULT='\033[0m'
function error {
    echo -e "${COLOR_ERROR}${1}${COLOR_DEFAULT}"
    exit 1
}

function warn {
    echo -e "${COLOR_WARN}${1}${COLOR_DEFAULT}"
}

[ $UID -eq 0 ] || error "Run this as root"

[ -z $RELEASE ] && warn "Warning: RELEASE not set, falling back to $DEFAULT_RELEASE" && RELEASE="$DEFAULT_RELEASE"
DEVICE=${DEVICE:-"$(df . --output=source | tail -n 1 | sed "s/\/dev\///")"}
if [ -z $DEVICE_UUID ]
then
    DEVICE_UUID="UUID=$(blkid /dev/"$DEVICE" -s UUID -o value)" || error "Device $DEVICE not found"
fi
[ -z $DEVICE_FILESYSTEM ] && DEVICE_FILESYSTEM=$(blkid /dev/"$DEVICE" -s TYPE -o value)

warn "Installing Ubuntu $RELEASE on $DEVICE ($DEVICE_UUID)"

if [ "$1" != "step2" ]
then
    read -r -p "Are you sure? [y/N] " response
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
    then
        error "Cancelled"
    fi

    if [ ! "$(ls -A | grep -v install_ubuntu.sh | grep -v "lost+found" | grep -cv "$RELEASE".tar)" -eq 0 ]
    then
        echo "folder not empty";
        exit
    fi

    debootstrap "$RELEASE" .
    env -i LANG=C.UTF-8 TERM="$TERM" http_proxy="$http_proxy" HOME=/root RELEASE=$RELEASE DEVICE_UUID=$DEVICE_UUID DEVICE_FILESYSTEM=$DEVICE_FILESYSTEM /usr/sbin/chroot . /install_ubuntu.sh "step2"
    exit
fi

mount -t devtmpfs devtmpfs  /dev
mount -t proc     proc      /proc
mount -t devpts   devpts    /dev/pts
mount -t sysfs    sysfs     /sys

export PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin'

cat << EOF > /etc/fstab
# <file system>                                 <mount point>   <type>        <options>             <dump>  <pass>
$DEVICE_UUID  /               $DEVICE_FILESYSTEM   async,discard,noatime 0       1
EOF


echo "Europe/Paris" > /etc/timezone
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

export LANGUAGE=en_US.UTF-8;
export LANG=en_US.UTF-8;
export LC_ALL=en_US.UTF-8;
locale-gen en_US.UTF-8
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales

echo $HOSTNAME > /etc/hostname
echo "127.0.0.1       $HOSTNAME" >> /etc/hosts

cat << EOF > /etc/apt/sources.list
deb http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE" main restricted
# deb-src http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE" main restricted
deb http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE"-updates main restricted
# deb-src http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE"-updates main restricted
deb http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE" universe
# deb-src http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE" universe
deb http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE"-updates universe
# deb-src http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE"-updates universe
deb http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE" multiverse
# deb-src http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE" multiverse
deb http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE"-updates multiverse
# deb-src http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE"-updates multiverse
deb http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE"-backports main restricted universe multiverse
# deb-src http://fr.archive.ubuntu.com/ubuntu/ "$RELEASE"-backports main restricted universe multiverse
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
  linux-image-generic \
  linux-headers-generic \
  linux-firmware \
  # linux-image-extra-4.15.0-15-generic \
  # linux-image-extra-*-generic \

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

PACKAGES=(
ubuntu-desktop
ubuntu-restricted-extras
)

apt install -y  "${PACKAGES[@]}"

echo "Password for Antoine:"
passwd antoine
echo "Openning a shell in chroot"
bash

echo "Unmounting virtual file systems"
umount /dev/pts
umount /dev
umount /proc
umount /sys
echo -e "${COLOR_SUCCESS}Success${COLOR_DEFAULT}"
