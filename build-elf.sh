#!/bin/bash

# Source environment variables from var-elf.sh
source ./var-elf.sh

# Run the build script
./build.sh

# Check if the build script succeeded
if [ $? -ne 0 ]; then
    echo "Failed to build the ELF toolchain"
    exit 1
fi

# Create the installer if requested
if [[ "${CREATEINSTALLER}" == "YES" ]]; then
    ./createinstaller.sh
fi
