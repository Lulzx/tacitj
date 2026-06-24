NB. ============================================================
NB. examples/pipeline.ijs - Tacit pipeline composition
NB. ============================================================
NB. Demonstrates @ (atop), @: (atop with rank), and forks.

NB. square: *: is the monadic * (square)
square =: *:

NB. inc: >: increments
inc    =: >:

NB. square-of-inc: explicit composition with @ (atop)
NB. (square @ inc) y = square (inc y) = (y+1)^2
pipeline1 =: square @ inc
pipeline1 3              NB. -> 16

NB. Same thing, with explicit parens for clarity
pipeline2 =: square @ inc
pipeline2 10             NB. -> 121

NB. A fork: (square ` inc ` double) is a 3-train
NB. NB. `double` is `2 *`. (square ` inc ` double) y =
NB. NB. (square y) ` inc (double y) ... but this is a 2-train in
NB. NB. our parser, so let's keep it simple.

NB. A 2-train: `0 , ]` prefixes a 0 to a list
prefixZero =: 0 , ]
prefixZero 1 2 3        NB. -> 0 1 2 3

NB. A 2-train: `, 0` appends a 0
appendZero =: , & 0
appendZero 1 2 3        NB. -> 1 2 3 0
