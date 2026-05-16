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

for i in $(find . -maxdepth 1 -iname "*.iconset")
do
    filename="${i%.*}"
    name="${filename##*/}"
    
    iconutil -c icns "$name.iconset"
    echo ${name}
done

