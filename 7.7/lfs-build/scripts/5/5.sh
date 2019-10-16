bi=$LFS/lfs-build/scripts/buildit.sh
fi=$LFS/lfs-build/scripts/5
logspath=$LFS/lfs-build/logs

{ time $bi binutils-2.25	.tar.bz2	$fi/5.4.sh	binutils-build >$logspath/5.4.log 2>$logspath/5.4.err ;  } 2> $logspath/sbu
$bi gcc-4.9.2		.tar.bz2	$fi/5.5.sh	gcc-build	>$logspath/5.5.log	2>$logspath/5.5.err
$bi linux-3.19		.tar.xz		$fi/5.6.sh			>$logspath/5.6.log	2>$logspath/5.6.err
$bi glibc-2.21		.tar.xz		$fi/5.7.sh	glibc-build	>$logspath/5.7.log	2>$logspath/5.7.err
$bi gcc-4.9.2		.tar.bz2	$fi/5.8.sh	gcc-build	>$logspath/5.8.log	2>$logspath/5.8.err
$bi binutils-2.25	.tar.bz2	$fi/5.9.sh	binutils-build	>$logspath/5.9.log	2>$logspath/5.9.err
$bi gcc-4.9.2		.tar.bz2	$fi/5.10.sh	gcc-build	>$logspath/5.10.log	2>$logspath/5.10.err
$bi tcl8.6.3		-src.tar.gz	$fi/5.11.sh			>$logspath/5.11.log	2>$logspath/5.11.err
$bi expect5.45		.tar.gz		$fi/5.12.sh			>$logspath/5.12.log	2>$logspath/5.12.err
$bi dejagnu-1.5.2	.tar.gz		$fi/5.13.sh			>$logspath/5.13.log	2>$logspath/5.13.err
$bi check-0.9.14	.tar.gz		$fi/5.14.sh			>$logspath/5.14.log	2>$logspath/5.14.err
$bi ncurses-5.9		.tar.gz		$fi/5.15.sh			>$logspath/5.15.log	2>$logspath/5.15.err
$bi bash-4.3.30		.tar.gz		$fi/5.16.sh			>$logspath/5.16.log	2>$logspath/5.16.err
$bi bzip2-1.0.6		.tar.gz		$fi/5.17.sh			>$logspath/5.17.log	2>$logspath/5.17.err
$bi coreutils-8.23	.tar.xz		$fi/5.18.sh			>$logspath/5.18.log	2>$logspath/5.18.err
$bi diffutils-3.3	.tar.xz		$fi/5.19.sh			>$logspath/5.19.log	2>$logspath/5.19.err
$bi file-5.22		.tar.gz		$fi/5.20.sh			>$logspath/5.20.log	2>$logspath/5.20.err
$bi findutils-4.4.2	.tar.gz		$fi/5.21.sh			>$logspath/5.21.log	2>$logspath/5.21.err
$bi gawk-4.1.1		.tar.xz		$fi/5.22.sh			>$logspath/5.22.log	2>$logspath/5.22.err
$bi gettext-0.19.4	.tar.xz		$fi/5.23.sh			>$logspath/5.23.log	2>$logspath/5.23.err
$bi grep-2.21		.tar.xz		$fi/5.24.sh			>$logspath/5.24.log	2>$logspath/5.24.err
$bi gzip-1.6		.tar.xz		$fi/5.25.sh			>$logspath/5.25.log	2>$logspath/5.25.err
$bi m4-1.4.17		.tar.xz		$fi/5.26.sh			>$logspath/5.26.log	2>$logspath/5.26.err
$bi make-4.1		.tar.bz2	$fi/5.27.sh			>$logspath/5.27.log	2>$logspath/5.27.err
$bi patch-2.7.4		.tar.xz		$fi/5.28.sh			>$logspath/5.28.log	2>$logspath/5.28.err
$bi perl-5.20.2		.tar.bz2	$fi/5.29.sh			>$logspath/5.29.log	2>$logspath/5.29.err
$bi sed-4.2.2		.tar.bz2	$fi/5.30.sh			>$logspath/5.30.log	2>$logspath/5.30.err
$bi tar-1.28		.tar.xz		$fi/5.31.sh			>$logspath/5.31.log	2>$logspath/5.31.err
$bi texinfo-5.2		.tar.xz		$fi/5.32.sh			>$logspath/5.32.log	2>$logspath/5.32.err
$bi util-linux-2.26	.tar.xz		$fi/5.33.sh			>$logspath/5.33.log	2>$logspath/5.33.err
$bi xz-5.2.0		.tar.xz		$fi/5.34.sh			>$logspath/5.34.log	2>$logspath/5.34.err
$fi/5.35.sh								>$logspath/5.35.log	2>$logspath/5.35.err
