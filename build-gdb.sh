#!/bin/bash
set -e

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

if [ -d "$BUILDDIR/gdb" ]; then
    trace_info "Removing existing GDB build directory..."
    redirect_output rm -rf "$BUILDDIR/gdb"
fi

trace_info "Creating GDB build directory..."
redirect_output mkdir -p "$BUILDDIR/gdb"
cd "$BUILDDIR/gdb" || {
    trace_error "Failed to change to GDB build directory"
    exit 1
}

trace_info "Configuring GDB..."
redirect_output "$SRCDIR/gdb-${GDBVER}${GDBREV}/configure" \
    --host="${HOSTMACH}" \
    --build="${BUILDMACH}" \
    --target="${TARGETMACH}" \
    --prefix="${INSTALLDIR}" \
    --program-prefix="${PROGRAM_PREFIX}" || {
        trace_error "Configuration failed"
        exit 1
    }
trace_success "Configuration completed"

trace_info "Building GDB..."
redirect_output make all-gdb $MAKEFLAGS || {
    trace_error "Build failed"
    exit 1
}

trace_info "Installing GDB..."
redirect_output make install-gdb $MAKEFLAGS || {
    trace_error "Installation failed"
    exit 1
}

trace_success "GDB build completed successfully"
