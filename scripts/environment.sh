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

SCRIPTS_DIRECTORY="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIRECTORY="$SCRIPTS_DIRECTORY/.."

export LOCAL_TOOLS_PATH="$ROOT_DIRECTORY/.local"

export PYTHONUSERBASE="$LOCAL_TOOLS_PATH/python"
mkdir -p "$PYTHONUSERBASE"
export PATH="$PYTHONUSERBASE/bin":$PATH
export PYTHONPATH=$PYTHONUSERBASE

export PATH=$PATH:"$SCRIPTS_DIRECTORY/changes"
export PATH=$PATH:"$SCRIPTS_DIRECTORY/build-tools"
export PATH=$PATH:"$ROOT_DIRECTORY/dependencies/diligence/scripts"
