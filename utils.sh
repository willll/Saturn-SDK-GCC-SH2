#!/bin/bash

# Constants
: "${ENABLE_VERBOSE_BUILD:=1}"

# Redirect function for command output
redirect_output() {
    if [ "${ENABLE_VERBOSE_BUILD}" = "1" ]; then
        "$@"
    else
        "$@" >/dev/null 2>&1
    fi
    return $?
}

# Ensure directory permissions
ensure_dir_permissions() {
    local dir="$1"
    if [ ! -w "$dir" ]; then
        trace_info "Fixing permissions for directory: $dir"
        redirect_output chmod u+w "$dir" || {
            trace_error "Failed to set write permissions on $dir"
            return 1
        }
    fi
    return 0
}

# Trace functions
trace_info() {
    echo -e "\e[1;34m[ INFO ]\e[0m $1"
}

trace_success() {
    echo -e "\e[1;32m[  OK  ]\e[0m $1"
}

trace_warning() {
    echo -e "\e[1;33m[ WARN ]\e[0m $1"
}

trace_error() {
    echo -e "\e[1;31m[ ERROR ]\e[0m $1"
}

# Function to compare versions using sort -V
version_ge() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

# Provide versioned automake/aclocal names expected by older generated scripts.
setup_versioned_automake_shims() {
    local base_dir="${ROOTDIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
    local host_tools_dir="${base_dir}/.host-tools"

    mkdir -p "$host_tools_dir" || return 1

    if command -v aclocal >/dev/null 2>&1 && ! command -v aclocal-1.17 >/dev/null 2>&1; then
        ln -sf "$(command -v aclocal)" "$host_tools_dir/aclocal-1.17" || return 1
    fi

    if command -v automake >/dev/null 2>&1 && ! command -v automake-1.17 >/dev/null 2>&1; then
        ln -sf "$(command -v automake)" "$host_tools_dir/automake-1.17" || return 1
    fi

    export PATH="$host_tools_dir:$PATH"
}

# Set tar verbosity based on ENABLE_VERBOSE_BUILD
VERBOSE_EXTRACT=$([ "${ENABLE_VERBOSE_BUILD}" = "1" ] && echo "-v" || echo "")
