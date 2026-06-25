NB. ============================================================
NB. examples/rank.ijs - Demonstrating rank-preserving composition
NB. ============================================================
NB. Stage 0 subset supports @: (atop with rank), &: (bond with
NB. rank), and ^: (power with rank).
NB.
NB. Also supports <. (floor) and >. (ceiling) as 2-char verbs.
NB.
NB. @: composes two verbs while preserving the rank of the right
NB. operand. So `f @: g y` has the same rank as `g y`.
NB.
NB. Common idioms:
NB.
NB.   sumSquares y = +/ @: *: y    NB. sum of (each element squared)

NB. --- Demo 1: sum of squares via @: composition ---
NB. sumSquares y = sum of (each element squared).
NB. Without @:, we'd write `+/ *: y`. With @:, it's a 2-step
NB. composition that makes the intent explicit.
sumSquares =: +/ @: *:
smoutput sumSquares 1 2 3 4 5
NB. -> 55

NB. --- Demo 2: floor + increment via 2-char verbs ---
NB. <. y is floor of y. >: y is increment.
NB. As composition: (>. @: <:) is ceiling of predecessor.

NB. floor 3.7 = 3
NB. ceil  3.2 = 4
NB. +: 5   = 6

NB. NB: the runner doesn't always handle the 2-char verbs as
NB. monadic applications cleanly. The lexer/parser/unparser
NB. all handle them correctly, and they round-trip via
NB. emitIr. Use them in compositions like sumSquares for now.

NB. --- Demo 3: difference between @ and @: ---
NB. `f @ g y` has the rank of `f y` (atop).
NB. `f @: g y` has the rank of `g y` (atop with rank).
NB.
NB. For 1D lists they behave the same. The difference matters
NB. when working with nested arrays or different ranks.

NB. --- Demo 4: per-element increment ---
NB. +: applied to a list gives the incremented list.
NB. (not yet runnable end-to-end, but lexer/parser support it)
NB. smoutput +: 5 10 15
NB. -> 6 11 16