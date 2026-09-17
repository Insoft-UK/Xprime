#!/bin/bash
DIR=$(dirname "$0")
cd "$DIR"

clear


source ./notarization.sh


PROFILE="Apple-Notary"

echo "Checking notarization credentials..."

if xcrun notarytool history --keychain-profile "$PROFILE" >/dev/null 2>&1; then
    echo "✓ $PROFILE already exists."
    echo "Nothing to do."
    exit 0
fi

echo "$PROFILE not found."
echo "Creating $PROFILE..."

xcrun notarytool store-credentials "$PROFILE" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$PASSWORD"

if [ $? -eq 0 ]; then
    echo "✓ $PROFILE created successfully."
else
    echo "✗ Failed to create $PROFILE."
    exit 1
fi
