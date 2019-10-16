echo -n "5.6.sh : " >> $LFS/lfs-build/logs/log5
make mrproper
make INSTALL_HDR_PATH=dest headers_install
echo $? >> $LFS/lfs-build/logs/log5
cp -rv dest/include/* /tools/include
