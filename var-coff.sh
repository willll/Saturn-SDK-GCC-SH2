#!/bin/bash

export INSTALLDIR=$PWD/toolchain/toolchain
export SYSROOTDIR=$INSTALLDIR/sysroot
export ROOTDIR=$PWD
export DOWNLOADDIR=$PWD/toolchain/download
export RELSRCDIR=./toolchain/source
export SRCDIR=$PWD/toolchain/source
export BUILDDIR=$PWD/toolchain/build

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

export PROGRAM_PREFIX=saturn-sh2-coff-
export TARGETMACH=sh-coff
export OBJFORMAT=COFF

export BINUTILS_CFLAGS="-s"
export GCC_BOOTSTRAP_FLAGS="--with-cpu=m2"
export GCC_FINAL_FLAGS="--with-cpu=m2 --with-sysroot=$SYSROOTDIR"
export QTIFWDIR=./installer

source versions.sh
