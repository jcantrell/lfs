lfs:
	qemu-img create lfs.img 20G
	qemu-system-i386 -smp 4 -m 6G -hda lfs.img -cdrom Core-10.1.iso
	rm lfs.img
