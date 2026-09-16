#!/bin/bash
DIR=$(dirname "$0")
cd "$DIR"
clear

source ~/GitHub/notarization.sh
# Your AppleID, TeamID, Password and Name (An app-specific password NOT! AppleID password)
if [ -z "$APPLE_ID" ]; then
    source ./notarization.sh
fi

xcrun notarytool store-credentials "mycreds" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$PASSWORD"
