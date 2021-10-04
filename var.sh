#!/bin/bash

export RELSRCDIR=./toolchain/source
export SRCDIR=$PWD/toolchain/source
export BUILDDIR=$PWD/toolchain/build
export TARGETMACH=sh-elf

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    export BUILDMACH=i686-pc-linux-gnu
    export HOSTMACH=i686-pc-linux-gnu
elif [[ "$OSTYPE" == "darwin"* ]]; then
    export BUILDMACH=i686-pc-linux-gnu
    export HOSTMACH=i686-pc-linux-gnu
elif [[ "$OSTYPE" == "cygwin" ]]; then
    export BUILDMACH=i686-pc-linux-gnu
    export HOSTMACH=i686-pc-linux-gnu
elif [[ "$OSTYPE" == "msys" ]]; then
    export BUILDMACH=mingw32
    export HOSTMACH=mingw32
else
    export BUILDMACH=i686-pc-linux-gnu
    export HOSTMACH=i686-pc-linux-gnu
fi

export INSTALLDIR=$PWD/toolchain/toolchain
export SYSROOTDIR=$INSTALLDIR/sysroot
export ROOTDIR=$PWD/toolchain
export DOWNLOADDIR=$PWD/toolchain/download
export PROGRAM_PREFIX=sh-

export BINUTILSVER=2.34
export BINUTILSREV=
export GCCVER=8.4.0
export GCCREV=
export NEWLIBVER=3.3.0
export NEWLIBREV=
export MPCVER=1.1.0
export MPCREV=
export MPFRVER=4.0.2
export MPFRREV=
export GMPVER=6.2.0
export GMPREV=

export OBJFORMAT=ELF

export BINUTILS_CFLAGS="-s"
export GCC_BOOTSTRAP_FLAGS="--with-cpu=m2"
export GCC_FINAL_FLAGS="--with-cpu=m2 --with-sysroot=$SYSROOTDIR"
export NCPU=1
export QTIFWDIR=./installer

exec "$@"
