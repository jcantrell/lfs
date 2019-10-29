bi=/lfs-build/scripts/buildit.sh ;
fi=/lfs-build/scripts/6 ;
logspath=/lfs-build/logs
s=/sources
ch=6.7 ;
cd $s
echo "Starting linux-3.19" ;
date
$bi linux-3.19		.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.8 ;
echo "Starting man-pages-3.7.9" ;
date
$bi man-pages-3.79	.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.9 ;
echo "Starting glibc-2.21" ;
date
$bi glibc-2.21		.tar.xz		$fi/$ch.sh	$s/glibc-build	>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.10 ;
echo "Starting adjust toolchain" ;
date
					$fi/$ch.sh;			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.11 ;
echo "Starting zlib-1.2.8" ;
date
$bi zlib-1.2.8		.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.12 ;
$bi file-5.22		.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.13 ;
$bi binutils-2.25	.tar.bz2	$fi/$ch.sh $s/binutils-build	>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.14 ;
$bi gmp-6.0.0		a.tar.xz	$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.15 ;
$bi mpfr-3.1.2		.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.16 ;
$bi mpc-1.0.2		.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.17 ;
$bi gcc-4.9.2		.tar.bz2	$fi/$ch.sh	$s/gcc-build	>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.18 ;
$bi bzip2-1.0.6		.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.19 ;
$bi pkg-config-0.28	.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.20 ;
$bi ncurses-5.9		.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.21 ;
echo "Starting attr-2.4.47" ;
date
$bi attr-2.4.47		.src.tar.gz	$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.22 ;
$bi acl-2.2.52		.src.tar.gz	$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.23 ;
$bi libcap-2.24		.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.24 ;
$bi sed-4.2.2		.tar.bz2	$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.25 ;
$bi shadow-4.2.1	.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.26 ;
$bi psmisc-22.21	.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.27 ;
$bi procps-ng-3.3.10	.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.28 ;
$bi e2fsprogs-1.42.12	.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.29 ;
$bi coreutils-8.23	.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.30 ;
$bi iana-etc-2.30	.tar.bz2	$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.31 ;
echo "Starting m4-1.4.17" ;
date
$bi m4-1.4.17		.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.32 ;
$bi flex-2.5.39		.tar.bz2	$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.33 ;
$bi bison-3.0.4		.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.34 ;
$bi grep-2.21		.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.35 ;
$bi readline-6.3	.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.36 ;
$bi bash-4.3.30		.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.37 ;
$bi bc-1.06.95		.tar.bz2	$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.38 ;
$bi libtool-2.4.6	.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.39 ;
$bi gdbm-1.11		.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.40 ;
$bi expat-2.1.0		.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.41 ;
echo "Starting inetutils-1.9.2" ;
date
$bi inetutils-1.9.2	.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.42 ;
$bi perl-5.20.2		.tar.bz2	$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.43 ;
$bi XML-Parser-2.44	.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.44 ;
$bi autoconf-2.69	.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.45 ;
$bi automake-1.15	.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.46 ;
$bi diffutils-3.3	.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.47 ;
$bi gawk-4.1.1		.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.48 ;
$bi findutils-4.4.2	.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.49 ;
$bi gettext-0.19.4	.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.50 ;
$bi intltool-0.50.2	.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.51 ;
echo "Starting gperf-3.0.4" ;
date
$bi gperf-3.0.4		.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.52 ;
$bi groff-1.22.3	.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.53 ;
$bi xz-5.2.0		.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.54 ;
$bi grub-2.02~beta2	.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.55 ;
$bi less-458		.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.56 ;
$bi gzip-1.6		.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.57 ;
$bi iproute2-3.19.0	.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.58 ;
$bi kbd-2.0.2		.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.59 ;
$bi kmod-19		.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.60 ;
$bi libpipeline-1.4.0	.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.61 ;
echo "Starting make-4.1" ;
date
$bi make-4.1		.tar.bz2	$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.62 ;
$bi patch-2.7.4		.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.63 ;
$bi sysklogd-1.5.1	.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.64 ;
$bi sysvinit-2.88dsf	.tar.bz2	$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.65 ;
$bi tar-1.28		.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.66 ;
$bi texinfo-5.2		.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.67 ;
$bi eudev-2.1.1		.tar.gz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.68 ;
$bi util-linux-2.26	.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.69 ;
$bi man-db-2.7.1	.tar.xz		$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		; ch=6.70 ;
tar -xf vim-7.4.tar.bz2;cd vim74; $fi/$ch.sh >$logspath/$ch.log 2>$logspath/$ch.err; cd ..; rm -rf vim74;
#$bi vim-7.4		.tar.bz2	$fi/$ch.sh			>$logspath/$ch.log	2>$logspath/$ch.err		;
echo "Finished vim" ;
date
