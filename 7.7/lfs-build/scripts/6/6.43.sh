echo -n "6.43.sh : " >> /lfs-build/logs/log6
perl Makefile.PL
make
echo -n $? >> /lfs-build/logs/log6
make test
echo -n $? >> /lfs-build/logs/log6
make install
echo $? >> /lfs-build/logs/log6
