#!/bin/bash

export OBJFORMAT=ELF

export TARGETMACH=sh-elf

if [ -z ${PROGRAM_PREFIX} ]; then
	export PROGRAM_PREFIX=saturn-sh2-elf-
else
	export PROGRAM_PREFIX=${PROGRAM_PREFIX}elf-
fi

export BINUTILS_CFLAGS="-s"
export GCC_BOOTSTRAP_FLAGS="--with-cpu=m2"
export GCC_FINAL_FLAGS="--with-cpu=m2 --with-sysroot=$SYSROOTDIR"

./build.sh

if [ $? -ne 0 ]; then
	echo "Failed to build the ELF toolchain"
	exit 1
fi

if [[ "${CREATEINSTALLER}" == "YES" ]]; then
	./createinstaller.sh
fi
