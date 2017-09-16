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

echo ubuntu > /etc/hostname
echo "127.0.0.1       $(cat /etc/hostname)" >> /etc/hosts

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

PACKAGES=(
alsa-base
alsa-utils
anacron
at-spi2-core
bc
ca-certificates
checkbox-gui
dmz-cursor-theme
doc-base
fonts-dejavu-core
fonts-freefont-ttf
foomatic-db-compressed-ppds
genisoimage
ghostscript-x
gnome-menus
gnome-session-canberra
gstreamer1.0-alsa
gstreamer1.0-plugins-base-apps
gstreamer1.0-pulseaudio
gvfs-bin
inputattach
language-selector-gnome
libatk-adaptor
libnotify-bin
libsasl2-modules
lightdm
nautilus
notify-osd
openprinting-ppds
printer-driver-pnm2ppa
pulseaudio
rfkill
software-properties-gtk
ubuntu-artwork
ubuntu-drivers-common
ubuntu-release-upgrader-gtk
ubuntu-session
ubuntu-settings
ubuntu-sounds
unity
unity-control-center
unity-greeter
unity-settings-daemon
unzip
update-manager
update-notifier
wireless-tools
wpasupplicant
xdg-user-dirs
xdg-user-dirs-gtk
xdiagnose
xkb-data
xorg
yelp
zenity
zip

acpi-support
activity-log-manager
app-install-data-partner
apport-gtk
avahi-autoipd
avahi-daemon
baobab
bluez
bluez-cups
branding-ubuntu
cups
cups-bsd
cups-client
cups-filters
eog
evince
file-roller
firefox
fonts-guru
fonts-kacst-one
fonts-khmeros-core
fonts-lao
fonts-liberation
fonts-lklug-sinhala
fonts-nanum
fonts-noto-cjk
fonts-sil-abyssinica
fonts-sil-padauk
fonts-takao-pgothic
fonts-thai-tlwg
fonts-tibetan-machine
fwupd
fwupdate
fwupdate-signed
gnome-bluetooth
gnome-calculator
gnome-font-viewer
gnome-keyring
gnome-orca
gnome-power-manager
gnome-screensaver
gnome-screenshot
gnome-system-monitor
terminator
gnupg-agent
gucharmap
gvfs-fuse
hplip
ibus
ibus-gtk
ibus-gtk3
ibus-table
im-config
kerneloops-daemon
laptop-detect
libgail-common
libnss-mdns
libpam-gnome-keyring
libproxy1-plugin-gsettings
libproxy1-plugin-networkmanager
libqt4-sql-sqlite
libwmf0.2-7-gtk
mousetweaks
network-manager-gnome
onboard
overlay-scrollbar-gtk2
pcmciautils
#plymouth-theme-ubuntu-logo
policykit-desktop-privileges
pulseaudio-module-bluetooth
pulseaudio-module-x11
python3-aptdaemon.pkcompat
qt-at-spi
seahorse
sni-qt
system-config-printer-gnome
ttf-ancient-fonts-symbola
ttf-ubuntu-font-family
ubuntu-software
whoopsie
xcursor-themes
xdg-utils
xterm
xul-ext-ubufox
zeitgeist-core
zeitgeist-datahub
)

apt install -y  "${PACKAGES[@]}"

echo "Password for Antoine:"
passwd antoine
echo "Openning a shell in chroot"
bash
