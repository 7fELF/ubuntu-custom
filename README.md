# ubuntu-custom
```
# Create a 10G filesystem in RAM
sudo mount -t tmpfs -o size=10G tmpfs chroot

# Create/Extract squashfs filesystem (to build live USB)
sudo mksquashfs chroot ./filesystem.squashfs
sudo unsquashfs -f -d chroot/ ./filesystem.squashfs
```
