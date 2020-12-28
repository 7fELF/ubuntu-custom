#!/bin/bash
source "$(dirname "$0")/lib/import.sh"

import log
import vfs
import env

command -v debootstrap > /dev/null || fatal "Please install debootstrap"

function help {
	cat <<- EOF
	Set of tools to install ubuntu manually

	Usage:
	  $0 [command]

	Available commands:
	install      installs ubuntu
	chroot       chroot(8) to the new system
	clean        removes FS_ROOT
	unmount      unmounts the virtual filesystems and FS_ROOT
	tmps_create  mounts a 10G tmps on FS_ROOT
	EOF
}

PACKAGES=(
linux-firmware
linux-headers-generic
linux-image-generic grub-pc-

ubuntu-restricted-extras
gpm

btrfs-progs
casper
ubuntu-desktop-minimal
ubuntu-standard
curl
vim
git
)

function set_locales {
	info "Setting up locales"
	LANGUAGE=en_US.UTF-8 LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 DEBIAN_FRONTEND=noninteractive chroot "$FS_ROOT" dpkg-reconfigure locales
}

function set_timezone {
	info "Setting up timezone $TIMEZONE"
	echo "$TIMEZONE" > "$FS_ROOT/etc/timezone"
	chroot_run ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
	chroot_run dpkg-reconfigure -f noninteractive tzdata
}

function set_keyboard {
	info "Setting-up keyboard $KBLAYOUT"
	cat << EOF > "$FS_ROOT/etc/default/keyboard"
# KEYBOARD CONFIGURATION FILE
# Consult the keyboard(5) manual page.
XKBMODEL="pc105"
XKBLAYOUT="$KBLAYOUT"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
EOF

cat << EOF >> "$FS_ROOT/etc/initramfs-tools/initramfs.conf"

#
# KEYMAP: [ y | n ]
#
# Load a keymap during the initramfs stage.
#

KEYMAP=y
EOF
}

function set_apt_repos {
cat << EOF > "$FS_ROOT/etc/apt/sources.list"
deb http://fr.archive.ubuntu.com/ubuntu/ $RELEASE main restricted
# deb-src http://fr.archive.ubuntu.com/ubuntu/ $RELEASE main restricted

deb http://fr.archive.ubuntu.com/ubuntu/ $RELEASE-updates main restricted
# deb-src http://fr.archive.ubuntu.com/ubuntu/ $RELEASE-updates main restricted

deb http://fr.archive.ubuntu.com/ubuntu/ $RELEASE universe
# deb-src http://fr.archive.ubuntu.com/ubuntu/ $RELEASE universe

deb http://fr.archive.ubuntu.com/ubuntu/ $RELEASE-updates universe
# deb-src http://fr.archive.ubuntu.com/ubuntu/ $RELEASE-updates universe

deb http://fr.archive.ubuntu.com/ubuntu/ $RELEASE multiverse
# deb-src http://fr.archive.ubuntu.com/ubuntu/ $RELEASE multiverse

deb http://fr.archive.ubuntu.com/ubuntu/ $RELEASE-updates multiverse
# deb-src http://fr.archive.ubuntu.com/ubuntu/ $RELEASE-updates multiverse

deb http://fr.archive.ubuntu.com/ubuntu/ $RELEASE-backports main restricted universe multiverse
# deb-src http://fr.archive.ubuntu.com/ubuntu/ $RELEASE-backports main restricted universe multiverse

# deb http://archive.canonical.com/ubuntu $RELEASE partner
# deb-src http://archive.canonical.com/ubuntu $RELEASE partner

deb http://security.ubuntu.com/ubuntu $RELEASE-security main restricted
# deb-src http://security.ubuntu.com/ubuntu $RELEASE-security main restricted

deb http://security.ubuntu.com/ubuntu $RELEASE-security universe
# deb-src http://security.ubuntu.com/ubuntu $RELEASE-security universe

deb http://security.ubuntu.com/ubuntu $RELEASE-security multiverse
# deb-src http://security.ubuntu.com/ubuntu $RELEASE-security multiverse
deb http://fr.archive.ubuntu.com/ubuntu/ $RELEASE-proposed multiverse restricted universe main
EOF
chroot_run apt update
}

function create_user {
	info "Creating user $USERNAME"
	chroot_run adduser $USERNAME --gecos ${USERNAME^} --disabled-password

	info "Creating group admin"
	chroot_run addgroup --system admin
	info "Adding $USERNAME to group admin"
	chroot_run adduser $USERNAME admin
	sed -i "/^%admin/s/ALL$/NOPASSWD:ALL/g" "$FS_ROOT/etc/sudoers"

	if [ -z "$NOPASSWD" ]
	then
	info "No password set for $USERNAME"
	else
		info "Password for $USERNAME:"
	chroot_run passwd "$USERNAME"
	fi
}

function install {
	set -e

	warn "Installing Ubuntu $RELEASE in folder \"$FS_ROOT\""
	[[ ! -d "$FS_ROOT" ]] && warn "The installation folder does not exists, it will be created"
	[[ ! -d "$CACHE_DIR" ]] && warn "The cache folder \"$CACHE_DIR\" does not exists, it will be created"
    read -r -p "Are you sure? [y/N] " response
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]
    then
        fatal "Cancelled"
    fi

	mkdir -p "$FS_ROOT"
	mkdir -p "$CACHE_DIR"

	debootstrap --cache-dir="$CACHE_DIR" "$RELEASE" "$FS_ROOT" || fatal "Debootstrap failed"
	mount_vfs
	set_locales
	set_timezone
	set_apt_repos

	chroot_run apt upgrade -y
	chroot_run apt install -y "${PACKAGES[@]}"
	rm "$FS_ROOT/etc/xdg/autostart/gnome-initial-setup-first-login.desktop"

	set_keyboard
	echo $HOSTNAME > "$FS_ROOT/etc/hostname"
	echo "127.0.0.1       $HOSTNAME" >> "$FS_ROOT/etc/hosts"



	gen_fstab

	create_user

	umount_vfs
	success "Success"
}

function gen_fstab {
	# TODO swap
	# TODO partitioning
	# TODO encryption

	info "Generating fstab"

	if [ "$DEVICE_UUID" = "auto" ]
	then
		DEVICE=${DEVICE:-"$(df "$FS_ROOT" --output=source | tail -n 1 | sed "s/\/dev\///")"}
		DEVICE_UUID="UUID=$(blkid /dev/"$DEVICE" -s UUID -o value)" || error "Device $DEVICE not found"
	fi
	set_default DEVICE_FILESYSTEM "$(blkid /dev/"$DEVICE" -s TYPE -o value)"

	local -A filesystems

	SWAP_UUID="# UUID=swap not configured"

	cat << EOF > "$FS_ROOT/etc/fstab"
# <file system>                                 <mount point>   <type>        <options>             <dump>  <pass>
$DEVICE_UUID  /				  $(printf "%-10s" "$DEVICE_FILESYSTEM")  async,discard,noatime 0       1
$SWAP		  swap            swap					sw  	      0       0
EOF

}

function chroot_run {
	DEBIAN_FRONTEND=noninteractive chroot "$FS_ROOT" "$@"
}




[ $UID -eq 0 ] || fatal "Run this as root"

set_default FS_ROOT "$PWD/root"
set_default DEVICE_UUID "auto"

args=( "${@:2}" )
case "$1" in
	"tmpfs_create")
		mount -t tmpfs -o size=10G tmpfs "$FS_ROOT"
		;;
	"umount")
		umount_vfs
		umount "$FS_ROOT"
		;;
	"install")
		set_default RELEASE focal
		set_default TARGET_HOSTNAME ubuntu
		set_default TIMEZONE "Europe/Paris"
		set_default CACHE_DIR "$PWD/cache"
		set_default USERNAME "antoine"
		set_default KBLAYOUT "fr"

		install
		;;
	"chroot")
		mount_vfs
		chroot_run "${args[@]}"
		umount_vfs
		;;
	"clean")
		info "Removing $FS_ROOT"
		sleep 3
		umount_vfs
		rm -rvf "$FS_ROOT"
		;;
	"help")
		help "$0"
		;;
	*)
		echo "unknown command"
		help "$0"
		exit 1
		;;
esac
