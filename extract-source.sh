#!/bin/bash

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# Common functions
extract_archive() {
    local ARCHIVE="$1"
    local FORMAT="$2"
    local EXTRA_FLAGS="${3:-}"

    case "$FORMAT" in
        "xz")  redirect_output tar ${VERBOSE_EXTRACT}xJf ${EXTRA_FLAGS} "$ARCHIVE" ;;
        "gz")  redirect_output tar ${VERBOSE_EXTRACT}xzf ${EXTRA_FLAGS} "$ARCHIVE" ;;
        *)     trace_error "Unknown archive format: $FORMAT"; return 1 ;;
    esac
    
    if [ $? -eq 0 ]; then
        trace_success "Archive extracted successfully"
        return 0
    else
        trace_error "Failed to extract archive"
        return 1
    fi
}

get_archive_path() {
    local COMPONENT="$1"
    local VERSION="$2"
    local REV="${3:-}"
    local FORMAT="$4"

    if [[ "$ENABLE_DOWNLOAD_CACHE" == "1" ]]; then
        trace_info "$ROOTDIR/gnu/$COMPONENT/$COMPONENT-$VERSION$REV.tar.$FORMAT"
    else
        trace_info "$DOWNLOADDIR/$COMPONENT-$VERSION$REV.tar.$FORMAT"
    fi
}

extract_component() {
    local COMPONENT="$1"
    local VERSION="$2"
    local REV="$3"
    local FORMAT="$4"
    local COPY_TO_GCC="${5:-}"

    local DIR="${COMPONENT}-${VERSION}${REV}"
    local GCC_DIR="gcc-${GCCVER}${GCCREV}"
    
    if [ ! -d "$DIR" ]; then
        trace_info "Extracting ${COMPONENT}..."
        local ARCHIVE=$(get_archive_path "${COMPONENT}" "${VERSION}" "${REV}" "${FORMAT}")
        extract_archive "$ARCHIVE" "${FORMAT}" || {
            trace_error "Failed to extract ${COMPONENT}"
            redirect_output rm -rf "$DIR"
            return 1
        }
        # Ensure the extracted directory is writable
        ensure_dir_permissions "$DIR" || return 1
    else
        trace_info "Using existing ${COMPONENT} directory"
        ensure_dir_permissions "$DIR" || return 1
    fi

    if [ "$COPY_TO_GCC" = "true" ]; then
        trace_info "Copying ${COMPONENT} to gcc directory..."
        # First ensure GCC directory exists
        if [ ! -d "$GCC_DIR" ]; then
            trace_error "GCC directory $GCC_DIR does not exist. Extract GCC first."
            return 1
        fi
        
        # Ensure GCC directory is writable
        ensure_dir_permissions "$GCC_DIR" || return 1
        
        # Create and ensure component directory inside GCC directory
        if [ ! -d "$GCC_DIR/$COMPONENT" ]; then
            redirect_output mkdir -p "$GCC_DIR/$COMPONENT" || {
                trace_error "Failed to create $COMPONENT directory in GCC"
                return 1
            }
        fi
        ensure_dir_permissions "$GCC_DIR/$COMPONENT" || return 1
        
        # Copy files with proper permissions
        redirect_output cp -rf --preserve=mode "$DIR"/* "$GCC_DIR/$COMPONENT/" || {
            trace_error "Failed to copy ${COMPONENT} to gcc directory"
            return 1
        }
        trace_success "${COMPONENT} copied to gcc directory"
    fi

    return 0
}

# Component extraction functions
extract_binutils() {
    extract_component "binutils" "${BINUTILSVER}" "${BINUTILSREV}" "xz"
}

extract_gcc() {
    extract_component "gcc" "${GCCVER}" "${GCCREV}" "xz"
}

extract_newlib() {
    extract_component "newlib" "${NEWLIBVER}" "${NEWLIBREV}" "gz"
}

extract_mpc() {
    extract_component "mpc" "${MPCVER}" "${MPCREV}" "gz" "true"
}

extract_mpfr() {
    extract_component "mpfr" "${MPFRVER}" "${MPFRREV}" "xz" "true"
}

extract_gmp() {
    extract_component "gmp" "${GMPVER}" "${GMPREV}" "xz" "true"
}

extract_gdb() {
    if [ -z "${GDBVER}${GDBREV}" ]; then
        trace_info "GDB version not specified, skipping"
        return 0
    fi
    extract_component "gdb" "${GDBVER}" "${GDBREV}" "gz"
}

extract_automake() {
    if [ -z "${REQUIRED_AUTOMAKE_VERSION}" ]; then
        trace_info "Automake version not specified, skipping"
        return 0
    fi

    # Check if we need to extract automake
    if command -v automake >/dev/null; then
        local INSTALLED_AUTOMAKE_VERSION=$(automake --version | head -n1 | awk '{print $NF}')
        if [ "$(printf '%s\n' "$INSTALLED_AUTOMAKE_VERSION" "$REQUIRED_AUTOMAKE_VERSION" | sort -V | head -n1)" = "$REQUIRED_AUTOMAKE_VERSION" ]; then
            trace_success "Using system automake version ${INSTALLED_AUTOMAKE_VERSION}"
            return 0
        fi
    fi

    extract_component "automake" "${REQUIRED_AUTOMAKE_VERSION}" "" "gz"
}

# Main execution
trace_info "Extracting source files..."

if [ ! -d "$SRCDIR" ]; then
    trace_info "Creating source directory..."
    redirect_output mkdir -p "$SRCDIR"
fi

if ! cd "$SRCDIR"; then
    trace_error "Failed to change to source directory"
    exit 1
fi

# Extract core components
trace_info "Extracting core components..."
extract_binutils || { trace_error "Failed to extract binutils"; exit 1; }
extract_gcc || { trace_error "Failed to extract gcc"; exit 1; }
extract_gmp || { trace_error "Failed to extract gmp"; exit 1; }
extract_mpfr || { trace_error "Failed to extract mpfr"; exit 1; }
extract_mpc || { trace_error "Failed to extract mpc"; exit 1; }
extract_newlib || { trace_error "Failed to extract newlib"; exit 1; }

# Extract optional components
trace_info "Extracting optional components..."
extract_gdb || { trace_error "Failed to extract gdb"; exit 1; }
extract_automake || { trace_error "Failed to extract automake"; exit 1; }

trace_success "All components extracted successfully"