echo -n "5.29.sh : " >> $LFS/lfs-build/logs/log5
sh Configure -des -Dprefix=/tools -Dlibs=-lm

make
echo $? >> $LFS/lfs-build/logs/log5

cp -v perl cpan/podlators/pod2man /tools/bin
mkdir -pv /tools/lib/perl5/5.20.2
cp -Rv lib/* /tools/lib/perl5/5.20.2
