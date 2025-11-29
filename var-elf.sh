
#!/bin/bash

# Directories
export INSTALLDIR=${INSTALLDIR:=$PWD/toolchain/toolchain}
export SYSROOTDIR=$INSTALLDIR/sysroot
export ROOTDIR=${ROOTDIR:=$PWD}
export DOWNLOADDIR=$PWD/toolchain/download
export RELSRCDIR=./toolchain/source
export SRCDIR=$PWD/toolchain/source
export BUILDDIR=$PWD/toolchain/build

# Detect host system and set build/host machine using uname
UNAME_S=$(uname -s)
UNAME_M=$(uname -m)

case "$UNAME_S" in
    Linux)
        case "$UNAME_M" in
            x86_64)
                export BUILDMACH=x86_64-pc-linux-gnu
                export HOSTMACH=x86_64-pc-linux-gnu
                ;;
            aarch64)
                export BUILDMACH=aarch64-pc-linux-gnu
                export HOSTMACH=aarch64-pc-linux-gnu
                ;;
            *)
                export BUILDMACH=${UNAME_M}-unknown-linux-gnu
                export HOSTMACH=${UNAME_M}-unknown-linux-gnu
                ;;
        esac
        ;;
    Darwin)
        case "$UNAME_M" in
            arm64)
                export BUILDMACH=aarch64-apple-darwin
                export HOSTMACH=aarch64-apple-darwin
                ;;
            x86_64)
                export BUILDMACH=x86_64-apple-darwin
                export HOSTMACH=x86_64-apple-darwin
                ;;
            *)
                export BUILDMACH=${UNAME_M}-apple-darwin
                export HOSTMACH=${UNAME_M}-apple-darwin
                ;;
        esac
        ;;
    CYGWIN*)
        export BUILDMACH=x86_64-pc-cygwin
        export HOSTMACH=x86_64-pc-cygwin
        ;;
    MINGW*)
        export BUILDMACH=x86_64-w64-mingw32
        export HOSTMACH=x86_64-w64-mingw32
        ;;
    MSYS*)
        export BUILDMACH=x86_64-pc-msys
        export HOSTMACH=x86_64-pc-msys
        ;;
    *)
        export BUILDMACH=${UNAME_M}-unknown-${UNAME_S,,}
        export HOSTMACH=${UNAME_M}-unknown-${UNAME_S,,}
        ;;
esac

# Bootstrap flags
if [[ "$ENABLE_BOOTSTRAP" == "1" ]]; then
    export GCC_BOOTSTRAP="--enable-bootstrap"
else
    export GCC_BOOTSTRAP="--disable-bootstrap"
fi

# Toolchain-specific settings
export PROGRAM_PREFIX=${PROGRAM_PREFIX:=sh2eb-elf-}
export TARGETMACH=${TARGETMACH:=sh-elf}
export OBJFORMAT=${OBJFORMAT:=ELF}

export BINUTILS_CFLAGS="-s"
export GCC_BOOTSTRAP_FLAGS="--with-cpu=m2"
export GCC_FINAL_FLAGS="--with-cpu=m2 --with-sysroot=$SYSROOTDIR"
export QTIFWDIR=./installer


# Source versions
source versions.sh
