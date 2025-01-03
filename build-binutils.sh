#!/bin/bash
set -e

[ -d $BUILDDIR/binutils ] && rm -rf $BUILDDIR/binutils

mkdir -p $BUILDDIR/binutils
cd $BUILDDIR/binutils

export CFLAGS=${BINUTILS_CFLAGS}
export CXXFLAGS="-s"

$SRCDIR/binutils-${BINUTILSVER}${BINUTILSREV}/configure \
	--disable-werror --host=$HOSTMACH --build=$BUILDMACH --target=$TARGETMACH \
	--prefix=$INSTALLDIR --with-sysroot=$SYSROOTDIR \
	--program-prefix=${PROGRAM_PREFIX} --disable-multilib --disable-nls --enable-languages=c \
	--disable-newlib-atexit-dynamic-alloc --enable-libssp

make $MAKEFLAGS
make install $MAKEFLAGS
