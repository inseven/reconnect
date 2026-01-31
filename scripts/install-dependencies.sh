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

ROOT_DIRECTORY="$( cd "$( dirname "$( dirname "${BASH_SOURCE[0]}" )" )" &> /dev/null && pwd )"
SCRIPTS_DIRECTORY="$ROOT_DIRECTORY/scripts"

LOCAL_TOOLS_PATH="$ROOT_DIRECTORY/.local"
CHANGES_DIRECTORY="$SCRIPTS_DIRECTORY/changes"
BUILD_TOOLS_DIRECTORY="$SCRIPTS_DIRECTORY/build-tools"

# Install tools defined in `.tool-versions`.
cd "$ROOT_DIRECTORY"
mise install

# Clean up and recreate the local tools directory.
if [ -d "$LOCAL_TOOLS_PATH" ] ; then
    rm -r "$LOCAL_TOOLS_PATH"
fi
mkdir -p "$LOCAL_TOOLS_PATH"

# Set up a Python venv to bootstrap our python dependency on `pipenv`.
python -m venv "$LOCAL_TOOLS_PATH/python"

# Source `environment.sh` to ensure the remainder of our paths are set up correctly.
source "$SCRIPTS_DIRECTORY/environment.sh"

# Install the Python dependencies.
pip install --upgrade pip pipenv wheel certifi
PIPENV_PIPFILE="$CHANGES_DIRECTORY/Pipfile" pipenv install
PIPENV_PIPFILE="$BUILD_TOOLS_DIRECTORY/Pipfile" pipenv install
