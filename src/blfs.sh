set -e

git_2_30_1() {
  # Dependencies:
  # cURL-7.75.0
  # asciidoc-9.1.0
  # xmlto-0.0.28
  
  wget https://www.kernel.org/pub/software/scm/git/git-2.30.1.tar.xz
  wget https://www.kernel.org/pub/software/scm/git/git-manpages-2.30.1.tar.xz
  wget https://www.kernel.org/pub/software/scm/git/git-htmldocs-2.30.1.tar.xz

  ./configure --prefix=/usr \
            --with-gitconfig=/etc/gitconfig \
            --with-python=python3 &&
  make
  make html
  make man
  make perllibdir=/usr/lib/perl5/5.32/site_perl install
  make install-man
  make htmldir=/usr/share/doc/git-2.30.1 install-html

  mkdir -vp /usr/share/doc/git-2.30.1/man-pages/{html,text}         &&
  mv        /usr/share/doc/git-2.30.1/{git*.txt,man-pages/text}     &&
  mv        /usr/share/doc/git-2.30.1/{git*.,index.,man-pages/}html &&

  mkdir -vp /usr/share/doc/git-2.30.1/technical/{html,text}         &&
  mv        /usr/share/doc/git-2.30.1/technical/{*.txt,text}        &&
  mv        /usr/share/doc/git-2.30.1/technical/{*.,}html           &&

  mkdir -vp /usr/share/doc/git-2.30.1/howto/{html,text}             &&
  mv        /usr/share/doc/git-2.30.1/howto/{*.txt,text}            &&
  mv        /usr/share/doc/git-2.30.1/howto/{*.,}html               &&

  sed -i '/^<a href=/s|howto/|&html/|' /usr/share/doc/git-2.30.1/howto-index.html &&
  sed -i '/^\* link:/s|howto/|&html/|' /usr/share/doc/git-2.30.1/howto-index.txt
}
  
curl_7_75_0() {
  wget https://curl.haxx.se/download/curl-7.75.0.tar.xz

  grep -rl '#!.*python$' | xargs sed -i '1s/python/&3/'
  ./configure --prefix=/usr                           \
              --disable-static                        \
              --enable-threaded-resolver              \
              --with-ca-path=/etc/ssl/certs &&
  make
  sudo make install &&
  rm -rf docs/examples/.deps &&
  find docs \( -name Makefile\* -o -name \*.1 -o -name \*.3 \) -exec rm {} \; &&
  install -v -d -m755 /usr/share/doc/curl-7.75.0 &&
  cp -v -R docs/*     /usr/share/doc/curl-7.75.0
}

gnutls_3_7_0() {
  # Dependencies:
  # nettle-3.7.1

  wget https://www.gnupg.org/ftp/gcrypt/gnutls/v3.7/gnutls-3.7.0.tar.xz

  ./configure --prefix=/usr \
            --docdir=/usr/share/doc/gnutls-3.7.0 \
            --disable-guile \
            --with-default-trust-store-pkcs11="pkcs11:" &&
  make
  sudo make install
  make -C doc/reference install-data-local
}

nettle_3_7_1() {
  ./configure --prefix=/usr --disable-static &&
  make
  sudo make install &&
  chmod -v 755 /usr/lib/lib{hogweed,nettle}.so &&
  install -v -m755 -d /usr/share/doc/nettle-3.7.1 &&
  install -v -m644 nettle.html /usr/shared/doc/nettle-3.7.1
}

libtasn1_4_16_0() {
  wget https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.16.0.tar.gz
  ./configure --prefix=/usr --disable-static &&
  make
  sudo make install
  make -C doc/reference install-data-local
}

libunistring_0_9_10() {
  wget https://ftp.gnu.org/gnu/libunistring/libunistring-0.9.10.tar.xz

  ./configure --prefix=/usr    \
              --disable-static \
              --docdir=/usr/share/doc/libunistring-0.9.10 &&
  make
  sudo make install
}

unbound_1_13_1() {
  wget http://www.unbound.net/downloads/unbound-1.13.1.tar.gz

  sudo groupadd -g 88 unbound &&
  useradd -c "Unbound DNS Resolver" -d /var/lib/unbound -u 88 \
          -g unbound -s /bin/false unbound
  ./configure --prefix=/usr     \
              --sysconfdir=/etc \
              --disable-static  \
              --with-pidfile=/run/unbound.pid &&
  make
  make doc
  sudo make install &&
  mv -v /usr/sbin/unbound-host /usr/bin/
  sudo install -v -m755 -d /usr/share/doc/unbound-1.13.1 &&
  install -v -m644 doc/html/* /usr/share/doc/unbound-1.13.1
}

p11_kit_0_23_22() {
  wget https://github.com/p11-glue/p11-kit/releases/download/0.23.22/p11-kit-0.23.22.tar.xz
  
  sed '20,$ d' -i trust/trust-extract-compat &&
  cat >> trust/trust-extract-compat << "EOF"
  # Copy existing anchor modifications to /etc/ssl/local
  /usr/libexec/make-ca/copy-trust-modifications

  # Generate a new trust store
  /usr/sbin/make-ca -f -g
EOF
  ./configure --prefix=/usr     \
              --sysconfdir=/etc \
              --with-trust-paths=/etc/pki/anchors &&
  make
  sudo 

  make install &&
  ln -sfv /usr/libexec/p11-kit/trust-extract-compat \
          /usr/bin/update-ca-certificates
  sudo ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so
}

libssh2_1_9_0() {
  wget https://www.libssh2.org/download/libssh2-1.9.0.tar.gz

  ./configure --prefix=/usr --disable-static &&
  make

  sudo make install
}

openldap_2_4_57() {
  wget https://www.openldap.org/software/download/OpenLDAP/openldap-release/openldap-2.4.57.tgz
  wget http://www.linuxfromscratch.org/patches/blfs/svn/openldap-2.4.57-consolidated-1.patch
  tar -xvf openldap-2.4.57.tgz
  cd openldap-2.4.57

  sudo groupadd -g 83 ldap &&
  useradd  -c "OpenLDAP Daemon Owner" \
           -d /var/lib/openldap -u 83 \
           -g ldap -s /bin/false ldap

  patch -Np1 -i ../openldap-2.4.57-consolidated-1.patch &&
  autoconf &&
  ./configure --prefix=/usr         \
              --sysconfdir=/etc     \
              --localstatedir=/var  \
              --libexecdir=/usr/lib \
              --disable-static      \
              --disable-debug       \
              --with-tls=openssl    \
              --with-cyrus-sasl     \
              --enable-dynamic      \
              --enable-crypt        \
              --enable-spasswd      \
              --enable-slapd        \
              --enable-modules      \
              --enable-rlookups     \
              --enable-backends=mod \
              --disable-ndb         \
              --disable-sql         \
              --disable-shell       \
              --disable-bdb         \
              --disable-hdb         \
              --enable-overlays=mod &&
  make depend &&
  make
  sudo make install &&
  sudo sed -e "s/\.la/.so/" -i /etc/openldap/slapd.{conf,ldif}{,.default} &&
  sudo install -v -dm700 -o ldap -g ldap /var/lib/openldap     &&
  sudo install -v -dm700 -o ldap -g ldap /etc/openldap/slapd.d &&
  sudo chmod   -v    640     /etc/openldap/slapd.{conf,ldif}   &&
  sudo chown   -v  root:ldap /etc/openldap/slapd.{conf,ldif}   &&
  sudo install -v -dm755 /usr/share/doc/openldap-2.4.57 &&
  sudo cp      -vfr      doc/{drafts,rfc,guide} \
                    /usr/share/doc/openldap-2.4.57
}

cyrus_sasl_2_1_27() {
  wget https://github.com/cyrusimap/cyrus-sasl/releases/download/cyrus-sasl-2.1.27/cyrus-sasl-2.1.27.tar.gz
  wget http://www.linuxfromscratch.org/patches/blfs/svn/cyrus-sasl-2.1.27-doc_fixes-1.patch

  tar -xvf cyrus-sasl-2.1.27.tar.gz
  cd cyrus-sasl-2.1.27.tar.gz
  patch -Np1 -i ../cyrus-sasl-2.1.27-doc_fixes-1.patch
  ./configure --prefix=/usr        \
              --sysconfdir=/etc    \
              --enable-auth-sasldb \
              --with-dbpath=/var/lib/sasl/sasldb2 \
              --with-saslauthd=/var/run/saslauthd &&
  make -j1
  sudo make install &&
  install -v -dm755                          /usr/share/doc/cyrus-sasl-2.1.27/html &&
  install -v -m644  saslauthd/LDAP_SASLAUTHD /usr/share/doc/cyrus-sasl-2.1.27      &&
  install -v -m644  doc/legacy/*.html        /usr/share/doc/cyrus-sasl-2.1.27/html &&
  install -v -dm700 /var/lib/sasl
}

glib_2_66_7() {
  wget https://download.gnome.org/sources/glib/2.66/glib-2.66.7.tar.xz --no-check-certificate
  tar -xvf glib-2.66.7.tar.xz
  cd glib-2.66.7
  mkdir build &&
  cd    build &&

  meson --prefix=/usr      \
        -Dman=true         \
        -Dselinux=disabled \
        ..                 &&
  ninja
}

libxslt_1_1_34() {
  wget http://xmlsoft.org/sources/libxslt-1.1.34.tar.gz
  sed -i s/3000/5000/ libxslt/transform.c doc/xsltproc.{1,xml} &&
  ./configure --prefix=/usr --disable-static --without-python  &&
  make
  sed -e 's@http://cdn.docbook.org/release/xsl@https://cdn.docbook.org/release/xsl-nons@' \
      -e 's@\$Date\$@31 October 2019@' -i doc/xsltproc.xml &&
  xsltproc/xsltproc --nonet doc/xsltproc.xml -o doc/xsltproc.1
  sudo make install
}

libxml2_2_9_10() {
  wget http://xmlsoft.org/sources/libxml2-2.9.10.tar.gz
  wget http://www.linuxfromscratch.org/patches/blfs/svn/libxml2-2.9.10-security_fixes-1.patch
  tar -xvf libxml2-2.9.10.tar.gz
  cd libxml2-2.9.10
  patch -p1 -i ../libxml2-2.9.10-security_fixes-1.patch
  sed -i '/if Py/{s/Py/(Py/;s/)/))/}' python/{types.c,libxml.c}
  ./configure --prefix=/usr    \
              --disable-static \
              --with-history   \
              --with-python=/usr/bin/python3 &&
  make
  sudo make install
}

docbook_xsl_nons_1_79_2_cleanup() {
  sudo rm /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2/VERSION.xsl
}

docbook_xsl_nons_1_79_2() {
  wget https://github.com/docbook/xslt10-stylesheets/releases/download/release/1.79.2/docbook-xsl-nons-1.79.2.tar.bz2 --no-check-certificate
  wget http://www.linuxfromscratch.org/patches/blfs/svn/docbook-xsl-nons-1.79.2-stack_fix-1.patch --no-check-certificate

  tar -xvf docbook-xsl-nons-1.79.2.tar.bz2
  cd docbook-xsl-nons-1.79.2

  patch -Np1 -i ../docbook-xsl-nons-1.79.2-stack_fix-1.patch

  sudo install -v -m755 -d /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2 &&
  sudo cp -v -R VERSION assembly common eclipse epub epub3 extensions fo        \
           highlighting html htmlhelp images javahelp lib manpages params  \
           profiling roundtrip slides template tests tools webhelp website \
           xhtml xhtml-1_1 xhtml5                                          \
      /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2 &&
  sudo ln -s VERSION /usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2/VERSION.xsl &&
  sudo install -v -m644 -D README \
                      /usr/share/doc/docbook-xsl-nons-1.79.2/README.txt &&
  sudo install -v -m644    RELEASE-NOTES* NEWS* \
                      /usr/share/doc/docbook-xsl-nons-1.79.2

if [ ! -d /etc/xml ]; then sudo install -v -m755 -d /etc/xml; fi &&
if [ ! -f /etc/xml/catalog ]; then
    sudo xmlcatalog --noout --create /etc/xml/catalog
fi &&

sudo xmlcatalog --noout --add "rewriteSystem" \
           "https://cdn.docbook.org/release/xsl-nons/1.79.2" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog &&

sudo xmlcatalog --noout --add "rewriteURI" \
           "https://cdn.docbook.org/release/xsl-nons/1.79.2" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog &&

sudo xmlcatalog --noout --add "rewriteSystem" \
           "https://cdn.docbook.org/release/xsl-nons/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog &&

sudo xmlcatalog --noout --add "rewriteURI" \
           "https://cdn.docbook.org/release/xsl-nons/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog &&

sudo xmlcatalog --noout --add "rewriteSystem" \
           "http://docbook.sourceforge.net/release/xsl/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog &&

sudo xmlcatalog --noout --add "rewriteURI" \
           "http://docbook.sourceforge.net/release/xsl/current" \
           "/usr/share/xml/docbook/xsl-stylesheets-nons-1.79.2" \
    /etc/xml/catalog
}

docbook_xml_4_5() {
  wget http://www.docbook.org/xml/4.5/docbook-xml-4.5.zip --no-check-certificate
  mkdir docbook-xml-4.5
  cd docbook-xml-4.5
  unzip ../docbook-xml-4.5.zip

  sudo install -v -d -m755 /usr/share/xml/docbook/xml-dtd-4.5 &&
  sudo install -v -d -m755 /etc/xml &&
  sudo chown -R root:root . &&
  sudo cp -v -af docbook.cat *.dtd ent/ *.mod \
    /usr/share/xml/docbook/xml-dtd-4.5

if [ ! -e /etc/xml/docbook ]; then
    sudo xmlcatalog --noout --create /etc/xml/docbook
fi &&
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML V4.5//EN" \
    "http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd" \
    /etc/xml/docbook &&
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//DTD DocBook XML CALS Table Model V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/calstblx.dtd" \
    /etc/xml/docbook &&
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//DTD XML Exchange Table Model 19990315//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/soextblx.dtd" \
    /etc/xml/docbook &&
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML Information Pool V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbpoolx.mod" \
    /etc/xml/docbook &&
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML Document Hierarchy V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbhierx.mod" \
    /etc/xml/docbook &&
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//ELEMENTS DocBook XML HTML Tables V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/htmltblx.mod" \
    /etc/xml/docbook &&
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Notations V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbnotnx.mod" \
    /etc/xml/docbook &&
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Character Entities V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbcentx.mod" \
    /etc/xml/docbook &&
sudo xmlcatalog --noout --add "public" \
    "-//OASIS//ENTITIES DocBook XML Additional General Entities V4.5//EN" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5/dbgenent.mod" \
    /etc/xml/docbook &&
sudo xmlcatalog --noout --add "rewriteSystem" \
    "http://www.oasis-open.org/docbook/xml/4.5" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook &&
sudo xmlcatalog --noout --add "rewriteURI" \
    "http://www.oasis-open.org/docbook/xml/4.5" \
    "file:///usr/share/xml/docbook/xml-dtd-4.5" \
    /etc/xml/docbook

if [ ! -e /etc/xml/catalog ]; then
    sudo xmlcatalog --noout --create /etc/xml/catalog
fi &&
sudo xmlcatalog --noout --add "delegatePublic" \
    "-//OASIS//ENTITIES DocBook XML" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog &&
sudo xmlcatalog --noout --add "delegatePublic" \
    "-//OASIS//DTD DocBook XML" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog &&
sudo xmlcatalog --noout --add "delegateSystem" \
    "http://www.oasis-open.org/docbook/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog &&
sudo xmlcatalog --noout --add "delegateURI" \
    "http://www.oasis-open.org/docbook/" \
    "file:///etc/xml/docbook" \
    /etc/xml/catalog
}

unzip60() {
  wget https://downloads.sourceforge.net/infozip/unzip60.tar.gz --no-check-certificate
  wget http://www.linuxfromscratch.org/patches/blfs/10.1/unzip-6.0-consolidated_fixes-1.patch
  tar -xvf unzip60.tar.gz
  cd unzip60
  patch -Np1 -i ../unzip-6.0-consolidated_fixes-1.patch
  make -f unix/Makefile generic
  sudo make prefix=/usr MANDIR=/usr/share/man/man1 \
    -f unix/Makefile install
  cd ..

}

gobject_introspection_1_66_1() {
  wget https://download.gnome.org/sources/gobject-introspection/1.66/gobject-introspection-1.66.1.tar.xz --no-check-certificate
  tar -xvf gobject-introspection-1.66.1.tar.xz
  cd gobject-introspection-1.66.1
  # Temporary disable ssl for git, to work around missing ssl
  git config --global http.sslVerify false

  mkdir build &&
  cd build &&
  meson --prefix=/usr .. &&
  ninja
  sudo ninja install
}

libxfce4util_4_16_0() {
  wget http://archive.xfce.org/src/xfce/libxfce4util/4.16/libxfce4util-4.16.0.tar.bz2 --no-check-certificate
  tar -xvf libxfce4util-4.16.0.tar.bz2
  cd libxfce4util-4.16.0
  ./configure --prefix=/usr &&
  make
  sudo make install
}

xfconf_4_16_0() {
  wget http://archive.xfce.org/src/xfce/xfconf/4.16/xfconf-4.16.0.tar.bz2 --no-check-certificate
  tar -xvf xfconf-4.16.0.tar.bz2
  cd xfconf-4.16.0
  ./configure --prefix=/usr &&
  make
  sudo make install
}

libxfce4ui_4_16_0() {
    wget http://archive.xfce.org/src/xfce/libxfce4ui/4.16/libxfce4ui-4.16.0.tar.bz2 --no-check-certificate
    tar -xvf libxfce4ui-4.16.0.tar.bz2
    cd libxfce4ui-4.16.0
    ./configure --prefix=/usr --sysconfdir=/etc &&
    make
    sudo make install
}

xorg_7() {
  export XORG_PREFIX="/usr"
  export XORG_CONFIG="--prefix=$XORG_PREFIX --sysconfdir=/etc \
    --localstatedir=/var --disable-static"  
  [ ! -d /etc/profile.d ] && sudo mkdir /etc/profile.d
cat << EOF | sudo tee /etc/profile.d/xorg.sh
XORG_PREFIX="$XORG_PREFIX"
XORG_CONFIG="--prefix=\$XORG_PREFIX --sysconfdir=/etc --localstatedir=/var --disable-static"  
export XORG_PREFIX XORG_CONFIG
EOF
  sudo chmod 644 /etc/profile.d/xorg.sh
  cat << EOF | sudo tee /etc/sudoers.d/xorg
Defaults env_keep += XORG_PREFIX
Defaults env_keep += XORG_CONFIG
EOF
}

util_macros_1_19_3() {
  wget https://www.x.org/pub/individual/util/util-macros-1.19.3.tar.bz2 --no-check-certificate
  tar -xvf util-macros-1.19.3.tar.bz2
  cd util-macros-1.19.3

  ./configure $XORG_CONFIG
  sudo make install
}

xorgproto_2020_1() {
    wget https://xorg.freedesktop.org/archive/individual/proto/xorgproto-2020.1.tar.bz2 --no-check-certificate
    tar -xvf xorgproto-2020.1.tar.bz2
    cd xorgproto-2020.1

    mkdir build &&
    cd build &&
    meson --prefix=$XORG_PREFIX -Dlegacy=true .. &&
    ninja

    cd build &&
    sudo ninja install &&
    sudo install -vdm 755 $XORG_PREFIX/share/doc/xorgproto-2020.1 &&
    sudo install -vm 644 ../[^m]*.txt ../PM_spec $XORG_PREFIX/share/doc/xorgproto-2020.1
}

libxau_1_0_9() {
  wget https://www.x.org/pub/individual/lib/libXau-1.0.9.tar.bz2 --no-check-certificate
  tar -xvf libXau-1.0.9.tar.bz2
  cd libXau-1.0.9

  ./configure $XORG_CONFIG &&
  make
  sudo make install
}

libxdmcp_1_1_3() {
  wget https://www.x.org/pub/individual/lib/libXdmcp-1.1.3.tar.bz2 --no-check-certificate
  tar -xvf libXdmcp-1.1.3.tar.bz2
  cd libXdmcp-1.1.3

  ./configure $XORG_CONFIG --docdir=/usr/share/doc/libXdmcp-1.1.3 &&
  make
  sudo make install
}

xcb_proto() {
  wget https://xorg.freedesktop.org/archive/individual/proto/xcb-proto-1.14.1.tar.xz --no-check-certificate
  tar -xvf xcb-proto-1.14.1.tar.xz
  cd xcb-proto-1.14.1

  PYTHON=python3 ./configure $XORG_CONFIG
  sudo make install
}

libxcb_1_14() {
  wget https://xorg.freedesktop.org/archive/individual/lib/libxcb-1.14.tar.xz --no-check-certificate
  tar -xvf libxcb-1.14.tar.xz
  cd libxcb-1.14

  CFLAGS="${CFLAGS:--O2 -g} -Wno-error=format-extra-args" ./configure $XORG_CONFIG \
    --without-doxygen \
    --docdir='${datadir}'/doc/libxcb-1.14 &&
  make
  sudo make install
}

as_root() {
  sudo $*
}

xorg_libraries() {
cat > lib-7.md5 << "EOF"
ce2fb8100c6647ee81451ebe388b17ad  xtrans-1.4.0.tar.bz2
f46572566e2cec801609d25f735285b7  libX11-1.7.0.tar.bz2
f5b48bb76ba327cd2a8dc7a383532a95  libXext-1.3.4.tar.bz2
4e1196275aa743d6ebd3d3d5ec1dff9c  libFS-1.0.8.tar.bz2
76d77499ee7120a56566891ca2c0dbcf  libICE-1.0.10.tar.bz2
87c7fad1c1813517979184c8ccd76628  libSM-1.2.3.tar.bz2
eeea9d5af3e6c143d0ea1721d27a5e49  libXScrnSaver-1.2.3.tar.bz2
b122ff9a7ec70c94dbbfd814899fffa5  libXt-1.2.1.tar.bz2
ac774cff8b493f566088a255dbf91201  libXmu-1.1.3.tar.bz2
6f0ecf8d103d528cfc803aa475137afa  libXpm-3.5.13.tar.bz2
e5e06eb14a608b58746bdd1c0bd7b8e3  libXaw-1.0.13.tar.bz2
07e01e046a0215574f36a3aacb148be0  libXfixes-5.0.3.tar.bz2
3fa0841ea89024719b20cd702a9b54e0  libXcomposite-0.4.5.tar.bz2
802179a76bded0b658f4e9ec5e1830a4  libXrender-0.9.10.tar.bz2
9b9be0e289130fb820aedf67705fc549  libXcursor-1.2.0.tar.bz2
e3f554267a7a04b042dc1f6352bd6d99  libXdamage-1.1.5.tar.bz2
6447db6a689fb530c218f0f8328c3abc  libfontenc-1.1.4.tar.bz2
00516bed7ec1453d56974560379fff2f  libXfont2-2.0.4.tar.bz2
4a433c24627b4ff60a4dd403a0990796  libXft-2.3.3.tar.bz2
62c4af0839072024b4b1c8cbe84216c7  libXi-1.7.10.tar.bz2
0d5f826a197dae74da67af4a9ef35885  libXinerama-1.1.4.tar.bz2
18f3b20d522f45e4dadd34afb5bea048  libXrandr-1.5.2.tar.bz2
5d6d443d1abc8e1f6fc1c57fb27729bb  libXres-1.2.0.tar.bz2
ef8c2c1d16a00bd95b9fdcef63b8a2ca  libXtst-1.2.3.tar.bz2
210b6ef30dda2256d54763136faa37b9  libXv-1.0.11.tar.bz2
3569ff7f3e26864d986d6a21147eaa58  libXvMC-1.0.12.tar.bz2
0ddeafc13b33086357cfa96fae41ee8e  libXxf86dga-1.1.5.tar.bz2
298b8fff82df17304dfdb5fe4066fe3a  libXxf86vm-1.1.4.tar.bz2
d2f1f0ec68ac3932dd7f1d9aa0a7a11c  libdmx-1.1.4.tar.bz2
b34e2cbdd6aa8f9cc3fa613fd401a6d6  libpciaccess-0.16.tar.bz2
dd7e1e946def674e78c0efbc5c7d5b3b  libxkbfile-1.1.0.tar.bz2
42dda8016943dc12aff2c03a036e0937  libxshmfence-1.3.tar.bz2
EOF
  mkdir lib &&
  cd lib &&
  grep -v '^#' ../lib-7.md5 | awk '{print $2}' | wget -i- -c \
      -B https://www.x.org/pub/individual/lib/ --no-check-certificate &&
  md5sum -c ../lib-7.md5

# bash -e
for package in $(grep -v '^#' ../lib-7.md5 | awk '{print $2}')
do
  packagedir=${package%.tar.bz2}
  tar -xf $package
  pushd $packagedir
  docdir="--docdir=$XORG_PREFIX/share/doc/$packagedir"
  case $packagedir in
    libICE* )
      ./configure $XORG_CONFIG $docdir ICE_LIBS=-lpthread
    ;;

    libXfont2-[0-9]* )
      ./configure $XORG_CONFIG $docdir --disable-devel-docs
    ;;

    libXt-[0-9]* )
      ./configure $XORG_CONFIG $docdir \
                  --with-appdefaultdir=/etc/X11/app-defaults
    ;;

    * )
      ./configure $XORG_CONFIG $docdir
    ;;
  esac
  make
  #make check 2>&1 | tee ../$packagedir-make_check.log
  as_root make install
  popd
  rm -rf $packagedir
  as_root /sbin/ldconfig
done
# exit
}

freetype_2_10_4() {
  wget https://downloads.sourceforge.net/freetype/freetype-2.10.4.tar.xz --no-check-certificate
  tar -xvf freetype-2.10.4.tar.xz
  cd freetype-2.10.4

  sed -ri "s:.*(AUX_MODULES.*valid):\1:" modules.cfg &&
  sed -r "s:.*(#.*SUBPIXEL_RENDERING) .*:\1:" \
    -i include/freetype/config/ftoption.h &&
  ./configure --prefix=/usr --enable-freetype-config --disable-static &&
  make
  sudo make install
}

fontconfig_2_13_1() {
  wget https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.1.tar.bz2 --no-check-certificate
  tar -xvf fontconfig-2.13.1.tar.bz2
  cd fontconfig-2.13.1

  ./configure --prefix=/usr        \
              --sysconfdir=/etc    \
              --localstatedir=/var \
              --disable-docs       \
              --docdir=/usr/share/doc/fontconfig-2.13.1 &&
  make

  sudo make install  
  sudo install -v -dm755 \
          /usr/share/{man/man{1,3,5},doc/fontconfig-2.13.1/fontconfig-devel} &&
  sudo install -v -m644 fc-*/*.1         /usr/share/man/man1 &&
  sudo install -v -m644 doc/*.3          /usr/share/man/man3 &&
  sudo install -v -m644 doc/fonts-conf.5 /usr/share/man/man5 &&
  sudo install -v -m644 doc/fontconfig-devel/* \
                                    /usr/share/doc/fontconfig-2.13.1/fontconfig-devel &&
  sudo install -v -m644 doc/*.{pdf,sgml,txt,html} \
                                    /usr/share/doc/fontconfig-2.13.1
}

$1
