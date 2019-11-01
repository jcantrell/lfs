set -xe

ch6_35() {
  ./configure --prefix=/usr
  make
  make check # TESTSUITEFLAGS=-j`nproc
  make install
}

ch6_36() {
  ./configure --prefix=/usr    \
              --disable-static \
              --enable-libgdbm-compat
  make
  make check
  make install
}

ch6_37() {
  ./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1
  make
  make -j1 check
  make install
}

ch6_38() {
  sed -i 's|usr/bin/env |bin/|' run.sh.in
  ./configure --prefix=/usr    \
              --disable-static \
              --docdir=/usr/share/doc/expat-2.2.7
  make
  make check
  make install
  install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.2.7
}

ch6_39() {
  ./configure --prefix=/usr        \
              --localstatedir=/var \
              --disable-logger     \
              --disable-whois      \
              --disable-rcp        \
              --disable-rexec      \
              --disable-rlogin     \
              --disable-rsh        \
              --disable-servers
  make
  make check
  make install
  mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
  mv -v /usr/bin/ifconfig /sbin
}

ch6_40() {
  echo "127.0.0.1 localhost $(hostname)" > /etc/hosts
  export BUILD_ZLIB=False
  export BUILD_BZIP2=0
  sh Configure -des -Dprefix=/usr                 \
                    -Dvendorprefix=/usr           \
                    -Dman1dir=/usr/share/man/man1 \
                    -Dman3dir=/usr/share/man/man3 \
                    -Dpager="/usr/bin/less -isR"  \
                    -Duseshrplib                  \
                    -Dusethreads
  make
  make -k test
  make install
  unset BUILD_ZLIB BUILD_BZIP2
}

ch6_41() {
  perl Makefile.PL
  make
  make test
  make install
}

ch6_42() {
  sed -i 's:\\\${:\\\$\\{:' intltool-update.in
  ./configure --prefix=/usr
  make
  make check
  make install
  install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
}

ch6_43() {
  sed '361 s/{/\\{/' -i bin/autoscan.in
  ./configure --prefix=/usr
  make
  make check
  make install
}

ch6_44() {
  ./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.1
  make
  make -j4 check
  make install
}

ch6_45() {
  ./configure --prefix=/usr    \
              --disable-static \
              --docdir=/usr/share/doc/xz-5.2.4
  make
  make check
  make install
  mv -v   /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
  mv -v /usr/lib/liblzma.so.* /lib
  ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so
}

ch6_46() {
  ./configure --prefix=/usr          \
              --bindir=/bin          \
              --sysconfdir=/etc      \
              --with-rootlibdir=/lib \
              --with-xz              \
              --with-zlib
  make
  make install
  for target in depmod insmod lsmod modinfo modprobe rmmod; do
    ln -sfv ../bin/kmod /sbin/$target
  done
  ln -sfv kmod /bin/lsmod
}

ch6_47() {
  ./configure --prefix=/usr    \
              --disable-static \
              --docdir=/usr/share/doc/gettext-0.20.1
  make
  make check
  make install
  chmod -v 0755 /usr/lib/preloadable_libintl.so
}

ch6_48() {
  ./configure --prefix=/usr
  make
  make check
  make -C libelf install
  install -vm644 config/libelf.pc /usr/lib/pkgconfig
}

ch6_49() {
  sed -e '/^includesdir/ s/$(libdir).*$/$(includedir)/' \
      -i include/Makefile.in
  
  sed -e '/^includedir/ s/=.*$/=@includedir@/' \
      -e 's/^Cflags: -I${includedir}/Cflags:/' \
      -i libffi.pc.in
  ./configure --prefix=/usr --disable-static --with-gcc-arch=native
  make
  make check
  make install
}

ch6_50() {
  sed -i '/\} data/s/ =.*$/;\n    memset(\&data, 0, sizeof(data));/' \
    crypto/rand/rand_lib.c
  ./config --prefix=/usr         \
           --openssldir=/etc/ssl \
           --libdir=lib          \
           shared                \
           zlib-dynamic
  make
  make test
  sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
  make MANSUFFIX=ssl install
  mv -v /usr/share/doc/openssl /usr/share/doc/openssl-1.1.1c
  cp -vfr doc/* /usr/share/doc/openssl-1.1.1c
}

ch6_51() {
  ./configure --prefix=/usr       \
              --enable-shared     \
              --with-system-expat \
              --with-system-ffi   \
              --with-ensurepip=yes
  make
  make install
  chmod -v 755 /usr/lib/libpython3.7m.so
  chmod -v 755 /usr/lib/libpython3.so
  ln -sfv pip3.7 /usr/bin/pip3
  install -v -dm755 /usr/share/doc/python-3.7.4/html 
  
  tar --strip-components=1  \
      --no-same-owner       \
      --no-same-permissions \
      -C /usr/share/doc/python-3.7.4/html \
      -xvf ../python-3.7.4-docs-html.tar.bz2
}

ch6_52() {
  python3 configure.py --bootstrap
  
  
  ./ninja ninja_test
  ./ninja_test --gtest_filter=-SubprocessTest.SetWithLots
  
  install -vm755 ninja /usr/bin/
  install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
  install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
}

ch6_53() {
  python3 setup.py build
  python3 setup.py install --root=dest
  cp -rv dest/* /
}

ch6_54() {
  patch -Np1 -i ../coreutils-8.31-i18n-1.patch
  sed -i '/test.lock/s/^/#/' gnulib-tests/gnulib.mk
  autoreconf -fiv
  FORCE_UNSAFE_CONFIGURE=1 ./configure \
              --prefix=/usr            \
              --enable-no-install-program=kill,uptime
  make
  make NON_ROOT_USERNAME=nobody check-root
  echo "dummy:x:1000:nobody" >> /etc/group
  chown -Rv nobody . 
  su nobody -s /bin/bash \
            -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check"
  sed -i '/dummy/d' /etc/group
  make install
  mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
  mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
  mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
  mv -v /usr/bin/chroot /usr/sbin
  mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
  sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8
  
  mv -v /usr/bin/{head,nice,sleep,touch} /bin
}

ch6_55() {
  ./configure --prefix=/usr
  make
  make check
  make docdir=/usr/share/doc/check-0.12.0 install
  sed -i '1 s/tools/usr/' /usr/bin/checkmk
}

ch6_56() {
  ./configure --prefix=/usr
  make
  make check
  make install
}

ch6_57() {
  sed -i 's/extras//' Makefile.in
  ./configure --prefix=/usr
  make
  make check
  make install
  mkdir -v /usr/share/doc/gawk-5.0.1
  cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-5.0.1
}

ch6_58() {
  sed -i 's/test-lock..EXEEXT.//' tests/Makefile.in
  sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
  sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
  echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h
  ./configure --prefix=/usr --localstatedir=/var/lib/locate
  make
  make check
  make install
  mv -v /usr/bin/find /bin
  sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb
}

ch6_59() {
  PAGE=letter ./configure --prefix=/usr
  make -j1
  make install
}

ch6_60() {
  ./configure --prefix=/usr          \
              --sbindir=/sbin        \
              --sysconfdir=/etc      \
              --disable-efiemu       \
              --disable-werror
  make
  make install
  mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
}

ch6_61() {
  ./configure --prefix=/usr --sysconfdir=/etc
  make
  make install
}

ch6_62() {
  ./configure --prefix=/usr
  make
  make check
  make install
  mv -v /usr/bin/gzip /bin
}

ch6_63() {
  sed -i /ARPD/d Makefile
  rm -fv man/man8/arpd.8
  sed -i 's/.m_ipt.o//' tc/Makefile
  make
  make DOCDIR=/usr/share/doc/iproute2-5.2.0 install
}

ch6_64() {
  patch -Np1 -i ../kbd-2.2.0-backspace-1.patch
  sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
  sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in
  PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr --disable-vlock
  make
  make check
  make install
  mkdir -v       /usr/share/doc/kbd-2.2.0
  cp -R -v docs/doc/* /usr/share/doc/kbd-2.2.0
}

ch6_65() {
  ./configure --prefix=/usr
  make
  make check
  make install
}

ch6_66() {
  sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c
  ./configure --prefix=/usr
  make
  make PERL5LIB=$PWD/tests/ check
  make install
}

ch6_67() {
  ./configure --prefix=/usr
  make
  make check
  make install
}

ch6_68() {
  ./configure --prefix=/usr                        \
              --docdir=/usr/share/doc/man-db-2.8.6.1 \
              --sysconfdir=/etc                    \
              --disable-setuid                     \
              --enable-cache-owner=bin             \
              --with-browser=/usr/bin/lynx         \
              --with-vgrind=/usr/bin/vgrind        \
              --with-grap=/usr/bin/grap            \
              --with-systemdtmpfilesdir=           \
              --with-systemdsystemunitdir=
  make
  make check
  make install
}

ch6_69() {
  FORCE_UNSAFE_CONFIGURE=1  \
  ./configure --prefix=/usr \
              --bindir=/bin
  make
  make check
  make install
  make -C doc install-html docdir=/usr/share/doc/tar-1.32
}

ch6_70() {
  ./configure --prefix=/usr --disable-static
  make
  make check
  make install
  make TEXMF=/usr/share/texmf install-tex
  pushd /usr/share/info
  rm -v dir
  for f in *
    do install-info $f dir 2>/dev/null
  done
  popd
}

ch6_71() {
  echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
  ./configure --prefix=/usr
  make
  chown -Rv nobody .
  su nobody -s /bin/bash -c "LANG=en_US.UTF-8 make -j1 test" &> vim-test.log
  make install
  ln -sv vim /usr/bin/vi
  for L in  /usr/share/man/{,*/}man1/vim.1; do
      ln -sv vim.1 $(dirname $L)/vi.1
  done
  ln -sv ../vim/vim81/doc /usr/share/doc/vim-8.1.1846
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1 

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF
}

ch6_72() {
  ./configure --prefix=/usr                            \
              --exec-prefix=                           \
              --libdir=/usr/lib                        \
              --docdir=/usr/share/doc/procps-ng-3.3.15 \
              --disable-static                         \
              --disable-kill
  make
  sed -i -r 's|(pmap_initname)\\\$|\1|' testsuite/pmap.test/pmap.exp
  sed -i '/set tty/d' testsuite/pkill.test/pkill.exp
  rm testsuite/pgrep.test/pgrep.exp
  make check
  make install
  mv -v /usr/lib/libprocps.so.* /lib
  ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so
}

ch6_73() {
  mkdir -pv /var/lib/hwclock
  ./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   \
              --docdir=/usr/share/doc/util-linux-2.34 \
              --disable-chfn-chsh  \
              --disable-login      \
              --disable-nologin    \
              --disable-su         \
              --disable-setpriv    \
              --disable-runuser    \
              --disable-pylibmount \
              --disable-static     \
              --without-python     \
              --without-systemd    \
              --without-systemdsystemunitdir
  make
  
  
  chown -Rv nobody .
  su nobody -s /bin/bash -c "PATH=$PATH make -k check"
  
  make install
}

ch6_74() {
  mkdir -v build
  cd       build
  ../configure --prefix=/usr           \
               --bindir=/bin           \
               --with-root-prefix=""   \
               --enable-elf-shlibs     \
               --disable-libblkid      \
               --disable-libuuid       \
               --disable-uuidd         \
               --disable-fsck
  make
  make check
  make install
  make install-libs
  chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a
  gunzip -v /usr/share/info/libext2fs.info.gz
  install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info
  makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
  install -v -m644 doc/com_err.info /usr/share/info
  install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
  cd ..
}

ch6_75() {
  sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
  sed -i 's/union wait/int/' syslogd.c
  make
  make BINDIR=/sbin install
cat > /etc/syslog.conf << "EOF"
# Begin /etc/syslog.conf

auth,authpriv.* -/var/log/auth.log
*.*;auth,authpriv.none -/var/log/sys.log
daemon.* -/var/log/daemon.log
kern.* -/var/log/kern.log
mail.* -/var/log/mail.log
user.* -/var/log/user.log
*.emerg *

# End /etc/syslog.conf
EOF
}

ch6_76() {
  patch -Np1 -i ../sysvinit-2.95-consolidated-1.patch
  make
  make install
}

ch6_77() {
  ./configure --prefix=/usr           \
              --bindir=/sbin          \
              --sbindir=/sbin         \
              --libdir=/usr/lib       \
              --sysconfdir=/etc       \
              --libexecdir=/lib       \
              --with-rootprefix=      \
              --with-rootlibdir=/lib  \
              --enable-manpages       \
              --disable-static
  make
  mkdir -pv /lib/udev/rules.d
  mkdir -pv /etc/udev/rules.d
  make check
  make install
  tar -xvf ../udev-lfs-20171102.tar.xz
  make -f udev-lfs-20171102/Makefile.lfs install
  udevadm hwdb --update
}

ch6_79() {
save_lib="ld-2.30.so libc-2.30.so libpthread-2.30.so libthread_db-1.0.so"

cd /lib

for LIB in $save_lib; do
    objcopy --only-keep-debug $LIB $LIB.dbg 
    strip --strip-unneeded $LIB
    objcopy --add-gnu-debuglink=$LIB.dbg $LIB 
done    

save_usrlib="libquadmath.so.0.0.0 libstdc++.so.6.0.27
             libitm.so.1.0.0 libatomic.so.1.2.0" 

cd /usr/lib

for LIB in $save_usrlib; do
    objcopy --only-keep-debug $LIB $LIB.dbg
    strip --strip-unneeded $LIB
    objcopy --add-gnu-debuglink=$LIB.dbg $LIB
done

unset LIB save_lib save_usrlib
exec /tools/bin/bash
/tools/bin/find /usr/lib -type f -name \*.a \
   -exec /tools/bin/strip --strip-debug {} ';'

/tools/bin/find /lib /usr/lib -type f \( -name \*.so* -a ! -name \*dbg \) \
   -exec /tools/bin/strip --strip-unneeded {} ';'

/tools/bin/find /{bin,sbin} /usr/{bin,sbin,libexec} -type f \
    -exec /tools/bin/strip --strip-all {} ';'
}
ch6_80() {
rm -rf /tmp/*
logout

chroot "$LFS" /usr/bin/env -i          \
    HOME=/root TERM="$TERM"            \
    PS1='(lfs chroot) \u:\w\$ '        \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash --login

rm -f /usr/lib/lib{bfd,opcodes}.a
rm -f /usr/lib/libbz2.a
rm -f /usr/lib/lib{com_err,e2p,ext2fs,ss}.a
rm -f /usr/lib/libltdl.a
rm -f /usr/lib/libfl.a
rm -f /usr/lib/libz.a
find /usr/lib /usr/libexec -name \*.la -delete
}

bs ch6_35 libtool-2.4.6   .tar.xz
bs ch6_36 gdbm-1.18.1     .tar.gz
bs ch6_37 gperf-3.1       .tar.gz
bs ch6_38 expat-2.2.7     .tar.xz
bs ch6_39 inetutils-1.9.4 .tar.xz
bs ch6_40 perl-5.30.0     .tar.xz
bs ch6_41 XML-Parser-2.44 .tar.gz
bs ch6_42 intltool-0.51.0 .tar.gz
bs ch6_43 autoconf-2.69   .tar.xz
bs ch6_44 automake-1.16.1 .tar.xz
bs ch6_45 xz-5.2.4        .tar.xz
bs ch6_46 kmod-26         .tar.xz
bs ch6_47 gettext-0.20.1  .tar.xz
bs ch6_48 elfutils-0.177  .tar.bz2
bs ch6_49 libffi-3.2.1    .tar.gz
bs ch6_50 openssl-1.1.1c  .tar.gz
bs ch6_51 Python-3.7.4    .tar.xz
bs ch6_52 ninja-1.9.0     .tar.gz
bs ch6_53 meson-0.51.1    .tar.gz
bs ch6_54 coreutils-8.31  .tar.xz
bs ch6_55 check-0.12.0    .tar.gz
bs ch6_56 diffutils-3.7   .tar.xz
bs ch6_57 gawk-5.0.1      .tar.xz
bs ch6_58 findutils-4.6.0 .tar.gz
bs ch6_59 groff-1.22.4    .tar.gz
bs ch6_60 grub-2.04       .tar.xz
bs ch6_61 less-551        .tar.gz
bs ch6_62 gzip-1.10       .tar.xz
bs ch6_63 iproute2-5.2.0  .tar.xz
bs ch6_64 kbd-2.2.0       .tar.xz
bs ch6_65 libpipeline-1.5.1 .tar.gz
bs ch6_66 make-4.2.1      .tar.gz
bs ch6_67 patch-2.7.6     .tar.xz
bs ch6_68 man-db-2.8.6.1  .tar.xz
bs ch6_69 tar-1.32        .tar.xz
bs ch6_70 texinfo-6.6     .tar.xz
bs ch6_71 vim-8.1.1846    .tar.gz
bs ch6_72 procps-ng-3.3.15 .tar.xz
bs ch6_73 util-linux-2.34 .tar.xz
bs ch6_74 e2fsprogs-1.45.3 .tar.gz
bs ch6_75 sysklogd-1.5.1 .tar.gz
bs ch6_76 sysvinit-2.95  .tar.xz
bs ch6_77 eudev-3.2.8    .tar.gz
ch6_79
ch6_80
