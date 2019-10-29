echo -n "6.13.sh : " >> /lfs-build/logs/log6
expect -c "spawn ls"
mkdir -v ../binutils-build
cd ../binutils-build
../binutils-2.25/configure --prefix=/usr   \
                           --enable-shared \
                           --disable-werror
make tooldir=/usr
echo -n $? >> /lfs-build/logs/log6
make -k check
echo -n $? >> /lfs-build/logs/log6
make tooldir=/usr install
echo $? >> /lfs-build/logs/log6
