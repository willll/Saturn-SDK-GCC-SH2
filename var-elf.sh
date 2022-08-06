#!/bin/bash

#export SKIP_DOWNLOAD

export INSTALLDIR=$PWD/toolchains/m68k
export SYSROOTDIR=$INSTALLDIR/sysroot
export ROOTDIR=$PWD/toolchains
export DOWNLOADDIR=$PWD/download
export RELSRCDIR=./toolchains/m68k/sources
export SRCDIR=$PWD/toolchains/m68k/sources
export BUILDDIR=$PWD/toolchains/m68k/build

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

export PROGRAM_PREFIX=m68k-elf
export TARGETMACH=m68k-elf
export OBJFORMAT=ELF

export NCPU=1

#export BINUTILS_CFLAGS="-s"
#export GCC_BOOTSTRAP_FLAGS="--with-cpu=m2"
#export GCC_FINAL_FLAGS="--with-cpu=m2 --with-sysroot=$SYSROOTDIR"
#export QTIFWDIR=./installer

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source $SCRIPT_DIR/versions.sh
