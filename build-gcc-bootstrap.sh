#!/bin/sh
set -e

[ -d $BUILDDIR/gcc-bootstrap ] && rm -rf $BUILDDIR/gcc-bootstrap

mkdir -p $BUILDDIR/gcc-bootstrap
cd $BUILDDIR/gcc-bootstrap

export PATH=$INSTALLDIR/bin:$PATH
export CFLAGS="-s -DCOMMON_LVB_REVERSE_VIDEO=0x4000 -DCOMMON_LVB_UNDERSCORE=0x8000"
export CXXFLAGS="-s -DCOMMON_LVB_REVERSE_VIDEO=0x4000 -DCOMMON_LVB_UNDERSCORE=0x8000"
export CDIR=$PWD

../../source/gcc-${GCCVER}${GCCREV}/configure \
	--build=$BUILDMACH --host=$HOSTMACH --target=$TARGETMACH \
	--prefix=$INSTALLDIR --without-headers --enable-bootstrap \
	--enable-languages=c,c++ --disable-threads --disable-libmudflap \
	--with-gnu-ld --with-gnu-as --with-gcc --enable-libssp --disable-libgomp \
	--disable-nls --disable-shared --program-prefix=${PROGRAM_PREFIX} \
	--with-newlib --disable-multilib --disable-libgcj \
	--without-included-gettext --disable-libstdcxx --disable-lto \
	${GCC_BOOTSTRAP_FLAGS}

make all-gcc $MAKEFLAGS
make install-gcc $MAKEFLAGS

make all-target-libgcc $MAKEFLAGS
make install-target-libgcc $MAKEFLAGS

cd ${CDIR}
