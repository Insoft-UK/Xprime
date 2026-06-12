#!/bin/bash
DIR=$(dirname "$0")
clear
cd "$DIR"



       
#-nobrowse
MOUNT_POINT=$(hdiutil attach "Xprime.dmg" | \
    awk '/\/Volumes\// {print $NF; exit}')

echo "$MOUNT_POINT"

VERSION=$(/usr/libexec/PlistBuddy \
        -c "Print :CFBundleShortVersionString" \
        "/Volumes/Xprime/Xprime.app/Contents/Info.plist"\
       )
       
BUILD=$(/usr/libexec/PlistBuddy \
        -c "Print :CFBundleVersion" \
        "/Volumes/Xprime/Xprime.app/Contents/Info.plist"\
       )

hdiutil detach "/Volumes/Xprime"

hdiutil convert "Xprime.dmg" -format UDZO -o "../Xprime_${VERSION}.dmg"


zip -j ../xprime_$BUILD.zip "../Xprime_${VERSION}.dmg"
rm "../Xprime_${VERSION}.dmg"
  
read -p "Press Enter to exit!"

# Close the Terminal window
osascript -e 'tell application "Terminal" to close window 1' & exit
