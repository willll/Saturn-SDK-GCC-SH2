#!/bin/sh
set -e

[ -d $BUILDDIR/gcc-bootstrap ] && rm -rf $BUILDDIR/gcc-bootstrap

mkdir -p $BUILDDIR/gcc-bootstrap
cd $BUILDDIR/gcc-bootstrap

export PATH=$INSTALLDIR/bin:$PATH
export CDIR=$PWD

which -- $TARGET-as || echo $TARGET-as is not in the PATH

../../sources/gcc-${GCCVER}/configure \
	--build=$BUILDMACH --host=$HOSTMACH --target=$TARGETMACH \
	--prefix=$INSTALLDIR  \
	--enable-languages=c  \
	--with-gnu-ld --with-gnu-as --with-gcc \
	--disable-shared \
	--disable-libgcj \
	--without-headers \
	--program-prefix=${PROGRAM_PREFIX} \
	--disable-libssp -disable-nls --disable-multilib \
	--with-newlib

make all-gcc -j${NCPU}
make install-gcc -j${NCPU}

cd ${CDIR}


#	--with-gmp=$INSTALLDIR \
#	--with-mpfr=$INSTALLDIR \
#	--with-mpc=$INSTALLDIR \
