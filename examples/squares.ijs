NB. ============================================================
NB. examples/squares.ijs - Sum of squares via 3-train
NB. ============================================================
NB. sumSquares = +/ @: *:        NB. (sum after square each) - monadic
NB. squareSum = *: @ +/         NB. (square the sum) - monadic
NB. meanSq    = (+/ % #) @ *:   NB. mean of squares - monadic
NB.
NB. The point: every operator here is a J primitive, and
NB. the composition is right-to-left. @: is "compose"
NB. (with rank preservation); @ is "atop" (also compose).
NB.
NB. A small program to test: sum of squares of 1..5 = 55.
NB. Stage 0 can run this end-to-end.

sumSquares =: +/ @: *:
sumSquares 1 2 3 4 5
