#!/bin/bash

echo "Building automake..."

if [ ! -d $BUILDDIR/automake ]; then
    mkdir -p $BUILDDIR/automake
fi

cd $BUILDDIR/automake

# Configure automake
if [ ! -f Makefile ]; then
    echo "Configuring automake..."
    
    CONF_FLAGS="--prefix=$INSTALLDIR"
    
    if [ "$ENABLE_STATIC_BUILD" = "1" ]; then
        CONF_FLAGS="$CONF_FLAGS --enable-static --disable-shared"
    fi
    
    $SRCDIR/automake-${REQUIRED_VERSION}/configure $CONF_FLAGS || exit 1
fi

# Build and install
echo "Building automake..."
make -j$NCPU || exit 1

echo "Installing automake..."
make install || exit 1

echo "Done building automake"