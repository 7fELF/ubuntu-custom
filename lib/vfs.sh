#!/usr/bin/env bash

function mount_vfs {
	info "Mounting virtual file systems"
	mount -t devtmpfs devtmpfs	"$FS_ROOT/dev"
	mount -t devpts   devpts	"$FS_ROOT/dev/pts"
	mount -t proc     proc      "$FS_ROOT/proc"
	mount -t sysfs    sysfs		"$FS_ROOT/sys"
}

function umount_vfs {
	info "Unmounting virtual file systems"
	umount -l "$FS_ROOT/dev/pts"
	umount -l "$FS_ROOT/sys"
	umount -l "$FS_ROOT/dev"
	umount -l "$FS_ROOT/proc"
}
