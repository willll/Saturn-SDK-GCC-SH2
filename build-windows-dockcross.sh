#!/bin/bash
set -e

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# Source default component versions from versions.sh
# We temporarily clear positional parameters to prevent versions.sh's 'exec "$@"' from terminating this script
SAVED_ARGS=("$@")
set --
source "$(dirname "${BASH_SOURCE[0]}")/versions.sh"
set -- "${SAVED_ARGS[@]}"

# Default settings
: "${DOCKCROSS_IMAGE:="dockcross/windows-static-x64"}"
: "${OBJFORMAT:="ELF"}"

trace_info "Preparing static Windows build using dockcross..."

# Check for docker
if ! command -v docker >/dev/null 2>&1; then
    trace_error "Docker is required but not installed."
    exit 1
fi

# Generate dockcross script if it doesn't exist
if [ ! -f "./dockcross" ]; then
    trace_info "Generating dockcross script from image: ${DOCKCROSS_IMAGE}"
    docker run --rm "${DOCKCROSS_IMAGE}" > ./dockcross
    chmod +x ./dockcross
fi

# Determine host triplet for the container environment
if [[ "${DOCKCROSS_IMAGE}" == *"x64"* ]]; then
    HOST_TRIPLET="x86_64-w64-mingw32"
else
    HOST_TRIPLET="i686-w64-mingw32"
fi

trace_info "Launching build for ${OBJFORMAT} targeting ${HOST_TRIPLET}..."

# Execute the build inside the container.
# We explicitly set BUILDMACH and HOSTMACH to trigger Canadian Cross logic.
./dockcross bash -c "
    export BUILDMACH=x86_64-pc-linux-gnu
    export HOSTMACH=${HOST_TRIPLET}
    export ENABLE_STATIC_BUILD=1
    export ENABLE_DOWNLOAD_CACHE=${ENABLE_DOWNLOAD_CACHE}
    export CREATEINSTALLER=YES
    
    # Versions passed from host environment (sourced from versions.sh)
    export BINUTILSVER=${BINUTILSVER}
    export BINUTILSREV=${BINUTILSREV}
    export GCCVER=${GCCVER}
    export GCCREV=${GCCREV}
    export NEWLIBVER=${NEWLIBVER}
    export NEWLIBREV=${NEWLIBREV}
    export MPCVER=${MPCVER}
    export MPCREV=${MPCREV}
    export MPFRVER=${MPFRVER}
    export MPFRREV=${MPFRREV}
    export GMPVER=${GMPVER}
    export GMPREV=${GMPREV}
    export GDBVER=${GDBVER}
    export GDBREV=${GDBREV}

    # Windows-specific overrides can be set here
    # Example: export GCCVER=\"15.1.0\"

    if [ \"${OBJFORMAT^^}\" == \"ELF\" ]; then
        ./build-elf.sh
    else
        ./build-coff.sh
    fi
"

trace_success "Windows static build process completed."
