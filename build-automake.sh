#!/bin/bash

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# Advisory automake minimum version (backward compatible with old variable name)
AUTOMAKE_MIN_VERSION="${AUTOMAKE_MIN_VERSION:-${REQUIRED_AUTOMAKE_VERSION:-}}"

trace_info "Automake build step uses local toolchain policy"

if ! command -v automake >/dev/null 2>&1; then
    trace_error "automake is not installed locally. Install automake and retry."
    exit 1
fi

LOCAL_AUTOMAKE_VERSION=$(automake --version | head -n1 | awk '{print $NF}')
trace_success "Using local automake version ${LOCAL_AUTOMAKE_VERSION}"

if [ -n "$AUTOMAKE_MIN_VERSION" ] && ! version_ge "$LOCAL_AUTOMAKE_VERSION" "$AUTOMAKE_MIN_VERSION"; then
    trace_warning "Local automake ${LOCAL_AUTOMAKE_VERSION} is lower than AUTOMAKE_MIN_VERSION=${AUTOMAKE_MIN_VERSION}. Continuing with local version."
fi

trace_success "No pinned automake installation performed"