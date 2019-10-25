sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | sudo fdisk /dev/sda
  n   # new partition
  p   # partition
  1   # first
      # default
  +2G # 2GB partition size
  n   # new entry
  p   # partition
  2   # second
      # default
      # default
  a   #
  2   # second
  t   # 
  1   #
  82  #
  w   #
EOF

SWAPPART="/dev/sda1"
LFSPART="/dev/sda2"
mkfs -v -t ext4 "$LFSPART"
mkswap "$SWAPPART"

export LFS=/mnt/lfs
mkdir -pv $LFS
mount -v -t ext4 "$LFSPART" $LFS
/sbin/swapon -v "$SWAPPART"

mv lfs-build $LFS
