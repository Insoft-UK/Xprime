`:?= *\( *((?:\w|:{2})+) *\)` := MAKELIST(0, X, 1, $1)
`__SCREEN\b` G0
>`\bauto\b`i v__COUNTER__
=`^ *\bauto *: *([a-z]\w*)`i g__COUNTER__:$1
`\b([a-z_]\w*) *\: *([a-z]\w*(?:::[a-z]\w*)*)`i alias $2:=$1;$1
