
#!/bin/bash

# Constants
: "${GNU_BASE_URL:="https://ftpmirror.gnu.org"}"
: "${SOURCEWARE_BASE_URL:="https://sourceware.org/pub"}"
: "${GNU_SOURCES_DIR:="gnu"}"

# Set default verbosity if not defined
: "${ENABLE_VERBOSE_BUILD:=1}"

# Source common utilities if the file exists
if [ -f "$(dirname "${BASH_SOURCE[0]}")/utils.sh" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"
else
    echo -e "\e[1;31m[ ERROR ]\e[0m utils.sh not found. This script cannot continue without it."
    exit 1
fi

# Determine download tool
if command -v curl >/dev/null; then
    FETCH="curl -fL --connect-timeout ${DOWNLOAD_CONNECT_TIMEOUT}"
elif command -v wget >/dev/null; then
    FETCH="wget -q --connect-timeout=${DOWNLOAD_CONNECT_TIMEOUT}"
fi

redirect_output() {
    if [ "${ENABLE_VERBOSE_BUILD}" = "1" ]; then
        "$@"
    else
        "$@" >/dev/null 2>&1
    fi
    return $?
}

# Function to compare versions using sort -V
version_ge() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

download_with_retry() {
    local URL="$1"
    local DEST_DIR="$2"
    local FILENAME=$(basename "$URL")
    local DEST_FILE="${DEST_DIR}/${FILENAME}"

    if [ -z "$FETCH" ]; then
        trace_error "Could not find either curl or wget, please install one to continue."
        return 1
    fi

    for ((i=0; i<=${DOWNLOAD_RETRIES}; i++)); do
        trace_info "Attempting to download ${FILENAME} from ${URL} (try $((i+1)))..."
        if [[ "$FETCH" == "curl"* ]]; then
            if redirect_output $FETCH -o "${DEST_FILE}" "${URL}"; then
                trace_success "Successfully downloaded ${FILENAME}"
                return 0
            fi
        else # wget
            if redirect_output $FETCH -O "${DEST_FILE}" "${URL}"; then
                trace_success "Successfully downloaded ${FILENAME}"
                return 0
            fi
        fi

        if [ $i -lt "$DOWNLOAD_RETRIES" ]; then
            local WAIT_TIME=$(( (i + 1) * DOWNLOAD_RETRY_DELAY ))
            trace_warning "Failed to download ${FILENAME}. Retrying in ${WAIT_TIME} seconds..."
            sleep $WAIT_TIME
        fi
    done

    trace_error "Failed to download ${FILENAME} after ${DOWNLOAD_RETRIES} retries."
    return 1
}


# Common functions
verify_gpg_signature() {
    local SIGFILE="$1"
    local TARFILE="$2"
    local COMPONENT="$3"

    trace_info "Verifying GPG signature for ${COMPONENT}..."

    if ! redirect_output gpg --verify --keyring "${DOWNLOADDIR}/gnu-keyring.gpg" "${SIGFILE}" "${TARFILE}"; then
        trace_error "GPG verification failed. Signature is invalid for ${COMPONENT}."
        return 1
    fi

    trace_success "GPG verification successful for ${COMPONENT}"
    return 0
}

# New function to check if file exists and is valid
validate_existing_file() {
    local COMPONENT="$1"
    local TARFILE="$2"
    local SIGFILE="$3"
    local URL_BASE="$4"

    # Check if component directory exists in gnu folder
    local COMPONENT_DIR="${GNU_SOURCES_DIR}/${COMPONENT}"
    if [ ! -d "${COMPONENT_DIR}" ]; then
        return 1
    fi

    # Check if tarfile exists
    if [ ! -f "${COMPONENT_DIR}/${TARFILE}" ]; then
        return 1
    fi

    # Download signature if it doesn't exist
    if [ ! -f "${COMPONENT_DIR}/${SIGFILE}" ]; then
        trace_info "Downloading signature for existing ${TARFILE}..."
        download_with_retry "${URL_BASE}/${SIGFILE}" "${COMPONENT_DIR}" || {
            trace_error "Failed to download ${SIGFILE}"
            return 1
        }
    fi

    # Verify signature
    if verify_gpg_signature "${COMPONENT_DIR}/${SIGFILE}" "${COMPONENT_DIR}/${TARFILE}" "${COMPONENT}"; then
        trace_success "Using existing verified ${TARFILE}"
        return 0
    fi

    trace_warning "Existing ${TARFILE} failed verification, will download fresh copy"
    return 1
}

# Clean symbolic links
clean_symbolic_links() {
    trace_info "Cleaning up symbolic links..."
    # Find all symbolic links in the directory and unlink them
    find "${DOWNLOADDIR}" -type l -exec unlink {} \;
}

download_gnu_component() {
    local COMPONENT="$1"
    local VERSION="$2"
    local REV="${3:-}"
    local FORMAT="$4"
    local SUBPATH="${5:-}"

    local BASE="${COMPONENT}-${VERSION}${REV}"
    local TARFILE="${BASE}.${FORMAT}"
    local SIGFILE="${TARFILE}.sig"
    local URL_BASE="${GNU_BASE_URL}/${COMPONENT}${SUBPATH:+/$SUBPATH}"
    local COMPONENT_DIR="${GNU_SOURCES_DIR}/${COMPONENT}"

    # Create component directory if it doesn't exist
    redirect_output mkdir -p "${COMPONENT_DIR}"

    # Check if we already have a valid file
    if [ "${ENABLE_DOWNLOAD_CACHE}" != "0" ]; then
        if validate_existing_file "${COMPONENT}" "${TARFILE}" "${SIGFILE}" "${URL_BASE}"; then
            # If file is valid, create symlink or copy to download directory if needed
            if [ "${COMPONENT_DIR}" != "${DOWNLOADDIR}" ]; then
                redirect_output ln -sf "$PWD/${COMPONENT_DIR}/${TARFILE}" "${DOWNLOADDIR}/${TARFILE}" || \
                redirect_output cp "${COMPONENT_DIR}/${TARFILE}" "${DOWNLOADDIR}/${TARFILE}"
            fi
            return 0
        fi
    fi

    trace_info "Downloading ${URL_BASE}/${TARFILE} and signature..."

    # Download to component directory
    if ! download_with_retry "${URL_BASE}/${TARFILE}" "${COMPONENT_DIR}"; then
        trace_error "Failed to download ${TARFILE}"
        return 1
    fi
    if ! download_with_retry "${URL_BASE}/${SIGFILE}" "${COMPONENT_DIR}"; then
        trace_error "Failed to download ${URL_BASE}/${SIGFILE}"
        return 1
    fi

    # Verify signature
    verify_gpg_signature "${COMPONENT_DIR}/${SIGFILE}" "${COMPONENT_DIR}/${TARFILE}" "${COMPONENT}" || return 1

    # Create symlink or copy to download directory if needed
    if [ "${COMPONENT_DIR}" != "${DOWNLOADDIR}" ]; then
        redirect_output ln -sf "$PWD/${COMPONENT_DIR}/${TARFILE}" "${DOWNLOADDIR}/${TARFILE}" || \
        redirect_output cp "${COMPONENT_DIR}/${TARFILE}" "${DOWNLOADDIR}/${TARFILE}"
    fi
}

# Component-specific download functions
function download_automake() {
    [ $# -eq 0 ] && { trace_error "Usage: download_automake <version>"; return 1; }
    download_gnu_component "automake" "$1" "" "tar.gz"
}

function download_binutils() {
    [ $# -eq 0 ] && { trace_error "Usage: download_binutils <version> [revision]"; return 1; }
    download_gnu_component "binutils" "$1" "$2" "tar.xz"
}

function download_gcc() {
    [ $# -eq 0 ] && { trace_error "Usage: download_gcc <version> [revision]"; return 1; }
    download_gnu_component "gcc" "$1" "$2" "tar.xz" "gcc-$1$2"
}

function download_gdb() {
    [ $# -eq 0 ] && { trace_error "Usage: download_gdb <version> [revision]"; return 1; }
    download_gnu_component "gdb" "$1" "$2" "tar.gz"
}

function download_mpc() {
    [ $# -eq 0 ] && { trace_error "Usage: download_mpc <version> [revision]"; return 1; }
    download_gnu_component "mpc" "$1" "$2" "tar.gz"
}

function download_mpfr() {
    [ $# -eq 0 ] && { trace_error "Usage: download_mpfr <version> [revision]"; return 1; }
    download_gnu_component "mpfr" "$1" "$2" "tar.xz"
}

function download_gmp() {
    [ $# -eq 0 ] && { trace_error "Usage: download_gmp <version> [revision]"; return 1; }
    download_gnu_component "gmp" "$1" "$2" "tar.xz"
}

function download_newlib() {
    [ $# -eq 0 ] && { trace_error "Usage: download_newlib <version> [revision]"; return 1; }

    local VERSION="$1"
    local REV="${2:-}"
    local BASE="newlib-${VERSION}${REV}"
    local TARFILE="${BASE}.tar.gz"
    local COMPONENT_DIR="${GNU_SOURCES_DIR}/newlib"
    local URL_BASE="${SOURCEWARE_BASE_URL}/newlib"

    # Create component directory if it doesn't exist
    redirect_output mkdir -p "${COMPONENT_DIR}"

    # Check if file already exists
    if [ "${ENABLE_DOWNLOAD_CACHE}" != "0" ]; then
        if [ -f "${COMPONENT_DIR}/${TARFILE}" ]; then
            trace_success "Using existing ${TARFILE}"
            if [ "${COMPONENT_DIR}" != "${DOWNLOADDIR}" ]; then
                redirect_output ln -sf "$PWD/${COMPONENT_DIR}/${TARFILE}" "${DOWNLOADDIR}/${TARFILE}" || \
                redirect_output cp "${COMPONENT_DIR}/${TARFILE}" "${DOWNLOADDIR}/${TARFILE}"
            fi
            return 0
        fi
    fi

    trace_info "Downloading ${TARFILE}..."
    if ! download_with_retry "${URL_BASE}/${TARFILE}" "${COMPONENT_DIR}"; then
        trace_error "Failed to download ${TARFILE}"
        return 1
    fi
    trace_success "Successfully downloaded ${TARFILE}"

    # Create symlink or copy to download directory if needed
    if [ "${COMPONENT_DIR}" != "${DOWNLOADDIR}" ]; then
        redirect_output ln -sf "$PWD/${COMPONENT_DIR}/${TARFILE}" "${TARFILE}" || \
        redirect_output cp "${COMPONENT_DIR}/${TARFILE}" "${TARFILE}"
    fi
}

# Setup download directory and fetch tool
if [ ! -d "${DOWNLOADDIR}" ]; then
    redirect_output mkdir -p "${DOWNLOADDIR}"
else
    # Clean symbolic links if directory already exists
    clean_symbolic_links
fi

cd "${DOWNLOADDIR}" || { trace_error "Failed to change to download directory"; exit 1; }

# Download GNU keyring first
if [ ! -f "${DOWNLOADDIR}/gnu-keyring.gpg" ]; then
    download_with_retry "${GNU_BASE_URL}/gnu-keyring.gpg" "${DOWNLOADDIR}" || {
        trace_error "gnu-keyring.gpg not downloaded."
        exit 1
    }
fi

trace_success "gnu-keyring.gpg is available."

# Download core components
download_gmp "${GMPVER}" "${GMPREV}" || exit 1
download_mpfr "${MPFRVER}" "${MPFRREV}" || exit 1
download_mpc "${MPCVER}" "${MPCREV}" || exit 1
download_binutils "${BINUTILSVER}" "${BINUTILSREV}" || exit 1
download_gcc "${GCCVER}" "${GCCREV}" || exit 1
download_newlib "${NEWLIBVER}" "${NEWLIBREV}" || exit 1

# Check automake installation and version
INSTALLED_AUTOMAKE_VERSION=""
if command -v automake &>/dev/null; then
    INSTALLED_AUTOMAKE_VERSION=$(automake --version | head -n1 | awk '{print $NF}')
    trace_success "Automake is installed: version ${INSTALLED_AUTOMAKE_VERSION}"
else
    trace_warning "Automake is not installed"
fi

# Handle automake version requirements
if [ -n "$REQUIRED_AUTOMAKE_VERSION" ]; then
    if [ -n "$INSTALLED_AUTOMAKE_VERSION" ] && version_ge "$INSTALLED_AUTOMAKE_VERSION" "$REQUIRED_AUTOMAKE_VERSION"; then
        trace_success "Version ${INSTALLED_AUTOMAKE_VERSION} meets the requirement (>= ${REQUIRED_AUTOMAKE_VERSION})"
    else
        if [ -n "$INSTALLED_AUTOMAKE_VERSION" ]; then
            trace_warning "Version ${INSTALLED_AUTOMAKE_VERSION} is lower than required (${REQUIRED_AUTOMAKE_VERSION})"
        fi
        trace_info "Downloading automake version ${REQUIRED_AUTOMAKE_VERSION}..."
        download_automake "$REQUIRED_AUTOMAKE_VERSION" || {
            trace_error "Failed to download or verify Automake version ${REQUIRED_AUTOMAKE_VERSION}"
            exit 1
        }
        trace_success "Successfully downloaded and verified Automake version ${REQUIRED_AUTOMAKE_VERSION}"
    fi
else
    trace_info "No specific Automake version required, skipping download"
fi

# Download optional components
if [ -n "${GDBVER}" ]; then
    trace_info "GDB version ${GDBVER}${GDBREV} requested"
    download_gdb "${GDBVER}" "${GDBREV}" || exit 1
else
    trace_info "No GDB version specified, skipping GDB download"
fi

trace_success "All required components downloaded successfully."
