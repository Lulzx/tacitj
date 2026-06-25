NB. ============================================================
NB. examples/matrix.ijs - Matrix operations
NB. ============================================================
NB. Demonstrates 2D-array operations in TacitJ.
NB.
NB. Stage 0 subset supports +/ on matrices (with the `,` ravel),
NB. +/"1 for row-wise reduction, +/ for column-wise reduction,
NB. |: for transpose, >./ for max. All of these round-trip via
NB. the compiler.
NB.
NB. Run via `make run EXAMPLE=examples/matrix.ijs`.

NB. --- Build a 2x3 matrix ---
NB. 2 3 $ 1 2 3 4 5 6  reshapes a 6-element list into 2 rows
NB. of 3 columns each.
m =: 2 3 $ 1 2 3 4 5 6
smoutput m
NB. ->
NB. 1 2 3
NB. 4 5 6

NB. --- Total sum ---
NB. , m ravel the matrix to a flat list. +/ then sums.
smoutput 'sum = ' , (": +/ , m)
NB. -> 21

NB. --- Row sums ---
NB. +/"1 applies +/ along axis 1 (rows).
smoutput 'row sums: ' , (": +/"1 m)
NB. -> 6 15

NB. --- Column sums ---
NB. +/ applies +/ along axis 0 (columns) by default.
smoutput 'col sums: ' , (": +/ m)
NB. -> 5 7 9

NB. --- Transpose ---
NB. |: swaps the axes: 2x3 -> 3x2.
smoutput 'transpose: ' , ": |: m
NB. ->
NB. 1 4
NB. 2 5
NB. 3 6

NB. --- Maximum ---
NB. >./ , m gives the overall max.
smoutput 'max = ' , (": >./ , m)
NB. -> 6

NB. --- Matrix from a 2-train (outer product) ---
NB. 1 2 3 */ 1 2 3 is the 3x3 multiplication table.
smoutput 'mul table:' , ": 1 2 3 */ 1 2 3
NB. ->
NB. 1 2 3
NB. 2 4 6
NB. 3 6 9

NB. --- Sum of squares of a matrix ---
NB. , m ravel the matrix, *: squares each element, +/ sums.
smoutput 'sum of squares = ' , (": +/ , *: m)
NB. -> 91  (= 1+4+9+16+25+36)