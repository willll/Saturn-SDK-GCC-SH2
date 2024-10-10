#!/bin/bash
set -e

[ -d $BUILDDIR/gcc-final ] && rm -rf $BUILDDIR/gcc-final

mkdir $BUILDDIR/gcc-final
cd $BUILDDIR/gcc-final

export PATH=$INSTALLDIR/bin:$PATH
export CFLAGS="-s -DCOMMON_LVB_REVERSE_VIDEO=0x4000 -DCOMMON_LVB_UNDERSCORE=0x8000 -std=c99"
export CXXFLAGS="-s -DCOMMON_LVB_REVERSE_VIDEO=0x4000 -DCOMMON_LVB_UNDERSCORE=0x8000 -std=c++11"
export CDIR=$PWD

../../source/gcc-${GCCVER}${GCCREV}/configure \
	--build=$BUILDMACH --target=$TARGETMACH --host=$HOSTMACH \
	--prefix=$INSTALLDIR --enable-languages=c,c++,lto $GCC_BOOTSTRAP \
	--with-gnu-as --with-gnu-ld --disable-shared --disable-threads \
	--disable-multilib --disable-libmudflap --enable-libssp --enable-lto \
	--disable-install-libiberty \
	--disable-nls --with-newlib \
	--enable-offload-target=$TARGETMACH \
	--enable-decimal-float=no \
	--program-prefix=${PROGRAM_PREFIX} ${GCC_FINAL_FLAGS} LDFLAGS="-static"

make $MAKEFLAGS
make install $MAKEFLAGS

cd ${CDIR}
