#!/bin/bash
# Applies patches/<package>/<version>/*.patch to the sources in $SRCDIR

cd "$SRCDIR" || exit 1

for dir in "$ROOTDIR/patches/binutils/${BINUTILSVER}${BINUTILSREV}" "$ROOTDIR/patches/gcc/${GCCVER}${GCCREV}"; do
	for file in "$dir"/*.patch; do
		[ -f "$file" ] || continue
		# patch -N exits 1 both when a patch is already applied and when it fails, so test the reverse first
		if patch -Rp1 -sf --dry-run -i "$file" >/dev/null; then
			echo "Already applied patch ${file}"
		elif patch -Np1 -i "$file"; then
			echo "Patched ${file}"
		else
			echo "Failed to apply patch ${file}"
			exit 1
		fi
	done
done

exit 0
