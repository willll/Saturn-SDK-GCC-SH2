#!/bin/bash
# Downloads the source tarballs into $DOWNLOADDIR and checks their GPG signatures

mkdir -p "$DOWNLOADDIR" && cd "$DOWNLOADDIR" || exit 1

if command -v curl >/dev/null; then
	FETCH="curl --retry 5 --retry-delay 5 --connect-timeout 30 -f -L -O -J"
elif command -v wget >/dev/null; then
	FETCH="wget --tries=5 -c"
else
	echo "Could not find either curl or wget, please install either one to continue"
	exit 1
fi

# fetch <url>
fetch() {
	local file
	file=$(basename "$1")
	$FETCH "$1" && [ -f "$file" ] || { echo "$file not downloaded."; exit 1; }
}

# fetch_verified <url>: also fetch the .sig and check it against the keyring in git, not one from the same server
fetch_verified() {
	fetch "$1"
	fetch "$1.sig"
	gpg --verify --keyring "$ROOTDIR/gnu/gnu-keyring.gpg" "$(basename "$1").sig" || { echo "Failed to verify GPG signature for $(basename "$1")"; exit 1; }
}

# fetch_sha256 <url> <sha256>: for old releases published without a signature
fetch_sha256() {
	fetch "$1"
	echo "$2  $(basename "$1")" | sha256sum -c - || { echo "Checksum mismatch for $(basename "$1")"; exit 1; }
}

GNU=https://ftp.gnu.org/gnu

fetch_verified $GNU/binutils/binutils-${BINUTILSVER}${BINUTILSREV}.tar.xz
# GCC 2.95.3 has no .sig: check the SHA-256 of the tarball that matches ftp.gnu.org's md5sum.txt
fetch_sha256 $GNU/gcc/gcc-${GCCVER}${GCCREV}/gcc-everything-${GCCVER}${GCCREV}.tar.gz 2a950e220c2f64c4abf781be3bb6d4c472ef8b3685873e77061788df85c6d5da
# sourceware publishes no signature for newlib
fetch https://sourceware.org/pub/newlib/newlib-${NEWLIBVER}${NEWLIBREV}.tar.gz
[ -z "${GDBVER}" ] || fetch_verified $GNU/gdb/gdb-${GDBVER}${GDBREV}.tar.gz
[ -z "${MPCVER}" ] || fetch_verified $GNU/mpc/mpc-${MPCVER}${MPCREV}.tar.gz
[ -z "${MPFRVER}" ] || fetch_verified $GNU/mpfr/mpfr-${MPFRVER}${MPFRREV}.tar.xz
[ -z "${GMPVER}" ] || fetch_verified $GNU/gmp/gmp-${GMPVER}${GMPREV}.tar.xz
