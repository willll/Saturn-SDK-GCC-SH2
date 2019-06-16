#!/bin/bash

echo "Extracting source files..."

if [ ! -d $SRCDIR ]; then
	mkdir -p $SRCDIR
fi

cd $SRCDIR

if [ ! -d binutils-${BINUTILSVER} ]; then
	tar xvJpf $DOWNLOADDIR/binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz
	if [ $? -ne 0 ]; then
		rm -rf binutils-${BINUTILSVER}
		exit 1
	fi
	cd $SRCDIR
fi

if [ ! -d gcc-${GCCVER} ]; then
	tar xvJpf $DOWNLOADDIR/gcc-${GCCVER}${GCCREV}.tar.xz
	if [ $? -ne 0 ]; then
		rm -rf gcc-${GCCVER}
		exit 1
	fi
fi

if [ ! -d newlib-${NEWLIBVER} ]; then
	tar xvzpf $DOWNLOADDIR/newlib-${NEWLIBVER}${NEWLIBREV}.tar.gz
	if [ $? -ne 0 ]; then
		rm -rf newlib-${NEWLIBVER}
		exit 1
	fi
fi

if [ -n "${MPCVER}" ]; then
	if [ ! -d mpc-${MPCVER} ]; then
		tar xvpf $DOWNLOADDIR/mpc-${MPCVER}${MPCREV}.tar.gz
		if [ $? -ne 0 ]; then
			rm -rf mpc-${MPCVER}
			exit 1
		fi
	fi
	cp -rv mpc-${MPCVER} gcc-${GCCVER}/mpc
fi

if [ -n "${MPFRVER}" ]; then
	if [ ! -d mpfr-${MPFRVER} ]; then
		tar xvJpf $DOWNLOADDIR/mpfr-${MPFRVER}${MPFRREV}.tar.xz
		if [ $? -ne 0 ]; then
			rm -rf mpfr-${MPFRVER}
			exit 1
		fi
	fi
	cp -rv mpfr-${MPFRVER} gcc-${GCCVER}/mpfr
fi

if [ -n "${GMPVER}" ]; then
	if [ ! -d gmp-${GMPVER} ]; then
		tar xvJpf $DOWNLOADDIR/gmp-${GMPVER}${GMPREV}.tar.xz
		if [ $? -ne 0 ]; then
			rm -rf gmp-${GMPVER}
			exit 1
		fi
	fi
	cp -rv gmp-${GMPVER} gcc-${GCCVER}/gmp
fi

echo "Done"
