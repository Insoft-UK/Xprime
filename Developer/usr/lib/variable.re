`\bvar\b`i LOCAL
`\btrue\b`i 1
`\bfalse\b`i 0
`\bPYTHON +([a-z]\w*) *:?= *([a-z]\w*)\b`i LOCAL $1:="\""+STRING($2)+"\""
