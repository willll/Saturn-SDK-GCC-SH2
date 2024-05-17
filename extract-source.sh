#!/bin/bash

echo "Extracting source files..."

if [ ! -d $SRCDIR ]; then
	mkdir -p $SRCDIR
fi

cd $SRCDIR

if [ ! -d binutils-${BINUTILSVER}${BINUTILSREV} ]; then
	tar xvJpf $DOWNLOADDIR/binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz
	if [ $? -ne 0 ]; then
		rm -rf binutils-${BINUTILSVER}${BINUTILSREV}
		exit 1
	fi
	cd $SRCDIR
fi

if [ ! -d gcc-${GCCVER}${GCCREV} ]; then
	tar xvJpf $DOWNLOADDIR/gcc-${GCCVER}${GCCREV}.tar.xz
	if [ $? -ne 0 ]; then
		rm -rf gcc-${GCCVER}${GCCREV}
		exit 1
	fi
fi

if [ ! -d newlib-${NEWLIBVER}${NEWLIBREV} ]; then
	tar xvzpf $DOWNLOADDIR/newlib-${NEWLIBVER}${NEWLIBREV}.tar.gz
	if [ $? -ne 0 ]; then
		rm -rf newlib-${NEWLIBVER}${NEWLIBREV}
		exit 1
	fi
fi

if [ -n "${MPCVER}${MPCREV}" ]; then
	if [ ! -d mpc-${MPCVER}${MPCREV} ]; then
		tar xvpf $DOWNLOADDIR/mpc-${MPCVER}${MPCREV}.tar.gz
		if [ $? -ne 0 ]; then
			rm -rf mpc-${MPCVER}${MPCREV}
			exit 1
		fi
	fi
	cp -rv mpc-${MPCVER}${MPCREV} gcc-${GCCVER}${GCCREV}/mpc
fi

if [ -n "${GDBVER}${GDBREV}" ]; then
	if [ ! -d gdb-${GDBVER}${GDBREV} ]; then
		tar xvpf $DOWNLOADDIR/gdb-${GDBVER}${GDBREV}.tar.gz
		if [ $? -ne 0 ]; then
			rm -rf gdb-${GDBVER}${GDBREV}
			exit 1
		fi
	fi
	#cp -rv gdb-${GDBVER}${GDBREV} gdb-${GDBVER}${GDBREV}/gdb
fi

if [ -n "${MPFRVER}${MPFRREV}" ]; then
	if [ ! -d mpfr-${MPFRVER}${MPFRREV} ]; then
		tar xvJpf $DOWNLOADDIR/mpfr-${MPFRVER}${MPFRREV}.tar.xz
		if [ $? -ne 0 ]; then
			rm -rf mpfr-${MPFRVER}${MPFRREV}
			exit 1
		fi
	fi
	cp -rv mpfr-${MPFRVER}${MPFRREV} gcc-${GCCVER}${GCCREV}/mpfr
fi

if [ -n "${GMPVER}${GMPREV}" ]; then
	if [ ! -d gmp-${GMPVER} ]; then
		tar xvJpf $DOWNLOADDIR/gmp-${GMPVER}${GMPREV}.tar.xz
		if [ $? -ne 0 ]; then
			rm -rf gmp-${GMPVER}${GMPREV}
			exit 1
		fi
	fi
	cp -rv gmp-${GMPVER}${GMPREV} gcc-${GCCVER}${GCCREV}/gmp
fi

echo "Done"
