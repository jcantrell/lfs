echo -n "6.7.sh : " >> /lfs-build/logs/log6
make mrproper
make INSTALL_HDR_PATH=dest headers_install
echo $? >> /lfs-build/logs/log6
find dest/include \( -name .install -o -name ..install.cmd \) -delete
cp -rv dest/include/* /usr/include
