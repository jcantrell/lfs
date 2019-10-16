echo -n "6.25.sh : " >> /lfs-build/logs/log6
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /' {} \;

sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
       -e 's@/var/spool/mail@/var/mail@' etc/login.defs

sed -i 's/1000/999/' etc/useradd

./configure --sysconfdir=/etc --with-group-name-max-length=32
echo -n $? >> /lfs-build/logs/log6

make
echo -n $? >> /lfs-build/logs/log6
make install
echo $? >> /lfs-build/logs/log6

mv -v /usr/bin/passwd /bin
pwconv
grpconv
#passwd root
