#!/bin/bash
set -e

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

if [ -d "$BUILDDIR/newlib" ]; then
    trace_info "Removing existing newlib build directory..."
    redirect_output rm -rf "$BUILDDIR/newlib"
fi

trace_info "Creating newlib build directory..."
redirect_output mkdir -p "$BUILDDIR/newlib"
cd "$BUILDDIR/newlib" || {
    trace_error "Failed to change to newlib build directory"
    exit 1
}

trace_info "Setting up build environment..."
export PATH=$INSTALLDIR/bin:$PATH
export CROSS=${PROGRAM_PREFIX}
export CC_FOR_TARGET=${CROSS}gcc
export LD_FOR_TARGET=${CROSS}ld
export AS_FOR_TARGET=${CROSS}as
export AR_FOR_TARGET=${CROSS}ar
export RANLIB_FOR_TARGET=${CROSS}ranlib

export newlib_cflags="${newlib_cflags} -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__"

trace_info "Configuring newlib..."
redirect_output "$SRCDIR/newlib-${NEWLIBVER}${NEWLIBREV}/configure" \
    --prefix="$INSTALLDIR" \
    --target="$TARGETMACH" \
    --build="$BUILDMACH" \
    --host="$HOSTMACH" \
    --enable-newlib-nano-malloc \
    --enable-target-optspace \
    --enable-lite-exit \
    --disable-newlib-fvwrite-in-streamio \
    --disable-newlib-fseek-optimization \
    --disable-newlib-unbuf-stream-opt \
    --disable-newlib-multithread \
    --enable-newlib-nano-formatted-io \
    --disable-newlib-io-float \
    --disable-newlib-supplied-syscalls || {
        trace_error "Configuration failed"
        exit 1
    }
trace_success "Configuration completed"

trace_info "Building newlib..."
redirect_output make all $MAKEFLAGS MAKEINFO=true || {
    trace_error "Build failed"
    exit 1
}

trace_info "Installing newlib..."
redirect_output make install $MAKEFLAGS MAKEINFO=true || {
    trace_error "Installation failed"
    exit 1
}

trace_success "Newlib build completed successfully"
