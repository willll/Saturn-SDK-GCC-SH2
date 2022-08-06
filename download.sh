#!/bin/bash
set -e

if [ ! -d $DOWNLOADDIR ]; then
	mkdir -p $DOWNLOADDIR
fi

cd $DOWNLOADDIR

if test "`curl -V`"; then
	FETCH="curl -f -L -O "
elif test "`wget -V`"; then
	FETCH="wget"
else
	echo "Could not find either curl or wget, please install either one to continue"
	exit 1
fi

function download_keyring
{
		$FETCH https://ftp.gnu.org/gnu/gnu-keyring.gpg
		if [ ! -f "gnu-keyring.gpg" ]; then
		    echo "gnu-keyring.gpg not downloaded."
		fi
}

function is_keyring_downloaded
{
	if [ ! -f "gnu-keyring.gpg" ]; then
			return 0
	fi

	return 1
}

function is_download_valid
{
		gpg --verify --keyring ./gnu-keyring.gpg $1
		if [ $? -ne 0 ]; then
			if [ $? -ne 0 ]; then
				echo "Failed to verify GPG signature for $1"
				exit 1
			fi
		fi
}

function download_binutils
{
		$FETCH https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz
		if [ ! -f "binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz" ]; then
		    echo "binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz not downloaded."
		    exit 1
		fi
}

function download_gcc
{
		$FETCH https://ftp.gnu.org/gnu/gcc/gcc-${GCCVER}${GCCREV}/gcc-${GCCVER}${GCCREV}.tar.xz
		if [ ! -f "gcc-${GCCVER}${GCCREV}.tar.xz" ]; then
		    echo "gcc-${GCCVER}${GCCREV}.tar.xz not downloaded."
		    exit 1
		fi
}

function download_newlib
{
		$FETCH https://sourceware.org/pub/newlib/newlib-${NEWLIBVER}${NEWLIBREV}.tar.gz
		if [ ! -f "newlib-${NEWLIBVER}${NEWLIBREV}.tar.gz" ]; then
		    echo "newlib-${NEWLIBVER}${NEWLIBREV}.tar.gz not downloaded."
		    exit 1
		fi
}

function download_mpc
{
		$FETCH https://ftp.gnu.org/gnu/mpc/mpc-${MPCVER}${MPCREV}.tar.gz
		if [ ! -f "mpc-${MPCVER}${MPCREV}.tar.gz" ]; then
    		echo "mpc-${MPCVER}${MPCREV}.tar.gz not downloaded."
				exit 1
		fi
}

function download_mpfr
{
		$FETCH https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFRVER}${MPFRREV}.tar.xz
		if [ ! -f "mpfr-${MPFRVER}${MPFRREV}.tar.xz" ]; then
	    		echo "mpfr-${MPFRVER}${MPFRREV}.tar.xz not downloaded."
			exit 1
		fi
}

function download_gmp
{
		$FETCH https://gmplib.org/download/gmp/gmp-${GMPVER}${GMPREV}.tar.xz
		if [ ! -f "gmp-${GMPVER}${GMPREV}.tar.xz" ]; then
	    		echo "gmp-${GMPVER}${GMPREV}.tar.xz not downloaded."
			exit 1
		fi
}

download_keyring

if [ ! -f "binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz" ] && ! is_keyring_downloaded ; then
		download_binutils
else
		$FETCH https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz.sig
		if [ ! -f "binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz.sig" ]; then
		    echo "binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz.sig not downloaded, redownloading"
				download_binutils
		else
				if ! is_download_valid "binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz.sig" ; then
						download_binutils
				fi
		fi
fi

if [ ! -f "gcc-${GCCVER}${GCCREV}.tar.xz" ] && ! is_keyring_downloaded ; then
		download_gcc
else
		$FETCH https://ftp.gnu.org/gnu/gcc/gcc-${GCCVER}${GCCREV}/gcc-${GCCVER}${GCCREV}.tar.xz.sig
		if [ ! -f "gcc-${GCCVER}${GCCREV}.tar.xz.sig" ]; then
		    echo "gcc-${GCCVER}${GCCREV}.tar.xz.sig not downloaded, redownloading"
				download_gcc
		else
				if ! is_download_valid "gcc-${GCCVER}${GCCREV}.tar.xz.sig" ; then
						download_gcc
				fi
		fi
fi

if [ ! -f "newlib-${NEWLIBVER}${NEWLIBREV}.tar.gz" ]; then
		download_newlib
fi

if [ -n "${MPCVER}" ]; then
		if [ ! -f "mpc-${MPCVER}${MPCREV}.tar.gz" ] && ! is_keyring_downloaded ; then
				download_mpc
		else
			$FETCH https://ftp.gnu.org/gnu/mpc/mpc-${MPCVER}${MPCREV}.tar.gz.sig
			if [ ! -f "mpc-${MPCVER}${MPCREV}.tar.gz.sig" ]; then
						echo "mpc-${MPCVER}${MPCREV}.tar.gz.sig not downloaded, redownloading"
						download_mpc
				else
						if ! is_download_valid "mpc-${MPCVER}${MPCREV}.tar.gz.sig" ; then
								download_mpc
						fi
				fi
		fi
fi

if [ -n "${MPFRVER}" ]; then
		if [ ! -f "mpfr-${MPFRVER}${MPFRREV}.tar.xz" ] && ! is_keyring_downloaded ; then
				download_mpfr
		else
				$FETCH https://ftp.gnu.org/gnu/mpfr/mpfr-${MPFRVER}${MPFRREV}.tar.xz.sig
				if [ ! -f "mpfr-${MPFRVER}${MPFRREV}.tar.xz.sig" ]; then
		    		echo "mpfr-${MPFRVER}${MPFRREV}.tar.xz.sig not downloaded, redownloading"
						download_mpfr
				else
						if ! is_download_valid "mpfr-${MPFRVER}${MPFRREV}.tar.xz.sig" ; then
								download_mpfr
						fi
				fi
		fi
fi

if [ -n "${GMPVER}" ]; then
		if [ ! -f "gmp-${GMPVER}${GMPREV}.tar.xz" ] && ! is_keyring_downloaded ; then
				download_gmp
		else
			$FETCH https://gmplib.org/download/gmp/gmp-${GMPVER}${GMPREV}.tar.xz.sig
			if [ ! -f "gmp-${GMPVER}${GMPREV}.tar.xz.sig" ]; then
						echo "gmp-${GMPVER}${GMPREV}.tar.xz.sig not downloaded, redownloading"
						download_gmp
				else
						if ! is_download_valid "gmp-${GMPVER}${GMPREV}.tar.xz.sig" ; then
								download_gmp
						fi
				fi
		fi
fi
