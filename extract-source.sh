#!/bin/bash

echo "Extracting source files..."

if [ ! -d $SRCDIR ]; then
	mkdir -p $SRCDIR
fi

cd $SRCDIR

if [ ! -d binutils-${BINUTILSVER}${BINUTILSREV} ]; then
	if [[ "$ENABLE_DOWNLOAD_CACHE" != "1" ]]; then
		tar xvJpf $DOWNLOADDIR/binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz
	else
		tar xvJpf $ROOTDIR/gnu/binutils/binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz
	fi

	if [ $? -ne 0 ]; then
		rm -rf binutils-${BINUTILSVER}${BINUTILSREV}
		exit 1
	fi
	cd $SRCDIR
fi

if [ ! -d gcc-${GCCVER}${GCCREV} ]; then
	if [[ "$ENABLE_DOWNLOAD_CACHE" != "1" ]]; then
		tar xvJpf $DOWNLOADDIR/gcc-${GCCVER}${GCCREV}.tar.xz
	else
		tar xvJpf $ROOTDIR/gnu/gcc/gcc-${GCCVER}${GCCREV}.tar.xz
	fi

	if [ $? -ne 0 ]; then
		rm -rf gcc-${GCCVER}${GCCREV}
		exit 1
	fi
fi

if [ ! -d newlib-${NEWLIBVER}${NEWLIBREV} ]; then
	if [[ "$ENABLE_DOWNLOAD_CACHE" != "1" ]]; then
		tar xvJpf $DOWNLOADDIR/newlib-${NEWLIBVER}${NEWLIBREV}.tar.gz
	else
		tar xvJpf $ROOTDIR/gnu/newlib/newlib-${NEWLIBVER}${NEWLIBREV}.tar.gz
	fi

	if [ $? -ne 0 ]; then
		rm -rf newlib-${NEWLIBVER}${NEWLIBREV}
		exit 1
	fi
fi

if [ -n "${MPCVER}${MPCREV}" ]; then
	if [ ! -d mpc-${MPCVER}${MPCREV} ]; then
		if [[ "$ENABLE_DOWNLOAD_CACHE" != "1" ]]; then
			tar xvJpf $DOWNLOADDIR/mpc-${MPCVER}${MPCREV}.tar.gz
		else
			tar xvJpf $ROOTDIR/gnu/mpc/mpc-${MPCVER}${MPCREV}.tar.gz
		fi

		if [ $? -ne 0 ]; then
			rm -rf mpc-${MPCVER}${MPCREV}
			exit 1
		fi
	fi
	cp -rv mpc-${MPCVER}${MPCREV} gcc-${GCCVER}${GCCREV}/mpc
fi

if [ -n "${GDBVER}${GDBREV}" ]; then
	if [ ! -d gdb-${GDBVER}${GDBREV} ]; then
		if [[ "$ENABLE_DOWNLOAD_CACHE" != "1" ]]; then
			tar xvJpf $DOWNLOADDIR/gdb-${GDBVER}${GDBREV}.tar.gz
		else
			tar xvJpf $ROOTDIR/gnu/gdb/gdb-${GDBVER}${GDBREV}.tar.gz
		fi

		if [ $? -ne 0 ]; then
			rm -rf gdb-${GDBVER}${GDBREV}
			exit 1
		fi
	fi
	#cp -rv gdb-${GDBVER}${GDBREV} gdb-${GDBVER}${GDBREV}/gdb
fi

if [ -n "${MPFRVER}${MPFRREV}" ]; then
	if [ ! -d mpfr-${MPFRVER}${MPFRREV} ]; then
		if [[ "$ENABLE_DOWNLOAD_CACHE" != "1" ]]; then
			tar xvJpf $DOWNLOADDIR/mpfr-${MPFRVER}${MPFRREV}.tar.xz
		else
			tar xvJpf $ROOTDIR/gnu/mpfr/mpfr-${MPFRVER}${MPFRREV}.tar.xz
		fi

		if [ $? -ne 0 ]; then
			rm -rf mpfr-${MPFRVER}${MPFRREV}
			exit 1
		fi
	fi
	cp -rv mpfr-${MPFRVER}${MPFRREV} gcc-${GCCVER}${GCCREV}/mpfr
fi

if [ -n "${GMPVER}${GMPREV}" ]; then
	if [ ! -d gmp-${GMPVER} ]; then
		if [[ "$ENABLE_DOWNLOAD_CACHE" != "1" ]]; then
			tar xvJpf $DOWNLOADDIR/gmp-${GMPVER}${GMPREV}.tar.xz
		else
			tar xvJpf $ROOTDIR/gnu/gmp/gmp-${GMPVER}${GMPREV}.tar.xz
		fi

		if [ $? -ne 0 ]; then
			rm -rf gmp-${GMPVER}${GMPREV}
			exit 1
		fi
	fi
	cp -rv gmp-${GMPVER}${GMPREV} gcc-${GCCVER}${GCCREV}/gmp
fi

echo "Done"
