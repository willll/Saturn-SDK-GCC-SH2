#!/bin/bash
set -e

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

if [ -d "$BUILDDIR/binutils" ]; then
    trace_info "Removing existing binutils build directory..."
    redirect_output rm -rf "$BUILDDIR/binutils"
fi

trace_info "Creating build directory..."
redirect_output mkdir -p "$BUILDDIR/binutils"
cd "$BUILDDIR/binutils" || {
    trace_error "Failed to change to build directory"
    exit 1
}

export CFLAGS=${BINUTILS_CFLAGS}
export CXXFLAGS="-s"

trace_info "Configuring binutils..."
redirect_output "$SRCDIR/binutils-${BINUTILSVER}${BINUTILSREV}/configure" \
    --disable-werror \
    --host="$HOSTMACH" \
    --build="$BUILDMACH" \
    --target="$TARGETMACH" \
    --prefix="$INSTALLDIR" \
    --with-sysroot="$SYSROOTDIR" \
    --program-prefix="${PROGRAM_PREFIX}" \
    --disable-multilib \
    --disable-nls \
    --enable-languages=c \
    --disable-newlib-atexit-dynamic-alloc \
    --enable-libssp || {
        trace_error "Configuration failed"
        exit 1
    }
trace_success "Configuration completed"

trace_info "Building binutils..."
if [[ "$ENABLE_STATIC_BUILD" != "0" ]]; then
    trace_info "Building with static linking..."
    redirect_output make configure-host $MAKEFLAGS || {
        trace_error "Host configuration failed"
        exit 1
    }
    redirect_output make $MAKEFLAGS LDFLAGS="-all-static" || {
        trace_error "Build failed"
        exit 1
    }
else
    redirect_output make $MAKEFLAGS || {
        trace_error "Build failed"
        exit 1
    }
fi
trace_success "Build completed"

trace_info "Installing binutils..."
redirect_output make install $MAKEFLAGS || {
    trace_error "Installation failed"
    exit 1
}
trace_success "Installation completed"

trace_success "Done building binutils"