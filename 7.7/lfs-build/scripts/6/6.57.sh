echo -n "6.57.sh : " >> /lfs-build/logs/log6
sed -i '/^TARGETS/s@arpd@@g' misc/Makefile
sed -i /ARPD/d Makefile
sed -i 's/arpd.8//' man/man8/Makefile
make
make DOCDIR=/usr/share/doc/iproute2-3.19.0 install
echo $? >> /lfs-build/logs/log6
