#!/bin/bash
# Run by build.sh once the sources are downloaded, extracted and patched

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

if [ -d "${INSTALLDIR_BUILD_TARGET}" ]; then
    trace_info "Removing existing build target directory..."
    redirect_output rm -rf "${INSTALLDIR_BUILD_TARGET}"
fi

HOSTORIG=$HOSTMACH
PREFIXORIG=$PROGRAM_PREFIX

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
