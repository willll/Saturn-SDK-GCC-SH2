#!/bin/bash
set -e

# ==============================================================================
# Helper script to build Saturn SDK GCC Toolchain via Docker containers
# Target platforms: linux-x64, windows-x64, macos-arm64
# ==============================================================================

USAGE="Usage: $0 [linux-x64|windows-x64|macos-arm64|all]"
TARGET="${1:-all}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_BASE_DIR="${ROOT_DIR}/toolchain-output"

build_target() {
    local platform="$1"
    local dockerfile="Dockerfile.${platform}"
    local tag="saturn-sdk-build:${platform}"
    local out_dir="${OUTPUT_BASE_DIR}/${platform}"

    echo -e "\e[1;34m[ DOCKER ]\e[0m Building image for platform: ${platform}..."
    docker build -t "${tag}" -f "${dockerfile}" "${ROOT_DIR}"

    echo -e "\e[1;34m[ DOCKER ]\e[0m Running build container for ${platform}..."
    mkdir -p "${out_dir}"
    docker run --rm -v "${out_dir}:/saturn-sdk/toolchain" "${tag}"

    echo -e "\e[1;32m[  OK  ]\e[0m Build complete for ${platform}. Output placed in: ${out_dir}"
}

case "$TARGET" in
    linux-x64)
        build_target "linux-x64"
        ;;
    windows-x64)
        build_target "windows-x64"
        ;;
    macos-arm64)
        build_target "macos-arm64"
        ;;
    all)
        build_target "linux-x64"
        build_target "windows-x64"
        build_target "macos-arm64"
        ;;
    *)
        echo "$USAGE"
        exit 1
        ;;
esac
