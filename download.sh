#!/bin/bash
if [ ! -d $DOWNLOADDIR ]; then
	mkdir -p $DOWNLOADDIR
fi

cd $DOWNLOADDIR

if test "`curl -V`"; then
	FETCH="curl -f -L -O -C -"
elif test "`wget -V`"; then
	FETCH="wget -c"
else
	echo "Could not find either curl or wget, please install either one to continue"
	exit 1
fi

#if test "`parallel -V`"; then
#	PARALLEL="TRUE"
#else
	PARALLEL="FALSE"
#fi

if [[ "$PARALLEL" == "FALSE" ]]; then
	$FETCH https://ftp.gnu.org/gnu/gnu-keyring.gpg

	$FETCH https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz
	$FETCH https://ftp.gnu.org/gnu/gcc/gcc-${GCCVER}${GCCREV}/gcc-${GCCVER}${GCCREV}.tar.xz.sig

	$FETCH https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz
	$FETCH https://ftp.gnu.org/gnu/gcc/gcc-${GCCVER}${GCCREV}/gcc-${GCCVER}${GCCREV}/gcc-${GCCVER}${GCCREV}.tar.xz
	$FETCH https://sourceware.org/pub/newlib/newlib-${NEWLIBVER}${NEWLIBREV}.tar.gz
	if [ -n "${MPCVER}" ]; then
		$FETCH https://ftp.gnu.org/gnu/mpc/mpc-${MPCVER}${MPCREV}.tar.gz.sig
		$FETCH https://ftp.gnu.org/gnu/mpc/mpc-${MPCVER}${MPCREV}.tar.gz
	fi
	if [ -n "${MPFRVER}" ]; then
		$FETCH https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFRVER}${MPFRREV}.tar.xz.sig
		$FETCH https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFRVER}${MPFRREV}.tar.xz
	fi
	if [ -n "${GMPVER}" ]; then
		$FETCH https://gmplib.org/download/gmp/gmp-${GMPVER}${GMPREV}.tar.xz.sig
		$FETCH https://gmplib.org/download/gmp/gmp-${GMPVER}${GMPREV}.tar.xz
	fi

fi

# GPG return status
# 1 == bad signature
# 2 == no file
gpg --verify --keyring ./gnu-keyring.gpg binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz.sig
if [ $? -ne 0 ]; then
	if [ $? -ne 0 ]; then
		echo "Failed to verify GPG signature for binutils"
		exit 1
	fi
fi

gpg --verify --keyring ./gnu-keyring.gpg gcc-${GCCVER}${GCCREV}.tar.xz.sig
if [ $? -ne 0 ]; then
	if [ $? -ne 0 ]; then
		echo "Failed to verify GPG signautre for gcc"
		exit 1
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

