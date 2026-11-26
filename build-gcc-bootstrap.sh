#!/bin/bash
set -e

[ -d $BUILDDIR/gcc-bootstrap ] && rm -rf $BUILDDIR/gcc-bootstrap

mkdir -p $BUILDDIR/gcc-bootstrap
cd $BUILDDIR/gcc-bootstrap

export PATH=$INSTALLDIR/bin:$PATH

# GCC 2.95 is K&R-era C: compile it as C89 with common tentative definitions.
# In CC, not CFLAGS: 2.95 also passes CFLAGS to its own compiler for libgcc.
export CC="${CC:-gcc} -std=gnu89 -fcommon"
# No -O, as on the other branches: GCC 15 at -O2 miscompiles 2.95 (cc1plus rejects every
# class declaration after PRE/DSE in cp/decl.c grokdeclarator). -w: thousands of K&R warnings.
export CFLAGS="-s -w"
export LDFLAGS=""

if [[ "$ENABLE_STATIC_BUILD" != "0" ]]; then
    CFLAGS+=" -static"
    LDFLAGS+=" -static"
fi

export CDIR=$PWD

$SRCDIR/gcc-${GCCVER}${GCCREV}/configure \
	--build=$BUILDMACH --host=$HOSTMACH --target=$TARGETMACH \
	--prefix=$INSTALLDIR --without-headers --with-newlib \
	--enable-languages=c,c++ --disable-threads --disable-nls --disable-shared \
	--with-gnu-ld --with-gnu-as --program-prefix=${PROGRAM_PREFIX} ${GCC_BOOTSTRAP_FLAGS}

# all-gcc also builds libgcc (libgcc1-asm, libgcc2 and the C++ runtime: new, delete, RTTI, exceptions)
make all-gcc CFLAGS="$CFLAGS" $MAKEFLAGS
# --program-prefix above names the target ar/ranlib; the gcc directory ignores it and would install a plain "cpp"
make -C gcc install "program_transform_name=s,^,${PROGRAM_PREFIX}," "program_transform_cross_name=s,^,${PROGRAM_PREFIX}," $MAKEFLAGS

cd ${CDIR}
