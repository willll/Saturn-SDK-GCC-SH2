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

# newlib's configure.host resets newlib_cflags, so flags go in CFLAGS_FOR_TARGET.
# --enable-target-optspace adds -Os, which already defines __OPTIMIZE_SIZE__.
# One section per function/object, so links with --gc-sections drop unused code.
# newlib 1.16's top-level Makefile sets CFLAGS_FOR_TARGET itself, so pass it to
# make, with -Os: optspace does not re-add it after these flags as later newlibs do.
TFLAGS="CFLAGS_FOR_TARGET=-g -Os -ffunction-sections -fdata-sections"

$SRCDIR/newlib-${NEWLIBVER}${NEWLIBREV}/configure --prefix=$INSTALLDIR \
	--target=$TARGETMACH --build=$BUILDMACH --host=$HOSTMACH \
	--enable-newlib-nano-malloc --enable-target-optspace \
	--enable-lite-exit --disable-newlib-fvwrite-in-streamio \
	--disable-newlib-fseek-optimization --disable-newlib-unbuf-stream-opt \
	--disable-newlib-multithread --enable-newlib-nano-formatted-io --disable-newlib-io-float \
	--disable-newlib-supplied-syscalls

# newlib 1.16's makedoc is K&R C, which GCC 15 (C23 by default) rejects
make all "CC_FOR_BUILD=gcc -std=gnu89" "$TFLAGS" $MAKEFLAGS
make install "CC_FOR_BUILD=gcc -std=gnu89" "$TFLAGS" $MAKEFLAGS
