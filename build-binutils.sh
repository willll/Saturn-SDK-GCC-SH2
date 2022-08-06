#!/bin/bash
set -e

[ -d $BUILDDIR/binutils ] && rm -rf $BUILDDIR/binutils

mkdir -p $BUILDDIR/binutils
cd $BUILDDIR/binutils

export CFLAGS=${BINUTILS_CFLAGS}
export CXXFLAGS="-s"

$SRCDIR/binutils-${BINUTILSVER}/configure \
	--host=$HOSTMACH --build=$BUILDMACH --target=$TARGETMACH \
	--prefix=$INSTALLDIR --with-sysroot=$SYSROOTDIR \
	--disable-werror -enable-install-libbfd \
	--program-prefix=${PROGRAM_PREFIX} --disable-multilib --with-cpu=m68000

make -j${NCPU} all
make install -j${NCPU}
