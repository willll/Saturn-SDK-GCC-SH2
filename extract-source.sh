#!/bin/bash
# Unpacks the source tarballs into $SRCDIR and links GMP, MPFR and MPC into the GCC tree

echo "Extracting source files..."

mkdir -p "$SRCDIR" && cd "$SRCDIR" || exit 1
rm -rf .extract.*

GCCDIR=gcc-${GCCVER}${GCCREV}

# extract <package> <folder> <extension>
extract() {
	[ -d "$2" ] && return 0
	local tarball=$DOWNLOADDIR/$2.$3
	[[ "$ENABLE_DOWNLOAD_CACHE" == "1" ]] && tarball=$ROOTDIR/gnu/$1/$2.$3
	# Unpack beside the final folder and move it in only when complete, so an interrupted run leaves nothing half-filled
	local tmp
	tmp=$(mktemp -d .extract.XXXXXX) || exit 1
	if ! tar xpf "$tarball" -C "$tmp" || ! mv "$tmp/$2" "$2"; then
		rm -rf "$tmp"
		exit 1
	fi
	rm -rf "$tmp"
}

# in_gcc <package> <folder>: GCC builds GMP, MPFR and MPC in-tree from gcc-x.y.z/<package>
in_gcc() {
	rm -rf "$GCCDIR/$1"
	cp -r "$2" "$GCCDIR/$1" || exit 1
}

extract binutils binutils-${BINUTILSVER}${BINUTILSREV} tar.xz
extract gcc $GCCDIR tar.xz
extract newlib newlib-${NEWLIBVER}${NEWLIBREV} tar.gz

if [ -n "${GDBVER}${GDBREV}" ]; then
	extract gdb gdb-${GDBVER}${GDBREV} tar.gz
fi

if [ -n "${MPCVER}${MPCREV}" ]; then
	extract mpc mpc-${MPCVER}${MPCREV} tar.gz
	in_gcc mpc mpc-${MPCVER}${MPCREV}
fi

if [ -n "${MPFRVER}${MPFRREV}" ]; then
	extract mpfr mpfr-${MPFRVER}${MPFRREV} tar.xz
	in_gcc mpfr mpfr-${MPFRVER}${MPFRREV}
fi

if [ -n "${GMPVER}${GMPREV}" ]; then
	extract gmp gmp-${GMPVER}${GMPREV} tar.xz
	in_gcc gmp gmp-${GMPVER}${GMPREV}
fi

echo "Done"
