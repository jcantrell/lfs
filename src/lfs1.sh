set -xe
# Preface: Checking host system requirements

cat > version-check.sh << "EOF"
#!/bin/bash
# Simple script to list version numbers of critical development tools
export LC_ALL=C
bash --version | head -n1 | cut -d" " -f2-4
MYSH=$(readlink -f /bin/sh)
echo "/bin/sh -> $MYSH"
echo $MYSH | grep -q bash || echo "ERROR: /bin/sh does not point to bash"
unset MYSH

echo -n "Binutils: "; ld --version | head -n1 | cut -d" " -f3-
bison --version | head -n1

if [ -h /usr/bin/yacc ]; then
  echo "/usr/bin/yacc -> `readlink -f /usr/bin/yacc`";
elif [ -x /usr/bin/yacc ]; then
  echo yacc is `/usr/bin/yacc --version | head -n1`
else
  echo "yacc not found" 
fi

bzip2 --version 2>&1 < /dev/null | head -n1 | cut -d" " -f1,6-
echo -n "Coreutils: "; chown --version | head -n1 | cut -d")" -f2
diff --version | head -n1
find --version | head -n1
gawk --version | head -n1

if [ -h /usr/bin/awk ]; then
  echo "/usr/bin/awk -> `readlink -f /usr/bin/awk`";
elif [ -x /usr/bin/awk ]; then
  echo awk is `/usr/bin/awk --version | head -n1`
else 
  echo "awk not found" 
fi

gcc --version | head -n1
g++ --version | head -n1
ldd --version | head -n1 | cut -d" " -f2-  # glibc version
grep --version | head -n1
gzip --version | head -n1
cat /proc/version
m4 --version | head -n1
make --version | head -n1
patch --version | head -n1
echo Perl `perl -V:version`
python3 --version
sed --version | head -n1
tar --version | head -n1
makeinfo --version | head -n1  # texinfo version
xz --version | head -n1

echo 'int main(){}' > dummy.c && g++ -o dummy dummy.c
if [ -x dummy ]
  then echo "g++ compilation OK";
  else echo "g++ compilation failed"; fi
rm -f dummy.c dummy
EOF

bash version-check.sh
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

# Chapter 2
SWAPPART="/dev/sda1"
LFSPART="/dev/sda2"
sudo mkfs -v -t ext4 "$LFSPART"
mkswap "$SWAPPART"

export LFS=/mnt/lfs
mkdir -pv $LFS
sudo mount -v -t ext4 "$LFSPART" $LFS
#sudo /sbin/swapon -v "$SWAPPART"
sudo /sbin/swapon "$SWAPPART"

# Chapter 3 - Packages and Patches
mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources

wget --input-file=wget-list-local --continue --directory-prefix=$LFS/sources
#mv $LFS/lfs-build/tarballs/* $LFS/sources

# Place md5sums file in sources directory
#wget wally/jordan/LFS7.7/md5sums
cp md5sums $LFS/sources

pushd $LFS/sources
md5sum -c md5sums
popd

# Chapter 4 - Final Preparations
mkdir -v $LFS/tools
ln -sv $LFS/tools /
#groupadd lfs
addgroup lfs
#useradd -s /bin/bash -g lfs -m -k /dev/null lfs
adduser -s /bin/bash -G lfs lfs
#passwd lfs
chown -v lfs $LFS/tools
chown -v lfs $LFS/sources
su - lfs # make sure to run lfs2.sh as user lfs - could we pass the file to su?
