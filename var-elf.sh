#!/bin/bash

# Directories
export INSTALLDIR=$PWD/toolchain/toolchain
export SYSROOTDIR=$INSTALLDIR/sysroot
export ROOTDIR=$PWD/toolchain
export DOWNLOADDIR=$PWD/toolchain/download
export RELSRCDIR=./toolchain/source
export SRCDIR=$PWD/toolchain/source
export BUILDDIR=$PWD/toolchain/build

# Detect host system and set build/host machine
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    export BUILDMACH=x86_64-pc-linux-gnu
    export HOSTMACH=x86_64-pc-linux-gnu
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # Adjust for M4 Mac (ARM64 architecture)
    if [[ "$(uname -m)" == "arm64" ]]; then
        export BUILDMACH=aarch64-apple-darwin
        export HOSTMACH=aarch64-apple-darwin
    else
        export BUILDMACH=x86_64-apple-darwin
        export HOSTMACH=x86_64-apple-darwin
    fi
elif [[ "$OSTYPE" == "cygwin" ]]; then
    export BUILDMACH=i686-pc-linux-gnu
    export HOSTMACH=i686-pc-linux-gnu
elif [[ "$OSTYPE" == "msys" ]]; then
    export BUILDMACH=mingw32
    export HOSTMACH=mingw32
else
    export BUILDMACH=x86_64-pc-linux-gnu
    export HOSTMACH=x86_64-pc-linux-gnu
fi

# Bootstrap flags
if [[ "$ENABLE_BOOTSTRAP" == "1" ]]; then
    export GCC_BOOTSTRAP="--enable-bootstrap"
else
    export GCC_BOOTSTRAP="--disable-bootstrap"
fi

# Toolchain-specific settings
export PROGRAM_PREFIX=sh2eb-elf-
export TARGETMACH=sh-elf
export OBJFORMAT=ELF

export BINUTILS_CFLAGS="-s"
export GCC_BOOTSTRAP_FLAGS="--with-cpu=m2"
export GCC_FINAL_FLAGS="--with-cpu=m2 --with-sysroot=$SYSROOTDIR"
export QTIFWDIR=./installer

# Source versions
source versions.sh
