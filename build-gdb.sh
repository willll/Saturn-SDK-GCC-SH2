#!/bin/sh
set -e

[ -d $BUILDDIR/gdb ] && rm -rf $BUILDDIR/gdb

mkdir -p $BUILDDIR/gdb
cd $BUILDDIR/gdb

$SRCDIR/gdb-${GDBVER}${GDBREV}/configure \
	--host=${HOSTMACH} --build=${BUILDMACH} --target=${TARGETMACH} \
	--prefix=${INSTALLDIR} --program-prefix=${PROGRAM_PREFIX}

make all-gdb $MAKEFLAGS
make install-gdb $MAKEFLAGS
