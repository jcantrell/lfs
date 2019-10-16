echo -n "5.35.sh : " >> $LFS/lfs-build/logs/log5
strip --strip-debug /tools/lib/*
/usr/bin/strip --strip-unneeded /tools/{,s}bin/*
rm -rf /tools/{,share}/{info,man,doc}
echo $? >> $LFS/lfs-build/logs/log5
