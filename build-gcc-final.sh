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

trace_info "Setting up build flags..."
export CFLAGS="-s -DCOMMON_LVB_REVERSE_VIDEO=0x4000 -DCOMMON_LVB_UNDERSCORE=0x8000 -std=c99"
export CXXFLAGS="-s -DCOMMON_LVB_REVERSE_VIDEO=0x4000 -DCOMMON_LVB_UNDERSCORE=0x8000 -std=c++11"
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
    --enable-languages=c,c++,lto \
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
    --enable-offload-target="$TARGETMACH" \
    --disable-decimal-float \
    --program-prefix="${PROGRAM_PREFIX}" \
    ${GCC_FINAL_FLAGS} || {
        trace_error "Configuration failed"
        exit 1
    }
trace_success "Configuration completed"

trace_info "Building final GCC..."
redirect_output make $MAKEFLAGS || {
    trace_error "Build failed"
    exit 1
}

trace_info "Installing final GCC..."
redirect_output make install $MAKEFLAGS || {
    trace_error "Installation failed"
    exit 1
}

cd "${CDIR}" || {
    trace_error "Failed to return to original directory"
    exit 1
}

trace_success "Final GCC build completed successfully"
