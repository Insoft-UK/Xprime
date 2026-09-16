#!/bin/bash
DIR=$(dirname "$0")
cd "$DIR"
clear

set -euo pipefail

# ============================================================
# XPrime macOS Developer ID release
# Signs -> verifies -> notarizes -> staples -> creates ZIP
# ============================================================

# ---------- CONFIGURATION ----------


#ISSUER_ID="69a6de6f-48d9-47e3-e053-5b8c7c11a4d1"
#KEY_ID="PY2Z38PG7Z"

source ~/GitHub/notarization.sh
# Your AppleID, TeamID, Password and Name (An app-specific password NOT! AppleID password)
if [ -z "$APPLE_ID" ]; then
    source ./notarization.sh
fi

APP="build/Xprime.app"

IDENTITY="Developer ID Application: $YOUR_NAME ($TEAM_ID)"

NOTARY_PROFILE="mycreds"

# Output directory
DIST="dist"

# ---------- CHECKS ----------

if [ ! -d "$APP" ]; then
    echo "ERROR: App not found:"
    echo "       $APP"
    exit 1
fi

echo
echo "========================================"
echo " XPrime Release"
echo "========================================"
echo
echo "App:      $APP"
echo "Identity: $IDENTITY"
echo

# Make sure the signing identity exists
if ! security find-identity -v -p codesigning | grep -Fq "$IDENTITY"; then
    echo "ERROR: Developer ID signing identity not found:"
    echo "$IDENTITY"
    exit 1
fi

# Clean distribution directory
rm -rf "$DIST"
mkdir -p "$DIST"

# ---------- EMBEDDED EXECUTABLES ----------

BIN="$APP/Contents/Resources/Developer/usr/bin"

echo
echo "Signing embedded executables..."

for executable in \
    grob \
    hpfont \
    hpnote \
    "hpppl+"
do
    PATH_TO_BINARY="$BIN/$executable"

    if [ ! -f "$PATH_TO_BINARY" ]; then
        echo "ERROR: Missing executable:"
        echo "$PATH_TO_BINARY"
        exit 1
    fi

    echo "  Signing $executable"

    codesign \
        --force \
        --options runtime \
        --timestamp \
        --sign "$IDENTITY" \
        "$PATH_TO_BINARY"
done

# ---------- SIGN MAIN APPLICATION ----------

echo
echo "Signing Xprime.app..."

codesign \
    --force \
    --options runtime \
    --timestamp \
    --sign "$IDENTITY" \
    "$APP"

# ---------- VERIFY INDIVIDUAL EXECUTABLES ----------

echo
echo "Verifying embedded executables..."

for executable in \
    grob \
    hpfont \
    hpnote \
    "hpppl+"
do
    PATH_TO_BINARY="$BIN/$executable"

    echo "  Checking $executable"

    codesign \
        --verify \
        --strict \
        --verbose=2 \
        "$PATH_TO_BINARY"
done

# ---------- VERIFY APP ----------

echo
echo "Verifying Xprime.app..."

codesign \
    --verify \
    --deep \
    --strict \
    --verbose=2 \
    "$APP"

# ---------- DISPLAY SIGNATURE ----------

echo
echo "Signature information:"
echo

codesign \
    --display \
    --verbose=4 \
    "$APP"

# ---------- CREATE ZIP FOR NOTARIZATION ----------

ZIP="$DIST/XPrime-notarize.zip"

echo
echo "Creating notarization ZIP..."

ditto \
    -c \
    -k \
    --keepParent \
    "$APP" \
    "$ZIP"

# ---------- NOTARIZE ----------

echo
echo "Submitting to Apple notarization service..."
echo "(This may take a few minutes.)"
echo

xcrun notarytool submit \
    "$ZIP" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

# ---------- STAPLE ----------

echo
echo "Stapling notarization ticket to Xprime.app..."

xcrun stapler staple \
    "$APP"

# ---------- VERIFY STAPLE ----------

echo
echo "Verifying notarization ticket..."

xcrun stapler validate \
    "$APP"

# ---------- GATEKEEPER CHECK ----------

echo
echo "Checking Gatekeeper assessment..."

spctl \
    --assess \
    --type execute \
    --verbose=4 \
    "$APP"

# ---------- CREATE FINAL DISTRIBUTION ZIP ----------

FINAL="$DIST/Xprime.zip"

echo
echo "Creating final distribution ZIP..."

rm -f "$FINAL"

ditto \
    -c \
    -k \
    --keepParent \
    "$APP" \
    "$FINAL"

# ---------- FINAL SHA-256 ----------

echo
echo "SHA-256:"
shasum -a 256 "$FINAL"

# ---------- DONE ----------

echo
echo "========================================"
echo " Xprime notarization complete"
echo "========================================"
echo
echo "Final distribution:"
echo "  $FINAL"
echo
echo "The app has been:"
echo "  ✓ Developer ID signed"
echo "  ✓ Hardened Runtime enabled"
echo "  ✓ Notarized by Apple"
echo "  ✓ Ticket stapled"
echo "  ✓ Gatekeeper checked"
echo
