#!/bin/bash
if [ ! -d $DOWNLOADDIR ]; then
	mkdir -p $DOWNLOADDIR
fi

cd $DOWNLOADDIR

if test "`curl -V`"; then
	FETCH="curl --retry 5 --retry-delay 5 --connect-timeout 30 -f -L -O -J "
elif test "`wget -V`"; then
	FETCH="wget -tries=5 -c"
else
	echo "Could not find either curl or wget, please install either one to continue"
	exit 1
fi


$FETCH https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz.sig
if [ ! -f "binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz.sig" ]; then
    echo "binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz.sig not downloaded."
fi

$FETCH https://ftp.gnu.org/gnu/gcc/gcc-${GCCVER}${GCCREV}.tar.xz.sig
if [ ! -f "gcc-${GCCVER}${GCCREV}.tar.xz.sig" ]; then
    echo "gcc-${GCCVER}${GCCREV}.tar.xz.sig not downloaded."
fi

$FETCH https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz
if [ ! -f "binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz" ]; then
    echo "binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz not downloaded."
    exit 1
fi

$FETCH https://ftp.gnu.org/gnu/gcc/gcc-${GCCVER}${GCCREV}/gcc-${GCCVER}${GCCREV}.tar.xz
if [ ! -f "gcc-${GCCVER}${GCCREV}.tar.xz" ]; then
    echo "gcc-${GCCVER}${GCCREV}.tar.xz not downloaded."
    exit 1
fi

$FETCH https://sourceware.org/pub/newlib/newlib-${NEWLIBVER}${NEWLIBREV}.tar.gz
if [ ! -f "newlib-${NEWLIBVER}${NEWLIBREV}.tar.gz" ]; then
    echo "newlib-${NEWLIBVER}${NEWLIBREV}.tar.gz not downloaded."
    exit 1
fi

if [ -n "${GDBVER}" ]; then
	$FETCH https://ftp.gnu.org/gnu/gdb/gdb-${GDBVER}${GDBREV}.tar.gz.sig
	if [ ! -f "gdb-${GDBVER}${GDBREV}.tar.gz.sig" ]; then
				echo "gdb-${GDBVER}${GDBREV}.tar.gz.sig not downloaded."
	fi

	$FETCH https://ftp.gnu.org/gnu/gdb/gdb-${GDBVER}${GDBREV}.tar.gz
	if [ ! -f "gdb-${GDBVER}${GDBREV}.tar.gz" ]; then
    		echo "gdb-${GDBVER}${GDBREV}.tar.gz not downloaded."
		exit 1
	fi
fi

if [ -n "${MPCVER}" ]; then
	$FETCH https://ftp.gnu.org/gnu/mpc/mpc-${MPCVER}${MPCREV}.tar.gz.sig
	if [ ! -f "mpc-${MPCVER}${MPCREV}.tar.gz.sig" ]; then
    		echo "mpc-${MPCVER}${MPCREV}.tar.gz.sig not downloaded."
	fi

	$FETCH https://ftp.gnu.org/gnu/mpc/mpc-${MPCVER}${MPCREV}.tar.gz
	if [ ! -f "mpc-${MPCVER}${MPCREV}.tar.gz" ]; then
    		echo "mpc-${MPCVER}${MPCREV}.tar.gz not downloaded."
		exit 1
	fi
fi
if [ -n "${MPFRVER}" ]; then
	$FETCH https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFRVER}${MPFRREV}.tar.xz.sig
	if [ ! -f "mpfr-${MPFRVER}${MPFRREV}.tar.xz.sig" ]; then
    		echo "mpfr-${MPFRVER}${MPFRREV}.tar.xz.sig not downloaded."
	fi

	$FETCH https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFRVER}${MPFRREV}.tar.xz
	if [ ! -f "mpfr-${MPFRVER}${MPFRREV}.tar.xz" ]; then
    		echo "mpfr-${MPFRVER}${MPFRREV}.tar.xz not downloaded."
		exit 1
	fi
fi
if [ -n "${GMPVER}" ]; then
	$FETCH https://ftp.gnu.org/gnu/gmp/gmp-${GMPVER}${GMPREV}.tar.xz.sig
	if [ ! -f "gmp-${GMPVER}${GMPREV}.tar.xz.sig" ]; then
    		echo "gmp-${GMPVER}${GMPREV}.tar.xz.sig not downloaded."
	fi

	$FETCH https://ftp.gnu.org/gnu/gmp//gmp-${GMPVER}${GMPREV}.tar.xz
	if [ ! -f "gmp-${GMPVER}${GMPREV}.tar.xz" ]; then
    		echo "gmp-${GMPVER}${GMPREV}.tar.xz not downloaded."
		exit 1
	fi
fi



# Verify against the keyring in git, not one fetched from the same server as the tarballs
verify() {
	gpg --verify --keyring "$ROOTDIR/gnu/gnu-keyring.gpg" "$1" || { echo "Failed to verify GPG signature for $1"; exit 1; }
}

verify gcc-${GCCVER}${GCCREV}.tar.xz.sig
verify binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz.sig
[ -n "${GDBVER}" ] && verify gdb-${GDBVER}${GDBREV}.tar.gz.sig
[ -n "${MPCVER}" ] && verify mpc-${MPCVER}${MPCREV}.tar.gz.sig
[ -n "${MPFRVER}" ] && verify mpfr-${MPFRVER}${MPFRREV}.tar.xz.sig
[ -n "${GMPVER}" ] && verify gmp-${GMPVER}${GMPREV}.tar.xz.sig
exit 0
