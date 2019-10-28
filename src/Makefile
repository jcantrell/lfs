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

THREADS := $(shell nproc)
RAM := $(shell free -h | sed '1d;q' | awk '{print $$7;}')
IMG := lfs.img
#echo $(RAM)
lfs:
	qemu-img create $(IMG) 20G
	qemu-system-i386 -smp $(THREADS) -m $(RAM) -hda $(IMG) -cdrom Core-10.1.iso
	rm $(IMG)
