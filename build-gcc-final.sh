#!/bin/bash
set -e

[ -d $BUILDDIR/gcc-final ] && rm -rf $BUILDDIR/gcc-final

mkdir $BUILDDIR/gcc-final
cd $BUILDDIR/gcc-final

export PATH=$INSTALLDIR/bin:$PATH
export CDIR=$PWD

../../sources/gcc-${GCCVER}/configure \
	--build=$BUILDMACH --target=$TARGETMACH --host=$HOSTMACH \
	--prefix="$INSTALLDIR" --enable-languages=c  --disable-bootstrap \
	--with-gnu-as --with-gnu-ld --disable-shared --disable-threads \
	--disable-multilib --disable-tls --disable-libssp --disable-lto \
  --with-newlib \
	--with-cpu=m68000 --disable-werror --disable-multilib \
	--program-prefix=${PROGRAM_PREFIX}

make -j${NCPU}
make install -j${NCPU}

cd ${CDIR}
