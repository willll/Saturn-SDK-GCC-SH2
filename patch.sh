#!/bin/bash

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# Function to apply patches in a directory
apply_patches() {
    local component="$1"
    local version="$2"
    local revision="$3"
    local patch_dir="$ROOTDIR/patches/$component/$version$revision"

    if [ ! -d "$patch_dir" ]; then
        trace_info "No patches found for $component $version$revision"
        return 0
    fi

    trace_info "Applying patches for $component $version$revision..."
    cd "$SRCDIR" || {
        trace_error "Failed to change to source directory"
        exit 1
    }

    for file in "$patch_dir"/*.patch; do
        trace_info "Applying patch: $(basename "$file")"
        redirect_output patch -Np1 -i "$file"
        local status=$?
        
        if [ $status -eq 0 ]; then
            trace_success "Successfully applied patch: $(basename "$file")"
        elif [ $status -eq 1 ]; then
            trace_warning "Patch already applied: $(basename "$file")"
        else
            trace_error "Failed to apply patch: $(basename "$file")"
            exit 1
        fi
    done
}

trace_info "Starting patch application process..."

# Apply binutils patches
apply_patches "binutils" "${BINUTILSVER}" "${BINUTILSREV}"

# Apply GCC patches
apply_patches "gcc" "${GCCVER}" "${GCCREV}"

trace_success "Patch application process completed successfully"
exit 0