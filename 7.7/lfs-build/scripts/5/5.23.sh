echo -n "5.23.sh : " >> $LFS/lfs-build/logs/log5
cd gettext-tools
EMACS="no" ./configure --prefix=/tools --disable-shared
make -C gnulib-lib
make -C intl pluralx.c
make -C src msgfmt
make -C src msgmerge
make -C src xgettext
echo $? >> $LFS/lfs-build/logs/log5
cp -v src/{msgfmt,msgmerge,xgettext} /tools/bin
