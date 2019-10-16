mkfs -v -t ext4 /dev/sda2
mkswap /dev/sda1

export LFS=/mnt/lfs
mkdir -pv $LFS
mount -v -t ext4 /dev/sda2 $LFS
/sbin/swapon -v /dev/sda1

