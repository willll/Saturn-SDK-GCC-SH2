#!/bin/bash

# Constants
GNU_BASE_URL="https://ftp.gnu.org/gnu"
SOURCEWARE_BASE_URL="https://sourceware.org/pub"
GNU_SOURCES_DIR="gnu"

# Function to compare versions using sort -V
version_ge() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

# Common functions
verify_gpg_signature() {
    local SIGFILE="$1"
    local TARFILE="$2"
    local COMPONENT="$3"

    echo -e "\e[1;34m[ INFO ]\e[0m Verifying GPG signature for ${COMPONENT}..."

    if ! gpg --verify --keyring ./gnu-keyring.gpg "${SIGFILE}" "${TARFILE}" &>/dev/null; then
        echo -e "\e[1;31m[ ERROR ]\e[0m GPG verification failed. Signature is invalid for ${COMPONENT}."
        return 1
    fi

    echo -e "\e[1;32m[  OK  ]\e[0m GPG verification successful for ${COMPONENT}"
    return 0
}

# New function to check if file exists and is valid
validate_existing_file() {
    local COMPONENT="$1"
    local TARFILE="$2"
    local SIGFILE="$3"

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
        echo -e "\e[1;34m[ INFO ]\e[0m Downloading signature for existing ${TARFILE}..."
        wget -q -P "${COMPONENT_DIR}" "${URL_BASE}/${SIGFILE}" || {
            echo -e "\e[1;31m[ ERROR ]\e[0m Failed to download ${SIGFILE}"
            return 1
        }
    fi

    # Verify signature
    if verify_gpg_signature "${COMPONENT_DIR}/${SIGFILE}" "${COMPONENT_DIR}/${TARFILE}" "${COMPONENT}"; then
        echo -e "\e[1;32m[  OK  ]\e[0m Using existing verified ${TARFILE}"
        return 0
    fi

    echo -e "\e[1;33m[ WARN ]\e[0m Existing ${TARFILE} failed verification, will download fresh copy"
    return 1
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
    mkdir -p "${COMPONENT_DIR}"

    # Check if we already have a valid file
    if validate_existing_file "${COMPONENT}" "${TARFILE}" "${SIGFILE}"; then
        # If file is valid, create symlink or copy to download directory if needed
        if [ "${COMPONENT_DIR}" != "${DOWNLOADDIR}" ]; then
            ln -sf "../${COMPONENT_DIR}/${TARFILE}" "${TARFILE}" || \
            cp "${COMPONENT_DIR}/${TARFILE}" "${TARFILE}"
        fi
        return 0
    fi

    echo -e "\e[1;34m[ INFO ]\e[0m Downloading ${TARFILE} and signature..."

    # Download to component directory
    wget -q -P "${COMPONENT_DIR}" "${URL_BASE}/${TARFILE}" || { 
        echo -e "\e[1;31m[ ERROR ]\e[0m Failed to download ${TARFILE}"
        return 1
    }
    wget -q -P "${COMPONENT_DIR}" "${URL_BASE}/${SIGFILE}" || {
        echo -e "\e[1;31m[ ERROR ]\e[0m Failed to download ${SIGFILE}"
        return 1
    }

    # Verify signature
    verify_gpg_signature "${COMPONENT_DIR}/${SIGFILE}" "${COMPONENT_DIR}/${TARFILE}" "${COMPONENT}" || return 1

    # Create symlink or copy to download directory if needed
    if [ "${COMPONENT_DIR}" != "${DOWNLOADDIR}" ]; then
        ln -sf "../${COMPONENT_DIR}/${TARFILE}" "${TARFILE}" || \
        cp "${COMPONENT_DIR}/${TARFILE}" "${TARFILE}"
    fi
}

# Component-specific download functions
function download_automake() {
    [ $# -eq 0 ] && { echo -e "\e[1;31mUsage: download_automake <version>\e[0m"; return 1; }
    download_gnu_component "automake" "$1" "" "tar.gz"
}

function download_binutils() {
    [ $# -eq 0 ] && { echo -e "\e[1;31mUsage: download_binutils <version> [revision]\e[0m"; return 1; }
    download_gnu_component "binutils" "$1" "$2" "tar.xz"
}

function download_gcc() {
    [ $# -eq 0 ] && { echo -e "\e[1;31mUsage: download_gcc <version> [revision]\e[0m"; return 1; }
    download_gnu_component "gcc" "$1" "$2" "tar.xz" "gcc-$1$2"
}

function download_gdb() {
    [ $# -eq 0 ] && { echo -e "\e[1;31mUsage: download_gdb <version> [revision]\e[0m"; return 1; }
    download_gnu_component "gdb" "$1" "$2" "tar.gz"
}

function download_mpc() {
    [ $# -eq 0 ] && { echo -e "\e[1;31mUsage: download_mpc <version> [revision]\e[0m"; return 1; }
    download_gnu_component "mpc" "$1" "$2" "tar.gz"
}

function download_mpfr() {
    [ $# -eq 0 ] && { echo -e "\e[1;31mUsage: download_mpfr <version> [revision]\e[0m"; return 1; }
    download_gnu_component "mpfr" "$1" "$2" "tar.xz"
}

function download_gmp() {
    [ $# -eq 0 ] && { echo -e "\e[1;31mUsage: download_gmp <version> [revision]\e[0m"; return 1; }
    download_gnu_component "gmp" "$1" "$2" "tar.xz"
}

function download_newlib() {
    [ $# -eq 0 ] && { echo -e "\e[1;31mUsage: download_newlib <version> [revision]\e[0m"; return 1; }

    local VERSION="$1"
    local REV="${2:-}"
    local BASE="newlib-${VERSION}${REV}"
    local TARFILE="${BASE}.tar.gz"
    local COMPONENT_DIR="${GNU_SOURCES_DIR}/newlib"
    local URL_BASE="${SOURCEWARE_BASE_URL}/newlib"

    # Create component directory if it doesn't exist
    mkdir -p "${COMPONENT_DIR}"

    # Check if file already exists
    if [ -f "${COMPONENT_DIR}/${TARFILE}" ]; then
        echo -e "\e[1;32m[  OK  ]\e[0m Using existing ${TARFILE}"
        if [ "${COMPONENT_DIR}" != "${DOWNLOADDIR}" ]; then
            ln -sf "../${COMPONENT_DIR}/${TARFILE}" "${TARFILE}" || \
            cp "${COMPONENT_DIR}/${TARFILE}" "${TARFILE}"
        fi
        return 0
    fi

    echo -e "\e[1;34m[ INFO ]\e[0m Downloading ${TARFILE}..."
    wget -q -P "${COMPONENT_DIR}" "${URL_BASE}/${TARFILE}" || {
        echo -e "\e[1;31m[ ERROR ]\e[0m Failed to download ${TARFILE}"
        return 1
    }
    echo -e "\e[1;32m[  OK  ]\e[0m Successfully downloaded ${TARFILE}"

    # Create symlink or copy to download directory if needed
    if [ "${COMPONENT_DIR}" != "${DOWNLOADDIR}" ]; then
        ln -sf "../${COMPONENT_DIR}/${TARFILE}" "${TARFILE}" || \
        cp "${COMPONENT_DIR}/${TARFILE}" "${TARFILE}"
    fi
}

# Setup download directory and fetch tool
if [ ! -d "${DOWNLOADDIR}" ]; then
    mkdir -p "${DOWNLOADDIR}"
fi

cd "${DOWNLOADDIR}" || { echo -e "\e[1;31m[ ERROR ]\e[0m Failed to change to download directory"; exit 1; }

# Determine download tool
if command -v curl >/dev/null; then
    FETCH="curl --retry 5 --retry-delay 5 --connect-timeout 30 -k -f -L -O -J"
elif command -v wget >/dev/null; then
    FETCH="wget -tries=5 -c"
else
    echo -e "\e[1;31m[ ERROR ]\e[0m Could not find either curl or wget, please install either one to continue"
    exit 1
fi

# Download GNU keyring first
$FETCH "${GNU_BASE_URL}/gnu-keyring.gpg"
if [ ! -f "gnu-keyring.gpg" ]; then
    echo -e "\e[1;31m[ ERROR ]\e[0m gnu-keyring.gpg not downloaded."
    exit 1
fi

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
    echo -e "\e[1;32m[  OK  ]\e[0m Automake is installed: version ${INSTALLED_AUTOMAKE_VERSION}"
else
    echo -e "\e[1;33m[ WARN ]\e[0m Automake is not installed"
fi

# Handle automake version requirements
if [ -n "$REQUIRED_AUTOMAKE_VERSION" ]; then
    if [ -n "$INSTALLED_AUTOMAKE_VERSION" ] && version_ge "$INSTALLED_AUTOMAKE_VERSION" "$REQUIRED_AUTOMAKE_VERSION"; then
        echo -e "\e[1;32m[  OK  ]\e[0m Version ${INSTALLED_AUTOMAKE_VERSION} meets the requirement (>= ${REQUIRED_AUTOMAKE_VERSION})"
    else
        if [ -n "$INSTALLED_AUTOMAKE_VERSION" ]; then
            echo -e "\e[1;33m[ WARN ]\e[0m Version ${INSTALLED_AUTOMAKE_VERSION} is lower than required (${REQUIRED_AUTOMAKE_VERSION})"
        fi
        echo -e "\e[1;34m[ INFO ]\e[0m Downloading automake version ${REQUIRED_AUTOMAKE_VERSION}..."
        download_automake "$REQUIRED_AUTOMAKE_VERSION" || {
            echo -e "\e[1;31m[ ERROR ]\e[0m Failed to download or verify Automake version ${REQUIRED_AUTOMAKE_VERSION}"
            exit 1
        }
        echo -e "\e[1;32m[  OK  ]\e[0m Successfully downloaded and verified Automake version ${REQUIRED_AUTOMAKE_VERSION}"
    fi
fi

# Download optional components
if [ -n "${GDBVER}" ]; then
    echo -e "\e[1;34m[ INFO ]\e[0m GDB version ${GDBVER}${GDBREV} requested"
    download_gdb "${GDBVER}" "${GDBREV}" || exit 1
else
    echo -e "\e[1;33m[ INFO ]\e[0m No GDB version specified, skipping GDB download"
fi

echo -e "\e[1;32m[  OK  ]\e[0m All required components downloaded successfully."
