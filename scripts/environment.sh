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

ROOT_DIRECTORY="$( cd "$( dirname "$( dirname "${BASH_SOURCE[0]}" )" )" &> /dev/null && pwd )"
SCRIPTS_DIRECTORY="$ROOT_DIRECTORY/scripts"

export LOCAL_TOOLS_PATH="$ROOT_DIRECTORY/.local"

# Keep Python user installs local to the project instead of polluting the host.
export PYTHONUSERBASE="$LOCAL_TOOLS_PATH/python"
mkdir -p "$PYTHONUSERBASE"
export PATH="$PYTHONUSERBASE/bin":$PATH

# Keep pipenv virtualenvs local and predictable.
export WORKON_HOME="$LOCAL_TOOLS_PATH"
export PIPENV_CUSTOM_VENV_NAME="venv"
export PIPENV_VENV_IN_PROJECT=0
export PIPENV_IGNORE_VIRTUALENVS=1
export PIPENV_PIPFILE="$SCRIPTS_DIRECTORY/Pipfile"

# Add the tools to the path.
export PATH="$LOCAL_TOOLS_PATH/venv/bin":$PATH
