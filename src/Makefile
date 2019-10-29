# available system memory:
# free -h | sed '1d;q' | awk '{print $7;}'
# available processors:
# nproc
#
# lfs: after boot run
# time sh setup.sh
# git clone pi@10.0.0.133:/srv/git/lfs
# sudo bash lfs/7.7/src/lfs1.sh
# git clone pi@10.0.0.133:/srv/git/lfs
# bash lfs/7.7/src/lfs2.sh
lfs:
	qemu-img create lfs.img 20G
	qemu-system-i386 -smp 4 -m 6G -hda lfs.img -cdrom Core-10.1.iso
	rm lfs.img
