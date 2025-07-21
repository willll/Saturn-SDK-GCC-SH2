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
