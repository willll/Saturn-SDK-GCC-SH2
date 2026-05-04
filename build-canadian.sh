
#!/bin/bash

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

if [[ "$HOSTMACH" == "$BUILDMACH" ]]; then
    trace_info "Build and host are the same. Building a cross compiler for one host/build architecture"
    redirect_output ./build.sh
    exit $?
fi

if [ -z "$INSTALLDIR_BUILD_TARGET" ]; then
    INSTALLDIR_BUILD_TARGET=${INSTALLDIR}_build_target
fi

if [ -z "$NCPU" ]; then
    trace_info "Detecting number of CPU cores..."
    # Mac OS X
    if command -v sysctl >/dev/null 2>&1; then
        export NCPU=$(sysctl -n hw.ncpu)
    # coreutils
    elif command -v nproc >/dev/null 2>&1; then
        export NCPU=$(nproc)
    # fallback to non-parallel build
    else
        trace_warning "Could not detect CPU count, defaulting to single core build"
        export NCPU=1
    fi
    trace_info "Using $NCPU CPU cores for building"
fi

if [ -d "$INSTALLDIR" ]; then
    trace_info "Removing existing install directory..."
    redirect_output rm -rf "$INSTALLDIR"
fi
if [ -d "${INSTALLDIR_BUILD_TARGET}" ]; then
    trace_info "Removing existing build target directory..."
    redirect_output rm -rf "${INSTALLDIR_BUILD_TARGET}"
fi

HOSTORIG=$HOSTMACH
PREFIXORIG=$PROGRAM_PREFIX

if [[ "$ENABLE_DOWNLOAD_CACHE" != "1" ]]; then
    trace_info "Downloading required files..."
    redirect_output ./download.sh || {
        trace_error "Failed to retrieve the files necessary for building GCC"
        exit 1
    }
fi

trace_info "Extracting source files..."
redirect_output ./extract-source.sh || {
    trace_error "Failed to extract the source files"
    exit 1
}

trace_info "Applying patches..."
redirect_output ./patch.sh || {
    trace_error "Failed to patch packages"
    exit 1
}

# Build the cross compiler for the target
export HOSTMACH=$BUILDMACH
export PROGRAM_PREFIX=${TARGETMACH}-

# When building inside a cross-compilation environment (like dockcross), 
# variables like CC/CXX point to the target host (Windows). 
# Stage 1 MUST use the build machine's (Linux) native tools.
SAVE_CC="$CC"; SAVE_CXX="$CXX"; SAVE_AR="$AR"; SAVE_AS="$AS"; SAVE_RANLIB="$RANLIB"
SAVE_LD="$LD"; SAVE_NM="$NM"; SAVE_STRIP="$STRIP"; SAVE_OBJCOPY="$OBJCOPY"; SAVE_OBJDUMP="$OBJDUMP"
SAVE_CPP="$CPP"; SAVE_CROSS_COMPILE="$CROSS_COMPILE"
SAVE_CFLAGS="$CFLAGS"; SAVE_CXXFLAGS="$CXXFLAGS"; SAVE_LDFLAGS="$LDFLAGS"; SAVE_CPPFLAGS="$CPPFLAGS"
SAVE_CPATH="$CPATH"; SAVE_C_INCLUDE_PATH="$C_INCLUDE_PATH"; SAVE_CPLUS_INCLUDE_PATH="$CPLUS_INCLUDE_PATH"
SAVE_LIBRARY_PATH="$LIBRARY_PATH"; SAVE_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
SAVE_PKG_CONFIG_PATH="$PKG_CONFIG_PATH"; SAVE_PKG_CONFIG_LIBDIR="$PKG_CONFIG_LIBDIR"
SAVE_PATH="$PATH" # Save the original PATH from the dockcross environment
SAVE_STATIC_BUILD="$ENABLE_STATIC_BUILD"

export CC=gcc CXX=g++ AR=ar AS=as RANLIB=ranlib LD=ld NM=nm STRIP=strip
export OBJCOPY=objcopy OBJDUMP=objdump
export CFLAGS="" CXXFLAGS="" LDFLAGS="" CPPFLAGS=""
unset CPP CROSS_COMPILE
unset CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH OBJC_INCLUDE_PATH
unset LIBRARY_PATH LD_LIBRARY_PATH
# Temporarily set PATH to only include native system tools for Stage 1.
# This prevents the GCC build from finding cross-tools like windres prematurely.
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
unset PKG_CONFIG_PATH PKG_CONFIG_LIBDIR

export ENABLE_STATIC_BUILD=0 # Build-machine tools don't need to be static

CURRENT_COMPILER="${TARGETMACH} running on ${HOSTMACH}"

trace_info "Building toolchain for $CURRENT_COMPILER..."

trace_info "Building binutils..."
redirect_output ./build-binutils.sh || {
    trace_error "Failed to build binutils for ${CURRENT_COMPILER}"
    exit 1
}

trace_info "Building GCC bootstrap..."
redirect_output ./build-gcc-bootstrap.sh || {
    trace_error "Failed to build GCC bootstrap for ${CURRENT_COMPILER}"
    exit 1
}

trace_info "Building newlib..."
redirect_output ./build-newlib.sh || {
    trace_error "Failed to build newlib for ${CURRENT_COMPILER}"
    exit 1
}

trace_info "Building final GCC..."
redirect_output ./build-gcc-final.sh || {
    trace_error "Failed to build final GCC for ${CURRENT_COMPILER}"
    exit 1
}
export PROGRAM_PREFIX=$PREFIXORIG

trace_info "Moving installation directory..."
redirect_output mv "${INSTALLDIR}" "${INSTALLDIR_BUILD_TARGET}"

export PATH=${INSTALLDIR_BUILD_TARGET}/bin:$PATH

# Restore environment for the actual host build (e.g. MinGW)
export CC="$SAVE_CC" CXX="$SAVE_CXX" AR="$SAVE_AR" AS="$SAVE_AS" RANLIB="$SAVE_RANLIB"
export LD="$SAVE_LD" NM="$SAVE_NM" STRIP="$SAVE_STRIP" OBJCOPY="$SAVE_OBJCOPY" OBJDUMP="$SAVE_OBJDUMP"
export CPP="$SAVE_CPP" CROSS_COMPILE="$SAVE_CROSS_COMPILE"
export CFLAGS="$SAVE_CFLAGS" CXXFLAGS="$SAVE_CXXFLAGS" LDFLAGS="$SAVE_LDFLAGS" CPPFLAGS="$SAVE_CPPFLAGS"
export CPATH="$SAVE_CPATH" C_INCLUDE_PATH="$SAVE_C_INCLUDE_PATH" CPLUS_INCLUDE_PATH="$SAVE_CPLUS_INCLUDE_PATH"
export LIBRARY_PATH="$SAVE_LIBRARY_PATH" LD_LIBRARY_PATH="$SAVE_LD_LIBRARY_PATH"
export PKG_CONFIG_PATH="$SAVE_PKG_CONFIG_PATH" PKG_CONFIG_LIBDIR="$SAVE_PKG_CONFIG_LIBDIR"
export PATH="$SAVE_PATH" # Restore the original PATH from the dockcross environment
# Re-add stage-1 Linux tools so sh-elf-gcc is visible during stage-2 builds.
export PATH="${INSTALLDIR_BUILD_TARGET}/bin:$PATH"
export ENABLE_STATIC_BUILD="$SAVE_STATIC_BUILD"

unset SAVE_CC SAVE_CXX SAVE_AR SAVE_AS SAVE_RANLIB SAVE_LD SAVE_NM SAVE_STRIP SAVE_OBJCOPY SAVE_OBJDUMP
unset SAVE_CPP SAVE_CROSS_COMPILE SAVE_CFLAGS SAVE_CXXFLAGS SAVE_LDFLAGS SAVE_CPPFLAGS
unset SAVE_CPATH SAVE_C_INCLUDE_PATH SAVE_CPLUS_INCLUDE_PATH SAVE_LIBRARY_PATH SAVE_LD_LIBRARY_PATH
unset SAVE_PKG_CONFIG_PATH SAVE_PKG_CONFIG_LIBDIR SAVE_STATIC_BUILD
unset SAVE_PATH

# Build the cross compiler for the target using the host to build
export HOSTMACH=$HOSTORIG
CURRENT_COMPILER="${TARGETMACH} running on ${HOSTMACH}"

trace_info "Building toolchain for $CURRENT_COMPILER..."

trace_info "Building binutils..."
redirect_output ./build-binutils.sh || {
    trace_error "Failed to build binutils for ${CURRENT_COMPILER}"
    exit 1
}

trace_info "Building GCC bootstrap..."
redirect_output ./build-gcc-bootstrap.sh || {
    trace_error "Failed to build GCC bootstrap for ${CURRENT_COMPILER}"
    exit 1
}

export PROGRAM_PREFIX=${TARGETMACH}-
trace_info "Building newlib..."
redirect_output ./build-newlib.sh || {
    trace_error "Failed to build newlib for ${CURRENT_COMPILER}"
    exit 1
}
export PROGRAM_PREFIX=$PREFIXORIG

trace_info "Building final GCC..."
redirect_output ./build-gcc-final.sh || {
    trace_error "Failed to build final GCC for ${CURRENT_COMPILER}"
    exit 1
}

trace_success "Successfully built GCC for ${CURRENT_COMPILER}"
