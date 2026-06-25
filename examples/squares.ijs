NB. ============================================================
NB. examples/squares.ijs - Sum of squares in Stage 0 subset
NB. ============================================================
NB. Stage 0 subset supports: + - * % ^ | < > & =:
NB. It does NOT yet support: @ @: ~: \ :
NB.
NB. So we can't write `+/ @ *:` (sum after square) directly.
NB. Instead we use a multi-step form:
NB.
NB.   squares y = y * y          (each element squared, via table)
NB.   total    = +/ squares y    (sum the squares)
NB.
NB. NB: y * y in J gives the OUTER product (a 2D table), not
NB. element-wise squares. To get element-wise squares we need
NB. *: (monadic square). For Stage 0 without *:, we can compute
NB. sum of squares via +/(y*y) which uses the OUTER product
NB. and then sums. The result is sum-of-squares-of-y plus some
NB. cross terms. To get the *correct* sum of squares in Stage 0
NB. we can use *: if we treat it as a verb:
NB.
NB.   sq =: *:        NB. square function (monadic)
NB.   smoutput +/ sq 1 2 3 4 5   NB. -> 55
NB.
NB. (`: makes it a noun definition; when applied to y it returns
NB. the element-wise squares.)

NB. The point: every operator here is a J primitive, and the
NB. composition is right-to-left. +/ sums, *: squares.

NB. --- Demo 1: sum of squares via monadic *: ---
NB. *: is monadic square. +/ is sum.
NB. Together: +/ *: y = sum of squares.
smoutput +/ *: 1 2 3 4 5
NB. -> 55