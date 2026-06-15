#!/bin/bash
DATE=$(date +"%Y%m%d")
DIR=$(dirname "$0")
cd "$DIR"
clear

DEST=../Xprime/Xprime/Resources/Developer/usr/bin

cp hpppl+/build/hpppl+ $DEST/
cp hpppl+/add-ons/grob/build/grob $DEST/
cp hpppl+/add-ons/hpfont/build/hpfont $DEST/
cp hpnote/build/hpnote $DEST/

# Close the Terminal window
#osascript -e 'tell application "Terminal" to close window 1' & exit
