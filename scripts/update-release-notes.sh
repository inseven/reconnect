#!/bin/bash

# Reconnect -- Psion connectivity for macOS
#
# Copyright (C) 2024-2025 Jason Morley
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

ROOT_DIRECTORY="$SCRIPTS_DIRECTORY/.."
RELEASE_NOTES_TEMPLATE_PATH="$SCRIPTS_DIRECTORY/release-notes.md"
RELEASE_NOTES_DIRECTORY="$ROOT_DIRECTORY/docs/release-notes"
RELEASE_NOTES_PATH="$RELEASE_NOTES_DIRECTORY/index.md"

source "$SCRIPTS_DIRECTORY/environment.sh"

cd "$ROOT_DIRECTORY"

mkdir -p "$RELEASE_NOTES_DIRECTORY"
changes notes --all --template "$RELEASE_NOTES_TEMPLATE_PATH" > "$RELEASE_NOTES_PATH"
