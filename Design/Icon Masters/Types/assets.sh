#!/bin/bash
DIR=$(dirname "$0")
printf "\e[48;5;160m"
clear
ANSI_ART=$(cat <<EOF
\e[48;5;160m                            \e[0;m
\e[48;5;160m            \e[0;107m            \e[48;5;160m    \e[0;m
\e[48;5;160m          \e[0;107m            \e[48;5;160m      \e[0;m
\e[48;5;160m        \e[0;107m            \e[48;5;160m        \e[0;m
\e[48;5;160m      \e[0;107m            \e[48;5;160m  \e[0;107m  \e[48;5;160m      \e[0;m
\e[48;5;160m    \e[0;107m            \e[48;5;160m  \e[0;107m      \e[48;5;160m    \e[0;m
\e[48;5;160m  \e[0;107m            \e[48;5;160m  \e[0;107m          \e[48;5;160m  \e[0;m
\e[48;5;160m  \e[0;107m          \e[48;5;160m    \e[0;107m            \e[0;m
\e[48;5;160m  \e[0;107m            \e[48;5;160m    \e[0;107m          \e[0;m
\e[48;5;160m    \e[0;107m          \e[48;5;160m  \e[0;107m            \e[0;m
\e[48;5;160m      \e[0;107m      \e[48;5;160m  \e[0;107m            \e[48;5;160m  \e[0;m
\e[48;5;160m        \e[0;107m  \e[48;5;160m  \e[0;107m            \e[48;5;160m    \e[0;m
\e[48;5;160m          \e[0;107m            \e[48;5;160m      \e[0;m
\e[48;5;160m        \e[0;107m            \e[48;5;160m        \e[0;m
\e[48;5;160m      \e[0;107m            \e[48;5;160m          \e[0;m
\e[48;5;160m
EOF
)

printf "$ANSI_ART\n"
cd "$DIR"

for i in $(find . -maxdepth 1 -iname "*.png")
do
    filename="${i%.*}"
    name="${filename##*/}"
    
    mkdir -p "$name.iconset"
    rm -rf "$name.iconset/*"

    sips -z 16 16     "$name.png" --out "$name.iconset/icon_16x16.png" &>/dev/null
    sips -z 32 32     "$name.png" --out "$name.iconset/icon_16x16@2x.png" &>/dev/null
    sips -z 32 32     "$name.png" --out "$name.iconset/icon_32x32.png" &>/dev/null
    sips -z 64 64     "$name.png" --out "$name.iconset/icon_32x32@2x.png" &>/dev/null
    sips -z 128 128   "$name.png" --out "$name.iconset/icon_128x128.png" &>/dev/null
    sips -z 256 256   "$name.png" --out "$name.iconset/icon_128x128@2x.png" &>/dev/null
    sips -z 256 256   "$name.png" --out "$name.iconset/icon_256x256.png" &>/dev/null
    sips -z 512 512   "$name.png" --out "$name.iconset/icon_256x256@2x.png" &>/dev/null
    sips -z 512 512   "$name.png" --out "$name.iconset/icon_512x512.png" &>/dev/null
    sips -z 1024 1024 "$name.png" --out "$name.iconset/icon_512x512@2x.png" &>/dev/null
    
    echo ${name}
done


