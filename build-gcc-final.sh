#!/bin/bash
set -e

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

if [ -d "$BUILDDIR/gcc-final" ]; then
    trace_info "Removing existing final GCC build directory..."
    redirect_output rm -rf "$BUILDDIR/gcc-final"
fi

trace_info "Creating final GCC build directory..."
redirect_output mkdir -p "$BUILDDIR/gcc-final"
cd "$BUILDDIR/gcc-final" || {
    trace_error "Failed to change to final GCC build directory"
    exit 1
}

export PATH=$INSTALLDIR/bin:$PATH

# Force unversioned local autotools to avoid aclocal-1.xx/automake-1.xx lookups.
AUTOTOOLS_VARS=(
    ACLOCAL=aclocal
    AUTOMAKE=automake
    AUTORECONF=autoreconf
    AUTOHEADER=autoheader
    AUTOCONF=autoconf
)

MAKE_TOOL_VARS=()
if [[ "$HOSTMACH" == *mingw* ]]; then
    WINDRES_CMD=""

    for CANDIDATE in \
        "${HOSTMACH}-windres" \
        "${HOSTMACH%%.*}-windres"; do
        if command -v "$CANDIDATE" >/dev/null 2>&1; then
            WINDRES_CMD="$CANDIDATE"
            break
        fi
    done

    if [[ -z "$WINDRES_CMD" && -n "$CC" ]]; then
        CC_BASENAME=$(basename "$CC")
        CC_PREFIX="${CC_BASENAME%-gcc}"
        CC_PREFIX="${CC_PREFIX%-g++}"
        CANDIDATE="${CC_PREFIX}-windres"
        if command -v "$CANDIDATE" >/dev/null 2>&1; then
            WINDRES_CMD="$CANDIDATE"
        fi
    fi

    if [[ -n "$WINDRES_CMD" ]]; then
        trace_info "Using WINDRES=${WINDRES_CMD}"
        MAKE_TOOL_VARS+=("WINDRES=${WINDRES_CMD}")
    fi
fi

trace_info "Setting up build flags..."
export CFLAGS="-s -DCOMMON_LVB_REVERSE_VIDEO=0x4000 -DCOMMON_LVB_UNDERSCORE=0x8000"
export CXXFLAGS="-s -DCOMMON_LVB_REVERSE_VIDEO=0x4000 -DCOMMON_LVB_UNDERSCORE=0x8000"
export LDFLAGS=""

if [[ "$ENABLE_STATIC_BUILD" != "0" ]]; then
    trace_info "Enabling static build..."
    CFLAGS+=" -static"
    CXXFLAGS+=" -static"
    LDFLAGS+=" -static"
fi

export CDIR=$PWD

trace_info "Configuring final GCC build..."
redirect_output ../../source/gcc-${GCCVER}${GCCREV}/configure \
    --build="$BUILDMACH" \
    --target="$TARGETMACH" \
    --host="$HOSTMACH" \
    --prefix="$INSTALLDIR" \
    --enable-languages=c,c++ \
    $GCC_BOOTSTRAP \
    --with-gnu-as \
    --with-gnu-ld \
    --disable-shared \
    --disable-threads \
    --disable-multilib \
    --disable-libmudflap \
    --enable-libssp \
    --enable-lto \
    --disable-install-libiberty \
    --disable-nls \
    --with-newlib \
    --with-sysroot=$INSTALLDIR/$TARGETMACH \
    --enable-offload-target="$TARGETMACH" \
    --disable-decimal-float \
    --program-prefix="${PROGRAM_PREFIX}" \
    ${GCC_FINAL_FLAGS} || {
        trace_error "Configuration failed"
        exit 1
    }
trace_success "Configuration completed"

trace_info "Building final GCC..."
redirect_output make $MAKEFLAGS MAKEINFO=true "${AUTOTOOLS_VARS[@]}" "${MAKE_TOOL_VARS[@]}" || {
    trace_error "Build failed"
    exit 1
}

trace_info "Installing final GCC..."
redirect_output make install $MAKEFLAGS MAKEINFO=true "${AUTOTOOLS_VARS[@]}" "${MAKE_TOOL_VARS[@]}" || {
    trace_error "Installation failed"
    exit 1
}

trace_info "Building target libstdc++-v3..."
redirect_output make all-target-libstdc++-v3 $MAKEFLAGS MAKEINFO=true "${AUTOTOOLS_VARS[@]}" "${MAKE_TOOL_VARS[@]}" || {
    trace_error "Target libstdc++-v3 build failed"
    exit 1
}

trace_info "Installing target libstdc++-v3..."
redirect_output make install-target-libstdc++-v3 $MAKEFLAGS MAKEINFO=true "${AUTOTOOLS_VARS[@]}" "${MAKE_TOOL_VARS[@]}" || {
    trace_error "Target libstdc++-v3 installation failed"
    exit 1
}

cd "${CDIR}" || {
    trace_error "Failed to return to original directory"
    exit 1
}

trace_success "Final GCC build completed successfully"