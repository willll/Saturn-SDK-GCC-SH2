#!/bin/bash
export BINUTILSVER=2.32
export BINUTILSREV=
export GCCVER=9.1.0
export GCCREV=
export NEWLIBVER=3.1.0
export NEWLIBREV=
export MPCVER=1.1.0
export MPCREV=
export MPFRVER=4.0.2
export MPFRREV=
export GMPVER=6.1.2
export GMPREV=

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
