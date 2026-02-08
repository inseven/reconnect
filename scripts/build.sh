#!/bin/bash

# Reconnect -- Psion connectivity for macOS
#
# Copyright (C) 2024-2026 Jason Morley
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

set -e
set -o pipefail
set -x
set -u

SCRIPTS_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

SCRIPTS_DIRECTORY="$ROOT_DIRECTORY/scripts"
SOURCE_DIRECTORY="$ROOT_DIRECTORY/macos"
BUILD_DIRECTORY="$ROOT_DIRECTORY/build"
ARCHIVES_DIRECTORY="$ROOT_DIRECTORY/archives"
TEMPORARY_DIRECTORY="$ROOT_DIRECTORY/temp"
SPARKLE_DIRECTORY="$SCRIPTS_DIRECTORY/Sparkle"

KEYCHAIN_PATH="$TEMPORARY_DIRECTORY/temporary.keychain"
ARCHIVE_PATH="$BUILD_DIRECTORY/Reconnect.xcarchive"
ENV_PATH="$ROOT_DIRECTORY/.env"

RELEASE_NOTES_TEMPLATE_PATH="$SCRIPTS_DIRECTORY/release-notes.html"

RELEASE_SCRIPT_PATH="$SCRIPTS_DIRECTORY/release.sh"

IOS_XCODE_PATH=${IOS_XCODE_PATH:-/Applications/Xcode.app}
MACOS_XCODE_PATH=${MACOS_XCODE_PATH:-/Applications/Xcode.app}

source "$SCRIPTS_DIRECTORY/environment.sh"

# Check that the GitHub command is available on the path.
which gh || (echo "GitHub cli (gh) not available on the path." && exit 1)

# Process the command line arguments.
POSITIONAL=()
RELEASE=${RELEASE:-false}
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -r|--release)
        RELEASE=true
        shift
        ;;
        *)
        POSITIONAL+=("$1")
        shift
        ;;
    esac
done

# Generate a random string to secure the local keychain.
export TEMPORARY_KEYCHAIN_PASSWORD=`openssl rand -base64 14`

# Source the .env file if it exists to make local development easier.
if [ -f "$ENV_PATH" ] ; then
    echo "Sourcing .env..."
    source "$ENV_PATH"
fi

cd "$SOURCE_DIRECTORY"

# Select the correct Xcode.
sudo xcode-select --switch "$MACOS_XCODE_PATH"

# List the available schemes.
xcodebuild \
    -project Reconnect.xcodeproj \
    -list

# Clean up and recreate the output directories.

if [ -d "$BUILD_DIRECTORY" ] ; then
    rm -r "$BUILD_DIRECTORY"
fi
mkdir -p "$BUILD_DIRECTORY"

if [ -d "$ARCHIVES_DIRECTORY" ] ; then
    rm -r "$ARCHIVES_DIRECTORY"
fi
mkdir -p "$ARCHIVES_DIRECTORY"

# Create the a new keychain.
if [ -d "$TEMPORARY_DIRECTORY" ] ; then
    rm -rf "$TEMPORARY_DIRECTORY"
fi
mkdir -p "$TEMPORARY_DIRECTORY"
echo "$TEMPORARY_KEYCHAIN_PASSWORD" | build-tools create-keychain "$KEYCHAIN_PATH" --password

function cleanup {

    # Cleanup the temporary files, keychain and keys.
    cd "$ROOT_DIRECTORY"
    build-tools delete-keychain "$KEYCHAIN_PATH"
    rm -rf "$TEMPORARY_DIRECTORY"
    rm -rf ~/.appstoreconnect/private_keys
}

trap cleanup EXIT

# Build and test ReconnectCore.
swift build --package-path ReconnectCore
swift test --package-path ReconnectCore

# Determine the version and build number.
VERSION_NUMBER=`changes version`
BUILD_NUMBER=`build-number.swift`

# Import the certificates into our dedicated keychain.
echo "$DEVELOPER_ID_APPLICATION_CERTIFICATE_PASSWORD" | build-tools import-base64-certificate --password "$KEYCHAIN_PATH" "$DEVELOPER_ID_APPLICATION_CERTIFICATE_BASE64"

# Install the provisioning profiles.
build-tools install-provisioning-profile "profiles/Reconnect_Developer_ID_Profile.provisionprofile"
build-tools install-provisioning-profile "profiles/Reconnect_Menu_Developer_ID_Profile.provisionprofile"
build-tools install-provisioning-profile "profiles/Reconnect_Previews_Developer_ID_Profile.provisionprofile"

# Build and archive the macOS project.
sudo xcode-select --switch "$MACOS_XCODE_PATH"
xcodebuild \
    -project Reconnect.xcodeproj \
    -scheme "Reconnect" \
    -config Release \
    -archivePath "$ARCHIVE_PATH" \
    OTHER_CODE_SIGN_FLAGS="--keychain=\"${KEYCHAIN_PATH}\"" \
    CURRENT_PROJECT_VERSION=$BUILD_NUMBER \
    MARKETING_VERSION=$VERSION_NUMBER \
    clean archive
xcodebuild \
    -archivePath "$ARCHIVE_PATH" \
    -exportArchive \
    -exportPath "$BUILD_DIRECTORY" \
    -exportOptionsPlist "ExportOptions.plist"

# Apple recommends we use ditto to prepare zips for notarization.
# https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow
RELEASE_BASENAME="Reconnect-$VERSION_NUMBER-$BUILD_NUMBER"
RELEASE_ZIP_BASENAME="$RELEASE_BASENAME.zip"
RELEASE_ZIP_PATH="$BUILD_DIRECTORY/$RELEASE_ZIP_BASENAME"
pushd "$BUILD_DIRECTORY"
/usr/bin/ditto -c -k --keepParent "Reconnect.app" "$RELEASE_ZIP_BASENAME"
popd

# Install the private key.
mkdir -p ~/.appstoreconnect/private_keys/
API_KEY_PATH=~/".appstoreconnect/private_keys/AuthKey_${APPLE_API_KEY_ID}.p8"
echo -n "$APPLE_API_KEY_BASE64" | base64 --decode -o "$API_KEY_PATH"

# Validate the app before going any further.
codesign --verify --deep --strict --verbose=2 "$BUILD_DIRECTORY/Reconnect.app"

# Notarize the app.
xcrun notarytool submit "$RELEASE_ZIP_PATH" \
    --key "$API_KEY_PATH" \
    --key-id "$APPLE_API_KEY_ID" \
    --issuer "$APPLE_API_KEY_ISSUER_ID" \
    --output-format json \
    --wait | tee command-notarization-response.json
NOTARIZATION_ID=`cat command-notarization-response.json | jq -r ".id"`
NOTARIZATION_RESPONSE=`cat command-notarization-response.json | jq -r ".status"`

xcrun notarytool log \
    --key "$API_KEY_PATH" \
    --key-id "$APPLE_API_KEY_ID" \
    --issuer "$APPLE_API_KEY_ISSUER_ID" \
    "$NOTARIZATION_ID" | tee "$BUILD_DIRECTORY/notarization-log.json"

if [ "$NOTARIZATION_RESPONSE" != "Accepted" ] ; then
    echo "Failed to notarize app."
    exit 1
fi

# Remove the zip file used for notarization.
rm "$RELEASE_ZIP_PATH"

# Staple and validate the app; this bakes the notarization into the app in case the device trying to run it can't do an
# online check with Apple's servers for some reason.
xcrun stapler staple "$BUILD_DIRECTORY/Reconnect.app"
xcrun stapler validate "$BUILD_DIRECTORY/Reconnect.app"

# Next up, we perform a belt-and-braces check that the app validates after stapling.
codesign --verify --deep --strict --verbose=2 "$BUILD_DIRECTORY/Reconnect.app"

# Compress the stapled app and package it for release.
# Curiously, ditto, which Apple recommends for compressing app bundles only seems to create valid zip files when using
# Sequoia and subsequently notarizing the zip file. Since we need to recompress the stapled app package, we instead use
# `zip --symlinks` which, thankfully, seems to work just fine.
pushd "$BUILD_DIRECTORY"
zip --symlinks -r "$RELEASE_ZIP_BASENAME" "Reconnect.app"
rm -r "Reconnect.app"
popd

# Build Sparkle.
cd "$SPARKLE_DIRECTORY"
xcodebuild -project Sparkle.xcodeproj -scheme generate_appcast SYMROOT=`pwd`/.build
GENERATE_APPCAST=`pwd`/.build/Debug/generate_appcast

SPARKLE_PRIVATE_KEY_FILE="$TEMPORARY_DIRECTORY/private-key-file"
echo -n "$SPARKLE_PRIVATE_KEY_BASE64" | base64 --decode -o "$SPARKLE_PRIVATE_KEY_FILE"

# Generate the appcast.
cd "$ROOT_DIRECTORY"
cp "$RELEASE_ZIP_PATH" "$ARCHIVES_DIRECTORY"
changes notes --all --template "$RELEASE_NOTES_TEMPLATE_PATH" >> "$ARCHIVES_DIRECTORY/$RELEASE_BASENAME.html"
"$GENERATE_APPCAST" --ed-key-file "$SPARKLE_PRIVATE_KEY_FILE" "$ARCHIVES_DIRECTORY"
APPCAST_PATH="$ARCHIVES_DIRECTORY/appcast.xml"
cp "$APPCAST_PATH" "$BUILD_DIRECTORY"

# Archive the build directory.
cd "$ROOT_DIRECTORY"
ZIP_BASENAME="build-$VERSION_NUMBER-$BUILD_NUMBER.zip"
ZIP_PATH="$BUILD_DIRECTORY/$ZIP_BASENAME"
pushd "$BUILD_DIRECTORY"
zip -r "$ZIP_BASENAME" .
popd

if $RELEASE ; then

    changes \
        release \
        --skip-if-empty \
        --push \
        --exec "${RELEASE_SCRIPT_PATH}" \
        "${RELEASE_ZIP_PATH}" "${ZIP_PATH}" "$BUILD_DIRECTORY/appcast.xml"

fi
