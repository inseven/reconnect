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
# set -x
set -u

# Process the command line arguments.
POSITIONAL=()
HELP=false
TRANSPARENCY="#00ff00"
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -h|--help)
        HELP=true
        shift
        ;;
        -t|--transparency)
        shift
        TRANSPARENCY=$1
        shift
        ;;
        *)
        POSITIONAL+=("$1")
        shift
        ;;
    esac
done

if [[ "${#POSITIONAL[@]}" -ne 2 ]] ; then
    HELP=true
fi

if $HELP ; then
    echo "USAGE: convert-avi.sh <input> <output directory>"
    echo ""
    echo "OPTIONS:"
    echo "  -t <COLOR>, --transparency <COLOR>    Specify the transparency color (e.g., #00ff00)."
    echo "  -h, --help                            Show help."
    echo ""
    echo "Convert PsiWin AVI files to animated GIFs."
    echo ""
    exit
fi

INPUT_PATH=${POSITIONAL[0]}
OUTPUT_DIRECTORY=${POSITIONAL[1]}
BASENAME=$(basename "$INPUT_PATH" | cut -d. -f1 | tr '[:upper:]' '[:lower:]')
TEMPORARY_DIRECTORY=$(mktemp -d -t convert-XXXXXXXXXX)

ffmpeg -i "$INPUT_PATH" "$TEMPORARY_DIRECTORY/frame%04d.png"
convert -delay 0 -loop 0 -alpha set -dispose previous -transparent "$TRANSPARENCY" "$TEMPORARY_DIRECTORY/"*.png "$OUTPUT_DIRECTORY/$BASENAME.gif"
convert -scale 200% "$OUTPUT_DIRECTORY/$BASENAME.gif" "$OUTPUT_DIRECTORY/$BASENAME@2x.gif"
