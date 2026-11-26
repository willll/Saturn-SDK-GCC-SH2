#!/bin/bash
set -e

[ -d $BUILDDIR/gcc-final ] && rm -rf $BUILDDIR/gcc-final

mkdir $BUILDDIR/gcc-final
cd $BUILDDIR/gcc-final

export PATH=$INSTALLDIR/bin:$PATH

# See build-gcc-bootstrap.sh
export CC="${CC:-gcc} -std=gnu89 -fcommon"
export CFLAGS="-s -w"
export LDFLAGS=""

if [[ "$ENABLE_STATIC_BUILD" != "0" ]]; then
    CFLAGS+=" -static"
    LDFLAGS+=" -static"
fi

export CDIR=$PWD

# Rebuilt now that newlib's headers are installed, so that GCC's limits.h includes newlib's.
# No libstdc++: GCC 2.95's libstdc++ v2 needs a glibc-like libio; the C++ runtime is in libgcc.
$SRCDIR/gcc-${GCCVER}${GCCREV}/configure \
	--build=$BUILDMACH --target=$TARGETMACH --host=$HOSTMACH \
	--prefix=$INSTALLDIR --with-newlib \
	--enable-languages=c,c++ --disable-threads --disable-nls --disable-shared \
	--with-gnu-as --with-gnu-ld --program-prefix=${PROGRAM_PREFIX} ${GCC_FINAL_FLAGS}

make all-gcc CFLAGS="$CFLAGS" $MAKEFLAGS
make -C gcc install "program_transform_name=s,^,${PROGRAM_PREFIX}," "program_transform_cross_name=s,^,${PROGRAM_PREFIX}," $MAKEFLAGS
# g++ always links -lstdc++: give it an empty one, the C++ runtime is in libgcc
${PROGRAM_PREFIX}ar rc $INSTALLDIR/$TARGETMACH/lib/libstdc++.a

cd ${CDIR}
