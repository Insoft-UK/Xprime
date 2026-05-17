#!/bin/bash
DIR=$(dirname "$0")
clear
cd "$DIR"

NAME=$(basename $(PWD))

iconutil -c icns $NAME.iconset
