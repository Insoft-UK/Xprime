#!/bin/bash
DIR=$(dirname "$0")
ARCH=$(arch)
cd "$DIR"
clear

make

read -p "Press Enter to exit!"

# Close the Terminal window
osascript -e 'tell application "Terminal" to close window 1' & exit
