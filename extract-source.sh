#!/bin/bash

# Constants
VERBOSE_EXTRACT="-v"

# Common functions
extract_archive() {
    local ARCHIVE="$1"
    local FORMAT="$2"
    local EXTRA_FLAGS="${3:-}"

    case "$FORMAT" in
        "xz")  tar ${VERBOSE_EXTRACT}Jpf ${EXTRA_FLAGS} "$ARCHIVE" ;;
        "gz")  tar ${VERBOSE_EXTRACT}zpf ${EXTRA_FLAGS} "$ARCHIVE" ;;
        *)     echo -e "\e[1;31m[ ERROR ]\e[0m Unknown archive format: $FORMAT"; return 1 ;;
    esac
    return $?
}

get_archive_path() {
    local COMPONENT="$1"
    local VERSION="$2"
    local REV="${3:-}"
    local FORMAT="$4"

    if [[ "$ENABLE_DOWNLOAD_CACHE" == "1" ]]; then
        echo "$ROOTDIR/gnu/$COMPONENT/$COMPONENT-$VERSION$REV.tar.$FORMAT"
    else
        echo "$DOWNLOADDIR/$COMPONENT-$VERSION$REV.tar.$FORMAT"
    fi
}

extract_binutils() {
    local DIR="binutils-${BINUTILSVER}${BINUTILSREV}"
    if [ ! -d "$DIR" ]; then
        echo -e "\e[1;34m[ INFO ]\e[0m Extracting binutils..."
        local ARCHIVE=$(get_archive_path "binutils" "${BINUTILSVER}" "${BINUTILSREV}" "xz")
        extract_archive "$ARCHIVE" "xz" || {
            rm -rf "$DIR"
            return 1
        }
    fi
}

extract_gcc() {
    local DIR="gcc-${GCCVER}${GCCREV}"
    if [ ! -d "$DIR" ]; then
        echo -e "\e[1;34m[ INFO ]\e[0m Extracting gcc..."
        local ARCHIVE=$(get_archive_path "gcc" "${GCCVER}" "${GCCREV}" "xz")
        extract_archive "$ARCHIVE" "xz" || {
            rm -rf "$DIR"
            return 1
        }
    fi
}

extract_newlib() {
    local DIR="newlib-${NEWLIBVER}${NEWLIBREV}"
    if [ ! -d "$DIR" ]; then
        echo -e "\e[1;34m[ INFO ]\e[0m Extracting newlib..."
        local ARCHIVE=$(get_archive_path "newlib" "${NEWLIBVER}" "${NEWLIBREV}" "gz")
        extract_archive "$ARCHIVE" "gz" || {
            rm -rf "$DIR"
            return 1
        }
    fi
}

extract_mpc() {
    local DIR="mpc-${MPCVER}${MPCREV}"
    if [ ! -d "$DIR" ]; then
        echo -e "\e[1;34m[ INFO ]\e[0m Extracting mpc..."
        local ARCHIVE=$(get_archive_path "mpc" "${MPCVER}" "${MPCREV}" "gz")
        extract_archive "$ARCHIVE" "gz" || {
            rm -rf "$DIR"
            return 1
        }
    fi
    echo -e "\e[1;34m[ INFO ]\e[0m Copying mpc to gcc directory..."
    cp -rv "$DIR" "gcc-${GCCVER}${GCCREV}/mpc"
}

extract_mpfr() {
    local DIR="mpfr-${MPFRVER}${MPFRREV}"
    if [ ! -d "$DIR" ]; then
        echo -e "\e[1;34m[ INFO ]\e[0m Extracting mpfr..."
        local ARCHIVE=$(get_archive_path "mpfr" "${MPFRVER}" "${MPFRREV}" "xz")
        extract_archive "$ARCHIVE" "xz" || {
            rm -rf "$DIR"
            return 1
        }
    fi
    echo -e "\e[1;34m[ INFO ]\e[0m Copying mpfr to gcc directory..."
    cp -rv "$DIR" "gcc-${GCCVER}${GCCREV}/mpfr"
}

extract_gmp() {
    local DIR="gmp-${GMPVER}${GMPREV}"
    if [ ! -d "$DIR" ]; then
        echo -e "\e[1;34m[ INFO ]\e[0m Extracting gmp..."
        local ARCHIVE=$(get_archive_path "gmp" "${GMPVER}" "${GMPREV}" "xz")
        extract_archive "$ARCHIVE" "xz" || {
            rm -rf "$DIR"
            return 1
        }
    fi
    echo -e "\e[1;34m[ INFO ]\e[0m Copying gmp to gcc directory..."
    cp -rv "$DIR" "gcc-${GCCVER}${GCCREV}/gmp"
}

extract_gdb() {
    if [ -z "${GDBVER}${GDBREV}" ]; then
        return 0
    fi

    local DIR="gdb-${GDBVER}${GDBREV}"
    if [ ! -d "$DIR" ]; then
        echo -e "\e[1;34m[ INFO ]\e[0m Extracting gdb..."
        local ARCHIVE=$(get_archive_path "gdb" "${GDBVER}" "${GDBREV}" "gz")
        extract_archive "$ARCHIVE" "gz" || {
            rm -rf "$DIR"
            return 1
        }
    fi
}

extract_automake() {
    if [ -z "${REQUIRED_VERSION}" ]; then
        return 0
    fi

    # Check if we need to extract automake
    if command -v automake >/dev/null; then
        local INSTALLED_VERSION=$(automake --version | head -n1 | awk '{print $NF}')
        if [ "$(printf '%s\n' "$INSTALLED_VERSION" "$REQUIRED_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
            echo -e "\e[1;32m[  OK  ]\e[0m Using system automake version ${INSTALLED_VERSION}"
            return 0
        fi
    fi

    local DIR="automake-${REQUIRED_VERSION}"
    if [ ! -d "$DIR" ]; then
        echo -e "\e[1;34m[ INFO ]\e[0m Extracting automake..."
        local ARCHIVE=$(get_archive_path "automake" "${REQUIRED_VERSION}" "" "gz")
        extract_archive "$ARCHIVE" "gz" || {
            rm -rf "$DIR"
            return 1
        }
    fi

    # Configure and install automake if needed
    if [ ! -f "$DIR/Makefile" ]; then
        echo -e "\e[1;34m[ INFO ]\e[0m Configuring automake..."
        (cd "$DIR" && ./configure --prefix="$PREFIX") || return 1
    fi
    
    echo -e "\e[1;34m[ INFO ]\e[0m Installing automake..."
    (cd "$DIR" && make install) || return 1
}

# Main execution
echo "Extracting source files..."

if [ ! -d "$SRCDIR" ]; then
    mkdir -p "$SRCDIR"
fi

cd "$SRCDIR" || exit 1

# Extract core components
extract_binutils || exit 1
extract_gmp || exit 1
extract_mpfr || exit 1
extract_mpc || exit 1
extract_gcc || exit 1
extract_newlib || exit 1

# Extract optional components
extract_gdb || exit 1
extract_automake || exit 1

echo -e "\e[1;32m[  OK  ]\e[0m Done"
