#!/bin/bash
set -e

export NCPU=`nproc`

[ -d $BUILDDIR/binutils ] && rm -rf $BUILDDIR/binutils

mkdir -p $BUILDDIR/binutils
cd $BUILDDIR/binutils

$SRCDIR/binutils-2.24/configure --disable-werror --build=$BUILDMACH --target=$TARGETMACH --prefix=$INSTALLDIR --with-sysroot=$SYSROOTDIR --program-prefix=${PROGRAM_PREFIX} --disable-nls --enable-languages=c

make -j${NCPU}
make install -j${NCPU}

cd $ROOTDIR