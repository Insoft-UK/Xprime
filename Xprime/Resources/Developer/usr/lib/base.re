`:?= *\( *((?:\w|:{2})+) *\)` := MAKELIST(0, X, 1, $1)
`__SCREEN\b` G0
>`\bauto\b`i v__COUNTER__
=`^ *\bauto *: *([a-z]\w*)` g__COUNTER__:$1
`\b([a-zA-Z_]\w*) *\: *([a-zA-Z]\w*(?:::[a-zA-Z]\w*)*)` alias $2:=$1;$1
