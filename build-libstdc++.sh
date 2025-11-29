#!/bin/bash
set -e

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

if [ -d "$BUILDDIR/gcc-bootstrap" ]; then
    trace_error "Build bootstrap first !..."
    exit 1
fi

trace_info "Changing to bootstrap build directory..."
cd "$BUILDDIR/gcc-bootstrap" || {
    trace_error "Failed to change to bootstrap build directory"
    exit 1
}

export PATH=$INSTALLDIR/bin:$PATH

trace_info "Setting up build flags..."
export CFLAGS="-s -DCOMMON_LVB_REVERSE_VIDEO=0x4000 -DCOMMON_LVB_UNDERSCORE=0x8000"
export CXXFLAGS="-s -DCOMMON_LVB_REVERSE_VIDEO=0x4000 -DCOMMON_LVB_UNDERSCORE=0x8000"
export LDFLAGS=""

if [[ "$ENABLE_STATIC_BUILD" != "0" ]]; then
    trace_info "Enabling static build..."
    CFLAGS+=" -static"
    CXXFLAGS+=" -static"
    LDFLAGS+=" -static"
fi

export CDIR=$PWD

trace_info "Building target libstdc++-v3..."
redirect_output make all-target-libstdc++-v3 $MAKEFLAGS MAKEINFO=true || {
    trace_error "Target libstdc++-v3 build failed"
    exit 1
}

trace_info "Installing target libstdc++-v3..."
redirect_output make install-target-libstdc++-v3 $MAKEFLAGS MAKEINFO=true || {
    trace_error "Target libstdc++-v3 installation failed"
    exit 1
}

cd "${CDIR}" || {
    trace_error "Failed to return to original directory"
    exit 1
}

trace_success "libstdc++ build completed successfully"