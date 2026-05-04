
#!/bin/bash
set -e

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

if [ -d "$BUILDDIR/gcc-bootstrap" ]; then
    trace_info "Removing existing bootstrap directory..."
    redirect_output rm -rf "$BUILDDIR/gcc-bootstrap"
fi

trace_info "Creating bootstrap build directory..."
redirect_output mkdir -p "$BUILDDIR/gcc-bootstrap"
cd "$BUILDDIR/gcc-bootstrap" || {
    trace_error "Failed to change to bootstrap build directory"
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

trace_info "Configuring GCC bootstrap..."
redirect_output ../../source/gcc-${GCCVER}${GCCREV}/configure \
    --build="$BUILDMACH" \
    --host="$HOSTMACH" \
    --target="$TARGETMACH" \
    --prefix="$INSTALLDIR" \
    --without-headers $GCC_BOOTSTRAP \
    --enable-languages=c \
    --disable-threads \
    --disable-libmudflap \
    --with-gnu-ld \
    --with-gnu-as \
    --with-gcc \
    --enable-libssp \
    --disable-libgomp \
    --disable-nls \
    --disable-shared \
    --program-prefix="${PROGRAM_PREFIX}" \
    --with-newlib \
    --disable-multilib \
    --disable-libgcj \
    --without-included-gettext \
    --disable-libstdcxx \
    --disable-lto \
    ${GCC_BOOTSTRAP_FLAGS} || {
        trace_error "Configuration failed"
        exit 1
    }
trace_success "Configuration completed"

trace_info "Building GCC compiler..."
redirect_output make all-gcc $MAKEFLAGS MAKEINFO=true "${AUTOTOOLS_VARS[@]}" "${MAKE_TOOL_VARS[@]}" || {
    trace_error "GCC compiler build failed"
    exit 1
}

trace_info "Installing GCC compiler..."
redirect_output make install-gcc $MAKEFLAGS MAKEINFO=true "${AUTOTOOLS_VARS[@]}" "${MAKE_TOOL_VARS[@]}" || {
    trace_error "GCC compiler installation failed"
    exit 1
}

trace_info "Building target libgcc..."
redirect_output make all-target-libgcc $MAKEFLAGS MAKEINFO=true "${AUTOTOOLS_VARS[@]}" "${MAKE_TOOL_VARS[@]}" || {
    trace_error "Target libgcc build failed"
    exit 1
}

trace_info "Installing target libgcc..."
redirect_output make install-target-libgcc $MAKEFLAGS MAKEINFO=true "${AUTOTOOLS_VARS[@]}" "${MAKE_TOOL_VARS[@]}" || {
    trace_error "Target libgcc installation failed"
    exit 1
}

cd "${CDIR}" || {
    trace_error "Failed to return to original directory"
    exit 1
}

trace_success "GCC bootstrap build completed successfully"
