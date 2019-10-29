#cd /tmp 
#grub-mkrescue --output=grub-img.iso 
#xorriso -as cdrecord -v dev=/dev/cdrw blank=as_needed grub-img.iso

grub-install /dev/sda

cat > /boot/grub/grub.cfg << "EOF"
set default=0
set timeout=5

insmod ext2
set root=(hd0,2)

menuentry "GNU/Linux, Linux 3.19-lfs-7.7" {
	linux /boot/vmlinuz-3.19-lfs-7.7 root=/dev/sda4 ro
}
EOF
