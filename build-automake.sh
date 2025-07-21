#!/bin/bash

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

trace_info "Building automake..."

if [ ! -d "$BUILDDIR/automake" ]; then
    trace_info "Creating build directory..."
    redirect_output mkdir -p "$BUILDDIR/automake"
fi

cd "$BUILDDIR/automake" || {
    trace_error "Failed to change to build directory"
    exit 1
}

# Configure automake
if [ ! -f Makefile ]; then
    trace_info "Configuring automake..."
    
    CONF_FLAGS="--prefix=$INSTALLDIR"
    
    if [ "$ENABLE_STATIC_BUILD" = "1" ]; then
        CONF_FLAGS="$CONF_FLAGS --enable-static --disable-shared"
    fi
    
    redirect_output "$SRCDIR/automake-${REQUIRED_VERSION}/configure" $CONF_FLAGS || {
        trace_error "Configuration failed"
        exit 1
    }
    trace_success "Configuration completed"
fi

# Build and install
trace_info "Building automake..."
redirect_output make -j"$NCPU" || {
    trace_error "Build failed"
    exit 1
}
trace_success "Build completed"

trace_info "Installing automake..."
redirect_output make install || {
    trace_error "Installation failed"
    exit 1
}
trace_success "Installation completed"

trace_success "Done building automake"