NB. ============================================================
NB. examples/rank.ijs - Demonstrating rank-preserving composition
NB. ============================================================
NB. Stage 0 subset supports @: (atop with rank), &: (bond with
NB. rank), and ^: (power with rank).
NB.
NB. @: composes two verbs while preserving the rank of the right
NB. operand. So `f @: g y` has the same rank as `g y`.
NB.
NB. Common idioms:
NB.
NB.   sumSquares y = +/ @: *: y    NB. sum of (each element squared)
NB.   bounded y    = 0 <. @: <. y  NB. min of each element with 0
NB.   doubled y    = 2 *  @: ] y   NB. scale each element by 2
NB.
NB. NB: `<.` and `>.` are floor and ceil (not yet in Stage 0's
NB. PRIM_VERB). So we use a Stage 0 idiom: `+/ @: *: y` (sum of
NB. squares).

NB. --- Demo 1: sum of squares via @: composition ---
NB. sumSquares y = sum of (each element squared).
NB. Without @:, we'd write `+/ *: y`. With @:, it's a 2-step
NB. composition that makes the intent explicit.
sumSquares =: +/ @: *:
smoutput sumSquares 1 2 3 4 5
NB. -> 55

NB. --- Demo 2: difference between @ and @: ---
NB. `f @ g y` has the rank of `f y` (atop).
NB. `f @: g y` has the rank of `g y` (atop with rank).
NB.
NB. For 1D lists they're the same, but for nested arrays the
NB. difference matters. In Stage 0, both compose the same way.

NB. --- Demo 3: power with rank ^: ---
NB. ^: is "power conjunction with rank". `f ^: n y` applies f
NB. n times. Stage 0's runner doesn't execute ^: directly, but
NB. the lexer/parser/unparser all handle it correctly.
NB.
NB. (Commented out — runner limitation.)
NB. twice =: ^: 2
NB. twice +: NB. applies +: twice: (1 + 1) + 1 = 3