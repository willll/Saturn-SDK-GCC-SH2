#!/bin/bash
set -e

# Source common utilities
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

trace_info "Setting up version information..."
export TAG_NAME=$(git describe --tags | sed -e 's/_[0-9].*//')
export VERSION_NUM=$(git describe --match "${TAG_NAME}_[0-9]*" HEAD | sed -e 's/-g.*//' -e "s/${TAG_NAME}_//")
export MAJOR_BUILD_NUM=$(echo $VERSION_NUM | sed 's/-[^.]*$//' | sed -r 's/.[^.]*$//' | sed -r 's/.[^.]*$//')
export MINOR_BUILD_NUM=9
export REVISION_BUILD_NUM=3
export BUILD_NUM=0

if [ -z "$TAG_NAME" ]; then
    trace_warning "Tag name not found, using 'unknown'"
    TAG_NAME=unknown
fi

if [ -z "$MAJOR_BUILD_NUM" ]; then
    trace_warning "Major build number not found, using '0'"
    MAJOR_BUILD_NUM=0
fi

if [ -z "$MINOR_BUILD_NUM" ]; then
    MINOR_BUILD_NUM=0
fi

if [ -z "$REVISION_BUILD_NUM" ]; then
    REVISION_BUILD_NUM=0
fi

if [ -z "$BUILD_NUM" ]; then
    BUILD_NUM=0
fi

trace_info "Creating installer package directories..."
redirect_output mkdir -p "$ROOTDIR/installerpackage/"{org.opengamedevelopers.sega.saturn.sdk.gcc/{data,meta},config}

trace_info "Generating package metadata..."
cat > "$ROOTDIR/installerpackage/org.opengamedevelopers.sega.saturn.sdk.gcc/meta/package.xml" << __EOF__
<?xml version="1.0" encoding="UTF-8"?>
<Package>
    <DisplayName>SEGA Saturn SDK GCC ${GCCVER}${GCCREV}</DisplayName>
    <Description>GCC ${GCCVER} optimised for the SEGA Saturn Hitachi SH-2 [${OBJFORMAT}]. Host compiler: $HOSTMACH</Description>
    <Version>${MAJOR_BUILD_NUM}.${MINOR_BUILD_NUM}.${REVISION_BUILD_NUM}.${BUILD_NUM}</Version>
    <Name>org.opengamedevelopers.sega.saturn.sdk.gcc</Name>
    <ReleaseDate>$(git log --pretty=format:"%ci" -1 | sed -e 's/ [^ ]*$//g')</ReleaseDate>
    <Licenses>
        <License name="GNU Public License Ver. 3" file="gplv3.txt" />
    </Licenses>
</Package>
__EOF__

trace_info "Downloading GPL license..."
redirect_output wget -c -O "$ROOTDIR/installerpackage/org.opengamedevelopers.sega.saturn.sdk.gcc/meta/gplv3.txt" https://www.gnu.org/licenses/gpl-3.0.txt || {
    trace_error "Failed to download GPL license"
    exit 1
}

trace_info "Creating installer archive..."
redirect_output "$QTIFWDIR/bin/archivegen" "$ROOTDIR/installerpackage/org.opengamedevelopers.sega.saturn.sdk.gcc/data/directory.7z" "$INSTALLDIR" || {
    trace_error "Failed to create installer archive"
    exit 1
}
trace_success "Installer archive created"

trace_info "Cleaning up previous installer files..."
redirect_output rm -rf "$ROOTDIR/installerpackage/gcc"

trace_info "Generating installer components..."
redirect_output "$QTIFWDIR/bin/archivegen" "$ROOTDIR/installerpackage/org.opengamedevelopers.sega.saturn.sdk.gcc/data/directory.7z" "$INSTALLDIR" || {
    trace_error "Failed to create archive"
    exit 1
}

trace_info "Generating repository..."
redirect_output "$QTIFWDIR/bin/repogen" -p "$ROOTDIR/installerpackage" -i org.opengamedevelopers.sega.saturn.sdk.gcc "$ROOTDIR/installerpackage/gcc" || {
    trace_error "Failed to generate repository"
    exit 1
}

trace_info "Copying package files..."
redirect_output cp -r "$ROOTDIR/installerpackage/org.opengamedevelopers.sega.saturn.sdk.gcc" "$ROOTDIR/installerpackage/packages" || {
    trace_error "Failed to copy package files"
    exit 1
}

trace_info "Creating installer binary..."
redirect_output "$QTIFWDIR/bin/binarycreator.exe" --offline-only \
    -t "$QTIFWDIR/bin/installerbase.exe" \
    -p "$ROOTDIR/installerpackage/packages" \
    -c "$ROOTDIR/installerpackage/config/config.xml" \
    SSDKInstaller.exe || {
        trace_error "Failed to create installer binary"
        exit 1
    }

trace_success "Installer creation completed successfully"