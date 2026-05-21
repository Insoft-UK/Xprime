#!/bin/bash
DATE=$(date +"%Y%m%d")
DIR=$(dirname "$0")
cd "$DIR"
clear

DEST=../Xprime/Xprime/Resources/Developer/usr/bin

cp -p hpppl+/build/hpppl+ $DEST/hpppl+
cp -p hpppl+/add-ons/grob/build/grob $DEST/grob
cp -p hpppl+/add-ons/hpfont/build/hpfont $DEST/hpfont
cp -p hpnote/build/hpnote $DEST/hpnote

# Close the Terminal window
osascript -e 'tell application "Terminal" to close window 1' & exit
