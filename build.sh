#!/bin/bash

# Constants and settings
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

# Environment variables description
declare -A ENV_VARS=(
    ["ROOTDIR"]="Root directory for the entire build process"
    ["DOWNLOADDIR"]="Directory where required archive packages are stored"
    ["SRCDIR"]="Directory containing extracted source files"
    ["BUILDDIR"]="Directory where source packages are built"
    ["INSTALLDIR"]="Directory containing the final installed binaries"
    ["SYSROOTDIR"]="Location of the target sysroot (usually \$INSTALLDIR/sysroot)"
    ["TARGETMACH"]="Target architecture for the compiler (e.g., sh-elf)"
    ["BUILDMACH"]="Architecture of the build machine"
    ["HOSTMACH"]="Architecture the built tools will run on"
    ["PROGRAM_PREFIX"]="Prefix for tool names (e.g., saturn-sh2- for saturn-sh2-gcc)"
)

function print_environment_variable_usage {
    local PRINT_USAGE="ALL"
    if [ -n "$1" ]; then
        PRINT_USAGE="$1"
    fi

    trace_info "Environment variable usage"
    echo "--------------------------"
    echo

    for var in "${!ENV_VARS[@]}"; do
        if [ "$PRINT_USAGE" = "ALL" ] || [ "$PRINT_USAGE" = "$var" ]; then
            printf "%-14s - %s\n" "$var" "${ENV_VARS[$var]}"
        fi
    done
}

# Required environment checks
for VAR in "${!ENV_VARS[@]}"; do
    if [ -z "${!VAR}" ]; then
        trace_error "The environment variable \${$VAR} is not set."
        print_environment_variable_usage "$VAR"
        exit 1
    fi
done

# Canadian cross-detection
if [ "$HOSTMACH" != "$BUILDMACH" ]; then
    trace_info "Build and host differ. Starting Canadian cross build..."
    redirect_output ./build-canadian.sh
    exit $?
fi

# Determine NCPU
if [ -z "$NCPU" ]; then
    if command -v nproc >/dev/null 2>&1; then
        export NCPU=$(nproc)
    elif command -v sysctl >/dev/null 2>&1; then
        export NCPU=$(sysctl -n hw.ncpu)
    else
        export NCPU=1
        trace_warning "Could not detect CPU count. Defaulting to NCPU=1"
    fi
fi

# Print version and environment summaries
trace_info "Version & Build Flags Summary"
echo "===== Version & Build Flags Summary ====="
declare -A VERSION_VARS=(
    ["BINUTILSVER"]="$BINUTILSVER"
    ["BINUTILSREV"]="$BINUTILSREV"
    ["GCCVER"]="$GCCVER"
    ["GCCREV"]="$GCCREV"
    ["NEWLIBVER"]="$NEWLIBVER"
    ["NEWLIBREV"]="$NEWLIBREV"
    ["MPCVER"]="$MPCVER"
    ["MPCREV"]="$MPCREV"
    ["MPFRVER"]="$MPFRVER"
    ["MPFRREV"]="$MPFRREV"
    ["GMPVER"]="$GMPVER"
    ["GMPREV"]="$GMPREV"
    ["GDBVER"]="$GDBVER"
    ["GDBREV"]="$GDBREV"
    ["ENABLE_BOOTSTRAP"]="$ENABLE_BOOTSTRAP"
    ["ENABLE_DOWNLOAD_CACHE"]="$ENABLE_DOWNLOAD_CACHE"
    ["ENABLE_STATIC_BUILD"]="$ENABLE_STATIC_BUILD"
    ["REQUIRED_AUTOMAKE_VERSION"]="$REQUIRED_AUTOMAKE_VERSION"
    ["DOWNLOAD_RETRIES"]="$DOWNLOAD_RETRIES"
    ["DOWNLOAD_RETRY_DELAY"]="$DOWNLOAD_RETRY_DELAY"
    ["DOWNLOAD_CONNECT_TIMEOUT"]="$DOWNLOAD_CONNECT_TIMEOUT"
)

# Print version variables
for var in "${!VERSION_VARS[@]}"; do
    if [ -n "${VERSION_VARS[$var]}" ]; then
        printf "\e[1;34m[ INFO ]\e[0m %-22s = %s\n" "$var" "${VERSION_VARS[$var]}"
    fi
done

echo
trace_info "Environment Summary"
echo "===== Environment Summary ====="

declare -a ENV_LIST=(
    INSTALLDIR SYSROOTDIR ROOTDIR DOWNLOADDIR RELSRCDIR SRCDIR BUILDDIR
    BUILDMACH HOSTMACH GCC_BOOTSTRAP PROGRAM_PREFIX TARGETMACH OBJFORMAT
    BINUTILS_CFLAGS GCC_BOOTSTRAP_FLAGS GCC_FINAL_FLAGS QTIFWDIR
)

# Find maximum variable name length
max_length=0
for VAR in "${ENV_LIST[@]}"; do
    if [ -n "${!VAR}" ]; then
        length=${#VAR}
        if (( length > max_length )); then
            max_length=$length
        fi
    fi
done

# Print environment variables with consistent alignment
for VAR in "${ENV_LIST[@]}"; do
    if [ -n "${!VAR}" ]; then
        printf "\e[1;34m[ INFO ]\e[0m %-${max_length}s = %s\n" "$VAR" "${!VAR}"
    fi
done

echo
if [ "${ENABLE_VERBOSE_BUILD}" = "1" ]; then
    read -n 1 -s -r -p "Press any key to begin the build process..."
    echo
fi

# Clean install dir
if [ -d "$INSTALLDIR" ]; then
    trace_info "Cleaning installation directory..."
    redirect_output rm -rf "$INSTALLDIR"
fi

# Download phase (only if caching is disabled)
if [ "$ENABLE_DOWNLOAD_CACHE" != "1" ]; then
    trace_info "Downloading required files..."
    redirect_output ./download.sh || { trace_error "Failed to retrieve necessary files"; exit 1; }
    redirect_output ls -lR $DOWNLOADDIR
fi

# Build steps
trace_info "Extracting sources..."
redirect_output ./extract-source.sh || { trace_error "Failed to extract sources"; exit 1; }

trace_info "Applying patches..."
redirect_output ./patch.sh || { trace_error "Failed to patch sources"; exit 1; }

# Build automake if required
if [ -n "$REQUIRED_AUTOMAKE_VERSION" ]; then
    INSTALLED_AUTOMAKE_VERSION=""
    if command -v automake &>/dev/null; then
        INSTALLED_AUTOMAKE_VERSION=$(automake --version | head -n1 | awk '{print $NF}')
    fi

    if [ -z "$INSTALLED_AUTOMAKE_VERSION" ] || ! version_ge "$INSTALLED_AUTOMAKE_VERSION" "$REQUIRED_AUTOMAKE_VERSION"; then
        trace_info "Building automake..."
        redirect_output ./build-automake.sh || { trace_error "Failed to build automake"; exit 1; }
        trace_info "Updating PATH with new automake..."
        export PATH="$INSTALLDIR/bin:$PATH"
    fi
fi

trace_info "Building binutils..."
redirect_output ./build-binutils.sh || { trace_error "Failed to build binutils"; exit 1; }

trace_info "Building GCC bootstrap..."
redirect_output ./build-gcc-bootstrap.sh || { trace_error "Failed to build GCC bootstrap"; exit 1; }

trace_info "Building newlib..."
redirect_output ./build-newlib.sh || { trace_error "Failed to build newlib"; exit 1; }

#trace_info "Building libstdc++..."
#redirect_output ./build-libstdc++.sh || { trace_error "Failed to build libstdc++"; exit 1; }

trace_info "Building final GCC..."
redirect_output ./build-gcc-final.sh || { trace_error "Failed to build final GCC"; exit 1; }

if [ -n "${GDBVER}${GDBREV}" ]; then
    trace_info "Building GDB..."
    redirect_output ./build-gdb.sh || { trace_error "Failed to build GDB"; exit 1; }
fi

trace_success "Build completed successfully"