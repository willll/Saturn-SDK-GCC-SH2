#!/bin/sh
set -e

[ -d $BUILDDIR/newlib ] && rm -rf $BUILDDIR/newlib

mkdir -p $BUILDDIR/newlib
cd $BUILDDIR/newlib

export PATH=$INSTALLDIR/bin:$PATH

export CROSS=${PROGRAM_PREFIX}
export CC_FOR_TARGET=${CROSS}gcc
export LD_FOR_TARGET=${CROSS}ld
export AS_FOR_TARGET=${CROSS}as
export AR_FOR_TARGET=${CROSS}ar
export RANLIB_FOR_TARGET=${CROSS}ranlib

export newlib_cflags="${newlib_cflags} -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__"

$SRCDIR/newlib-${NEWLIBVER}/configure --prefix=$INSTALLDIR \
	--target=$TARGETMACH --build=$BUILDMACH --host=$HOSTMACH \
  --with-cpu=m68000 --disable-werror --disable-multilib \
	--disable-libquadmath --disable-libquadmath-support \
	--disable-libstdcxx --disable-newlib-fvwrite-in-streamio \
	--disable-newlib-fseek-optimization --disable-newlib-wide-orient \
	--disable-newlib-unbuf-stream-opt \
	--disable-newlib-multithread --disable-newlib-io-float \
	--disable-newlib-supplied-syscalls

make all -j${NCPU}
make install -j${NCPU}
