SWAPPART="/dev/sda1"
LFSPART="/dev/sda2"
mkfs -v -t ext4 /dev/sda2
mkswap /dev/sda1

export LFS=/mnt/lfs
mkdir -pv $LFS
mount -v -t ext4 "$LFSPART" $LFS
/sbin/swapon -v "$SWAPPART"
