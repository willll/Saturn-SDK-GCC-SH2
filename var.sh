#!/bin/bash
export RELSRCDIR=./toolchain/source
export SRCDIR=$PWD/toolchain/source
export BUILDDIR=$PWD/toolchain/build
export TARGETMACH=sh-elf
export BUILDMACH=mingw32
#i686-pc-msys
export HOSTMACH=mingw32
#i686-pc-msys
export INSTALLDIR=$PWD/toolchain/toolchain
export SYSROOTDIR=$INSTALLDIR/sysroot
export ROOTDIR=$PWD/toolchain
export DOWNLOADDIR=$PWD/toolchain/download
export PROGRAM_PREFIX=sh-

export BINUTILSVER=2.32
export BINUTILSREV=
export GCCVER=9.2.0
export GCCREV=
export NEWLIBVER=3.2.0
export NEWLIBREV=
export MPCVER=1.1.0
export MPCREV=
export MPFRVER=4.0.2
export MPFRREV=
export GMPVER=6.1.2
export GMPREV=

export OBJFORMAT=ELF

#export TARGETMACH=sh-elf

export BINUTILS_CFLAGS="-s"
export GCC_BOOTSTRAP_FLAGS="--with-cpu=m2"
export GCC_FINAL_FLAGS="--with-cpu=m2 --with-sysroot=$SYSROOTDIR"
export NCPU=1
export QTIFWDIR=./installer