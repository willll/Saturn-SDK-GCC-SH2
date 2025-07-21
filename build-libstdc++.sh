#!/bin/bash
set -e

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

if [ -d "$BUILDDIR/libstdc++" ]; then
    trace_info "Removing existing libstdc++ build directory..."
    redirect_output rm -rf "$BUILDDIR/libstdc++"
fi

trace_info "Creating libstdc++ build directory..."
redirect_output mkdir -p "$BUILDDIR/libstdc++"
cd "$BUILDDIR/libstdc++" || {
    trace_error "Failed to change to libstdc++ build directory"
    exit 1
}

trace_info "Setting up build environment..."
export PATH=$INSTALLDIR/bin:$PATH
export CROSS=${PROGRAM_PREFIX}
export CC=${CROSS}gcc
export CXX=${CROSS}g++
export CPP=${CROSS}cpp

export CFLAGS="-I$SRCDIR/newlib-$NEWLIBVER/newlib/libc/include"
export CXXFLAGS="-I$SRCDIR/newlib-$NEWLIBVER/newlib/libc/include"

trace_info "Configuring libstdc++..."
redirect_output "$SRCDIR/gcc-${GCCVER}${GCCREV}/libstdc++-v3/configure" \
    --host="${TARGETMACH}" \
    --build="${BUILDMACH}" \
    --target="${TARGETMACH}" \
    --with-cross-host="${HOSTMACH}" \
    --prefix="${INSTALLDIR}" \
    --disable-nls \
    --disable-multilib \
    --disable-libstdcxx-threads \
    --with-newlib \
    --disable-libstdcxx-pch || {
        trace_error "Configuration failed"
        exit 1
    }
trace_success "Configuration completed"

trace_info "Building libstdc++..."
redirect_output make $MAKEFLAGS || {
    trace_error "Build failed"
    exit 1
}

trace_info "Installing libstdc++..."
redirect_output make install $MAKEFLAGS || {
    trace_error "Installation failed"
    exit 1
}

trace_success "libstdc++ build completed successfully"
