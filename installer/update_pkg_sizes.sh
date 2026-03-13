#!/bin/bash

# Exit immediately if a command fails
set -e

# Function to calculate KB size safely
calculate_size() {
    local path="$1"
    if [ -d "$path" ]; then
        du -sk "$path" 2>/dev/null | awk '{print $1}'
    elif [ -f "$path" ]; then
        du -sk "$path" 2>/dev/null | awk '{print $1}'
    else
        echo ""
    fi
}

XPRIME_SIZE=$(calculate_size "xprime.pkg")
HP_SIZE=$(calculate_size "hp.pkg")
PPLPLUS_SIZE=$(calculate_size "pplplus.pkg")
NOTE_SIZE=$(calculate_size "note.pkg")
GROB_SIZE=$(calculate_size "grob.pkg")
FONT_SIZE=$(calculate_size "font.pkg")


# ---- Update distribution.dist ----
DIST_FILE="distribution.dist"

if [ ! -f "$DIST_FILE" ]; then
    echo "❌ Error: $DIST_FILE not found!"
    exit 1
fi

# Update installKBytes for both packages
sed -i '' "s|\(<pkg-ref id=\"uk\.insoft\.xprime\"[^\>]*installKBytes=\)\"[0-9]*\"|\1\"$XPRIME_SIZE\"|" "$DIST_FILE"
sed -i '' "s|\(<pkg-ref id=\"uk\.insoft\.pplplus\"[^\>]*installKBytes=\)\"[0-9]*\"|\1\"$PPLPLUS_SIZE\"|" "$DIST_FILE"
sed -i '' "s|\(<pkg-ref id=\"uk\.insoft\.grob\"[^\>]*installKBytes=\)\"[0-9]*\"|\1\"$GROB_SIZE\"|" "$DIST_FILE"
sed -i '' "s|\(<pkg-ref id=\"uk\.insoft\.font\"[^\>]*installKBytes=\)\"[0-9]*\"|\1\"$FONT_SIZE\"|" "$DIST_FILE"
sed -i '' "s|\(<pkg-ref id=\"uk\.insoft\.note\"[^\>]*installKBytes=\)\"[0-9]*\"|\1\"$NOTE_SIZE\"|" "$DIST_FILE"
sed -i '' "s|\(<pkg-ref id=\"uk\.insoft\.hp\"[^\>]*installKBytes=\)\"[0-9]*\"|\1\"$HP_SIZE\"|" "$DIST_FILE"

echo "✅ Updated $DIST_FILE:"
echo "   - Xprime installKBytes=\"$XPRIME_SIZE\""
echo "   - PPL Plus installKBytes=\"$PPLPLUS_SIZE\""
echo "   - GROB installKBytes=\"$GROB_SIZE\""
echo "   - Font installKBytes=\"$FONT_SIZE\""
echo "   - NoteText Tool installKBytes=\"$NOTE_SIZE\""
echo "   - HP   installKBytes=\"$HP_SIZE\""
