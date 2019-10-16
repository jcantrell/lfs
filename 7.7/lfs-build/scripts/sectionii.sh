sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk /dev/sda
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
#wget wally/jordan/LFS7.7/scripts/2/2.sh
source lfs-build/scripts/2/2.sh #. 2.sh
#rm 2.sh
mv lfs-build $LFS
