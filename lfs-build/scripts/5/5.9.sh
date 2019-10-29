echo -n "5.9.sh : " >> $LFS/lfs-build/logs/log5
mkdir -v ../binutils-build
cd ../binutils-build

CC=$LFS_TGT-gcc                \
AR=$LFS_TGT-ar                 \
RANLIB=$LFS_TGT-ranlib         \
../binutils-2.25/configure     \
    --prefix=/tools            \
    --disable-nls              \
    --disable-werror           \
    --with-lib-path=/tools/lib \
    --with-sysroot

make
make install
make -C ld clean
make -C ld LIB_PATH=/usr/lib:/lib
echo $? >> $LFS/lfs-build/logs/log5
cp -v ld/ld-new /tools/bin
