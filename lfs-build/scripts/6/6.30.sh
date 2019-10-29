echo -n "6.30.sh : " >> /lfs-build/logs/log6
make
echo -n $? >> /lfs-build/logs/log6
make install
echo $? >> /lfs-build/logs/log6
