
#!/bin/bash

set -euo pipefail

# Change to the project directory.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

clear

# Configuration.
TOOL_NAME="$(basename "$PWD")"
HTDOCS="/Applications/MAMP/htdocs"

# Build configurations: source | destination | platform.
BUILDS=(
    "build/arm64/${TOOL_NAME}|${HTDOCS}/downloads/macos|macos_arm64"
    "build/x86_64/${TOOL_NAME}|${HTDOCS}/downloads/macos|macos_x86_64"
    "build/win_x86_64/${TOOL_NAME}.exe|${HTDOCS}/downloads/pc|win_x86_64"
    "build/linux_x86_64/${TOOL_NAME}|${HTDOCS}/downloads/linux|linux_x86_64"
)

echo
echo "Creating distribution ZIPs for ${TOOL_NAME}..."
echo

for BUILD in "${BUILDS[@]}"; do

    IFS='|' read -r SOURCE DESTINATION PLATFORM <<< "$BUILD"

    # Check that the build and executable exist.
    if [[ ! -e "$SOURCE" ]]; then
        echo "Error: Build not found: ${SOURCE}" >&2
        exit 1
    fi
    
    # Use the executable's modification date.
    if [[ -d "$SOURCE" ]]; then
        EXECUTABLE="${SOURCE}/Contents/MacOS/${TOOL_NAME}"
    else
        EXECUTABLE="$SOURCE"
    fi

    if [[ ! -f "$EXECUTABLE" ]]; then
        echo "Error: Executable not found: ${EXECUTABLE}" >&2
        exit 1
    fi

    DATE="$(date -r "$EXECUTABLE" +%Y%m%d)"

    FILENAME="${TOOL_NAME}-${PLATFORM}-${DATE}.zip"

    # Create destination directory if necessary.
    mkdir -p "$DESTINATION"

    echo "Creating ${FILENAME}..."

    ditto \
        -c \
        -k \
        --keepParent \
        "$SOURCE" \
        "${DESTINATION}/${FILENAME}"

    echo "Created: ${DESTINATION}/${FILENAME}"
    echo

done

echo "Distribution ZIPs created successfully."
