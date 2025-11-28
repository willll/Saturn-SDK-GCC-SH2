#!/bin/bash

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

trace_info "Building COFF toolchain..."
redirect_output ./build.sh || {
    trace_error "Failed to build the COFF toolchain"
    exit 1
}
trace_success "COFF toolchain built successfully"

if [[ "${CREATEINSTALLER}" == "YES" ]]; then
    trace_info "Creating installer..."
    redirect_output ./createinstaller.sh || {
        trace_error "Failed to create installer"
        exit 1
    }
    trace_success "Installer created successfully"
fi

trace_success "COFF build process completed"