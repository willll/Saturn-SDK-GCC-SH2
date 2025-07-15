#!/bin/bash

function print_environment_variable_usage {
    local PRINT_USAGE="ALL"
    if [ -n "$1" ]; then
        PRINT_USAGE="$1"
    fi

    printf "\nEnvironment variable usage\n"
    printf "%s\n\n" "--------------------------"

    if [ "$PRINT_USAGE" = "ALL" ] || [ "$PRINT_USAGE" = "ROOTDIR" ]; then
        printf "ROOTDIR        - Root directory for the entire build process\n"
    fi

    if [ "$PRINT_USAGE" = "ALL" ] || [ "$PRINT_USAGE" = "DOWNLOADDIR" ]; then
        printf "DOWNLOADDIR    - Directory where required archive packages are stored\n"
    fi

    if [ "$PRINT_USAGE" = "ALL" ] || [ "$PRINT_USAGE" = "SRCDIR" ]; then
        printf "SRCDIR         - Directory containing extracted source files\n"
    fi

    if [ "$PRINT_USAGE" = "ALL" ] || [ "$PRINT_USAGE" = "BUILDDIR" ]; then
        printf "BUILDDIR       - Directory where source packages are built\n"
    fi

    if [ "$PRINT_USAGE" = "ALL" ] || [ "$PRINT_USAGE" = "INSTALLDIR" ]; then
        printf "INSTALLDIR     - Directory containing the final installed binaries\n"
    fi

    if [ "$PRINT_USAGE" = "ALL" ] || [ "$PRINT_USAGE" = "SYSROOTDIR" ]; then
        printf "SYSROOTDIR     - Location of the target sysroot (usually \$INSTALLDIR/sysroot)\n"
    fi

    if [ "$PRINT_USAGE" = "ALL" ] || [ "$PRINT_USAGE" = "TARGETMACH" ]; then
        printf "TARGETMACH     - Target architecture for the compiler (e.g., sh-elf)\n"
    fi

    if [ "$PRINT_USAGE" = "ALL" ] || [ "$PRINT_USAGE" = "BUILDMACH" ]; then
        printf "BUILDMACH      - Architecture of the build machine\n"
    fi

    if [ "$PRINT_USAGE" = "ALL" ] || [ "$PRINT_USAGE" = "HOSTMACH" ]; then
        printf "HOSTMACH       - Architecture the built tools will run on\n"
    fi

    if [ "$PRINT_USAGE" = "ALL" ] || [ "$PRINT_USAGE" = "PROGRAM_PREFIX" ]; then
        printf "PROGRAM_PREFIX - Prefix for tool names (e.g., saturn-sh2- for saturn-sh2-gcc)\n"
    fi
}

# Required environment checks
for VAR in ROOTDIR DOWNLOADDIR SRCDIR BUILDDIR INSTALLDIR SYSROOTDIR TARGETMACH BUILDMACH HOSTMACH PROGRAM_PREFIX; do
    if [ -z "${!VAR}" ]; then
        echo "Error: The environment variable \${$VAR} is not set."
        print_environment_variable_usage "$VAR"
        exit 1
    fi
done

# Canadian cross-detection
if [ "$HOSTMACH" != "$BUILDMACH" ]; then
    echo "Build and host differ. Starting Canadian cross build..."
    ./build-canadian.sh
    exit $?
fi

# Determine NCPU
if [ -z "$NCPU" ]; then
    if command -v nproc >/dev/null 2>&1; then
        export NCPU=$(nproc)
    elif command -v sysctl >/dev/null 2>&1; then
        export NCPU=$(sysctl -n hw.ncpu)
    else
        export NCPU=1
        echo "Warning: Could not detect CPU count. Defaulting to NCPU=1"
    fi
fi

# Print version and environment summaries
echo ""
echo "===== Version & Build Flags Summary ====="
[ -n "$BINUTILSVER" ]           && echo "BINUTILSVER           = $BINUTILSVER"
[ -n "$BINUTILSREV" ]           && echo "BINUTILSREV           = $BINUTILSREV"
[ -n "$GCCVER" ]                && echo "GCCVER                = $GCCVER"
[ -n "$GCCREV" ]                && echo "GCCREV                = $GCCREV"
[ -n "$NEWLIBVER" ]             && echo "NEWLIBVER             = $NEWLIBVER"
[ -n "$NEWLIBREV" ]             && echo "NEWLIBREV             = $NEWLIBREV"
[ -n "$MPCVER" ]                && echo "MPCVER                = $MPCVER"
[ -n "$MPCREV" ]                && echo "MPCREV                = $MPCREV"
[ -n "$MPFRVER" ]               && echo "MPFRVER               = $MPFRVER"
[ -n "$MPFRREV" ]               && echo "MPFRREV               = $MPFRREV"
[ -n "$GMPVER" ]                && echo "GMPVER                = $GMPVER"
[ -n "$GMPREV" ]                && echo "GMPREV                = $GMPREV"
[ -n "$GDBVER" ]                && echo "GDBVER                = $GDBVER"
[ -n "$GDBREV" ]                && echo "GDBREV                = $GDBREV"
[ -n "$ENABLE_BOOTSTRAP" ]      && echo "ENABLE_BOOTSTRAP      = $ENABLE_BOOTSTRAP"
[ -n "$ENABLE_DOWNLOAD_CACHE" ] && echo "ENABLE_DOWNLOAD_CACHE = $ENABLE_DOWNLOAD_CACHE"
[ -n "$ENABLE_STATIC_BUILD" ]   && echo "ENABLE_STATIC_BUILD   = $ENABLE_STATIC_BUILD"

echo ""
echo "===== Environment Summary ====="
for VAR in INSTALLDIR SYSROOTDIR ROOTDIR DOWNLOADDIR RELSRCDIR SRCDIR BUILDDIR \
           BUILDMACH HOSTMACH GCC_BOOTSTRAP PROGRAM_PREFIX TARGETMACH OBJFORMAT \
           BINUTILS_CFLAGS GCC_BOOTSTRAP_FLAGS GCC_FINAL_FLAGS QTIFWDIR; do
    [ -n "${!VAR}" ] && printf "%-20s = %s\n" "$VAR" "${!VAR}"
done

echo ""
read -n 1 -s -r -p "Press any key to begin the build process..."
echo ""

# Clean install dir
[ -d "$INSTALLDIR" ] && rm -rf "$INSTALLDIR"

# Download phase (only if caching is disabled)
if [ "$ENABLE_DOWNLOAD_CACHE" != "1" ]; then
    ./download.sh || { echo "Failed to retrieve necessary files"; exit 1; }
fi

# Build steps
./extract-source.sh         || { echo "Failed to extract sources"; exit 1; }
./patch.sh                  || { echo "Failed to patch sources"; exit 1; }
./build-binutils.sh         || { echo "Failed to build binutils"; exit 1; }
./build-gcc-bootstrap.sh    || { echo "Failed to build GCC bootstrap"; exit 1; }
./build-newlib.sh           || { echo "Failed to build newlib"; exit 1; }
./build-libstdc++.sh        || { echo "Failed to build libstdc++"; exit 1; }
./build-gcc-final.sh        || { echo "Failed to build final GCC"; exit 1; }

if [ -n "${GDBVER}${GDBREV}" ]; then
    ./build-gdb.sh || { echo "Failed to build GDB"; exit 1; }
fi
