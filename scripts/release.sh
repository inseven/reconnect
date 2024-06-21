#!/bin/bash

# Reconnect -- Psion connectivity for macOS
#
# Copyright (C) 2024 Jason Morley
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

# This script expects the macOS PKG as the first argument, and any additional files to be attached to the GitHub release
# to be passed as subsequent arguments.

# Upload the macOS build.
xcrun altool --upload-app \
    -f "$1" \
    --primary-bundle-id "uk.co.jbmorley.thoughts.apps.appstore" \
    --apiKey "$APPLE_API_KEY_ID" \
    --apiIssuer "$APPLE_API_KEY_ISSUER_ID" \
    --type macos

# Actually make the release.
FLAGS=()
if $CHANGES_INITIAL_DEVELOPMENT ; then
    FLAGS+=("--prerelease")
elif $CHANGES_PRE_RELEASE ; then
    FLAGS+=("--prerelease")
fi
gh release create "$CHANGES_TAG" --title "$CHANGES_QUALIFIED_TITLE" --notes-file "$CHANGES_NOTES_FILE" "${FLAGS[@]}"

# Upload the attachments.
for attachment in "$@"
do
    gh release upload "$CHANGES_TAG" "$attachment"
done
