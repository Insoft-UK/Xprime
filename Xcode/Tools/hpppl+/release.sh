#!/bin/bash
DIR=$(dirname "$0")
cd "$DIR"

clear

set -euo pipefail

TOOL_NAME="hpppl+"
HTDOCS="/Applications/MAMP/htdocs"
DATE=$(date +%Y%m%d)


echo
echo "Creating distribution ZIP..."

ditto \
    -c \
    -k \
    --keepParent \
    "build/arm64/${TOOL_NAME}" \
    "${HTDOCS}/downloads/macos/hppplplus-macos_arm64-${DATE}.zip"
    
    
ditto \
    -c \
    -k \
    --keepParent \
    "build/x86_64/${TOOL_NAME}" \
    "${HTDOCS}/downloads/macos/hppplplus-macos_x86_64-${DATE}.zip"
    
ditto \
    -c \
    -k \
    --keepParent \
    "build/win_x86_64/${TOOL_NAME}.exe" \
    "${HTDOCS}/downloads/pc/hppplplus-win_x86_64-${DATE}.zip"
    
ditto \
    -c \
    -k \
    --keepParent \
    "build/linux_x86_64/${TOOL_NAME}" \
    "${HTDOCS}/downloads/linux/hppplplus-linux_x86_64-${DATE}.zip"
