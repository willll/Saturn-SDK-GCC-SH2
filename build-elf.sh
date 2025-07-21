#!/bin/bash

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

trace_info "Loading ELF configuration..."
if source ./var-elf.sh 2>/dev/null || source ./var-elf.sh; then
    trace_success "ELF configuration loaded successfully"
else
    trace_error "Failed to load ELF configuration"
    exit 1
fi

trace_info "Building ELF toolchain..."
redirect_output ./build.sh || {
    trace_error "Failed to build the ELF toolchain"
    exit 1
}
trace_success "ELF toolchain built successfully"

if [[ "${CREATEINSTALLER}" == "YES" ]]; then
    trace_info "Creating installer..."
    redirect_output ./createinstaller.sh || {
        trace_error "Failed to create installer"
        exit 1
    }
    trace_success "Installer created successfully"
fi

trace_success "ELF build process completed"
