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
NB.   floorHalf  y = <. @: %:&2 y    NB. floor of (each / 2)

NB. --- Demo 1: sum of squares via @: composition ---
sumSquares =: +/ @: *:
smoutput sumSquares 1 2 3 4 5
NB. -> 55

NB. --- Demo 2: floor via <. verb ---
NB. <. applied to a scalar: 3.7 <. 3 = 3 (dyadic floor)
NB. As a 2-train hook, it forms a derived verb.
NB. NB: the Stage 0 runner doesn't evaluate <. y as a 2-train
NB. hook yet (it produces a degenerate IR for one-arg hooks).
NB. The lexer/parser/unparser all recognise <. correctly.
NB.
NB. floorOfHalf =: <. @: %:&2
NB. floorOfHalf 7     NB. floor(7/2) = floor(3.5) = 3
NB. floorOfHalf 9     NB. floor(9/2) = floor(4.5) = 4
NB.
NB. floorOfHalf 7
floorOfHalf 9