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
WEBSITE_DIRECTORY="$ROOT_DIRECTORY/docs"
WEBSITE_SIMULATOR_DIRECTORY="$ROOT_DIRECTORY/docs/simulator"
SIMULATOR_WEB_DIRECTORY="$ROOT_DIRECTORY/simulator/web"

RELEASE_NOTES_TEMPLATE_PATH="$SCRIPTS_DIRECTORY/release-notes.md"
HISTORY_PATH="$SCRIPTS_DIRECTORY/history.yaml"
RELEASE_NOTES_DIRECTORY="$ROOT_DIRECTORY/docs/release-notes"
RELEASE_NOTES_PATH="$RELEASE_NOTES_DIRECTORY/index.markdown"

source "$SCRIPTS_DIRECTORY/environment.sh"

cd "$ROOT_DIRECTORY"
if [ -d "$RELEASE_NOTES_DIRECTORY" ]; then
    rm -r "$RELEASE_NOTES_DIRECTORY"
fi
"$SCRIPTS_DIRECTORY/update-release-notes.sh"

# Install the Jekyll dependencies.
export GEM_HOME="${ROOT_DIRECTORY}/.local/ruby"
mkdir -p "$GEM_HOME"
export PATH="${GEM_HOME}/bin":$PATH
gem install bundler
cd "${WEBSITE_DIRECTORY}"
bundle install

# Get the latest release URL.
if ! DOWNLOAD_URL=$(build-tools latest-github-release inseven folders "Folders-*.zip"); then
    echo >&2 failed
    exit 1
fi
# Belt-and-braces check that we managed to get the download URL.
if [[ -z "$DOWNLOAD_URL" ]]; then
    echo "Failed to get release download URL."
    exit 1
fi

# Build the website.
cd "${WEBSITE_DIRECTORY}"
export DOWNLOAD_URL
bundle exec jekyll build
