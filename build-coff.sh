#!/bin/bash

./build.sh

if [ $? -ne 0 ]; then
	echo "Failed to build the COFF toolchain"
	exit 1
fi

if [[ "${CREATEINSTALLER}" == "YES" ]]; then
	./createinstaller.sh
fi
