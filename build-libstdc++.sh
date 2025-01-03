#!/bin/sh
set -e

[ -d $BUILDDIR/libstdc++ ] && rm -rf $BUILDDIR/libstdc++

mkdir -p $BUILDDIR/libstdc++
cd $BUILDDIR/libstdc++

export PATH=$INSTALLDIR/bin:$PATH
export CROSS=${PROGRAM_PREFIX}
export CC=${CROSS}gcc
export CXX=${CROSS}g++
export CPP=${CROSS}cpp

export CFLAGS="-I$SRCDIR/newlib-$NEWLIBVER/newlib/libc/include"
export CXXFLAGS="-I$SRCDIR/newlib-$NEWLIBVER/newlib/libc/include"

$SRCDIR/gcc-${GCCVER}${GCCREV}/libstdc++-v3/configure \
	--host=${TARGETMACH} --build=${BUILDMACH} --target=${TARGETMACH} --with-cross-host=${HOSTMACH} \
	--prefix=${INSTALLDIR} --disable-nls --disable-multilib --disable-libstdcxx-threads \
	--with-newlib --disable-libstdcxx-pch

make $MAKEFLAGS
make install $MAKEFLAGS
