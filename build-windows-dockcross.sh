#!/bin/bash
set -e

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

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
    export CREATEINSTALLER=YES
    
    if [ \"${OBJFORMAT^^}\" == \"ELF\" ]; then
        ./build-elf.sh
    else
        ./build-coff.sh
    fi
"

trace_success "Windows static build process completed."
