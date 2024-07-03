#!/bin/bash
if [ ! -d $DOWNLOADDIR ]; then
	mkdir -p $DOWNLOADDIR
fi

cd $DOWNLOADDIR

if test "`curl -V`"; then
	FETCH="curl --retry 5 --retry-delay 5 --connect-timeout 30 5 -k -f -L -O -C -"
elif test "`wget -V`"; then
	FETCH="wget -tries=5 -c"
else
	echo "Could not find either curl or wget, please install either one to continue"
	exit 1
fi


$FETCH https://ftp.gnu.org/gnu/gnu-keyring.gpg
if [ ! -f "gnu-keyring.gpg" ]; then
    echo "gnu-keyring.gpg not downloaded."
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



# GPG return status
# 1 == bad signature
# 2 == no file


gpg --verify --keyring ./gnu-keyring.gpg gcc-${GCCVER}${GCCREV}.tar.xz.sig
if [ $? -ne 0 ]; then
	if [ $? -ne 0 ]; then
		echo "Failed to verify GPG signautre for gcc"
		exit 1
	fi
fi

gpg --verify --keyring ./gnu-keyring.gpg binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz.sig
if [ $? -ne 0 ]; then
	if [ $? -ne 0 ]; then
		echo "Failed to verify GPG signature for binutils"
		exit 1
	fi
fi

if [ -n "${GDBVER}" ]; then
	gpg --verify --keyring ./gnu-keyring.gpg gdb-${GDBVER}${GDBREV}.tar.gz.sig
	if [ $? -ne 0 ]; then
		if [ $? -ne 0 ]; then
			echo "Failed to verify GPG signautre for gdb"
			exit 1
		fi
	fi
fi

if [ -n "${MPCVER}" ]; then
	gpg --verify --keyring ./gnu-keyring.gpg mpc-${MPCVER}${MPCREV}.tar.gz.sig
	if [ $? -ne 0 ]; then
		if [ $? -ne 0 ]; then
			echo "Failed to verify GPG signautre for mpc"
			exit 1
		fi
	fi
fi

if [ -n "${MPFRVER}" ]; then
	gpg --verify --keyring ./gnu-keyring.gpg mpfr-${MPFRVER}${MPFRREV}.tar.xz.sig
	if [ $? -ne 0 ]; then
		if [ $? -ne 0 ]; then
			echo "Failed to verify GPG signautre for mpfr"
			exit 1
		fi
	fi
fi
