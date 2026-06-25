NB. ============================================================
NB. examples/poly.ijs - Polynomial evaluation
NB. ============================================================
NB. Evaluates a polynomial p(x) = a + bx + cx^2 + dx^3 + ...
NB. at given points. Demonstrates array operations, broadcasting,
NB. and the inner-product-like form (coefs * powers) +/ .
NB.
NB. Run via `make run EXAMPLE=examples/poly.ijs`.

NB. --- Polynomial: p(x) = 1 + 2x + 3x^2 + 4x^3 ----------------
NB. Coefficients in ascending-power order: 1, 2, 3, 4.
NB. At x = 2: 1 + 2*2 + 3*4 + 4*8 = 1 + 4 + 12 + 32 = 49.
coefs =. 1 2 3 4
smoutput 'coefs = ' , ": coefs
NB. -> 1 2 3 4

NB. --- Single-point evaluation ------------------------
NB. We compute the polynomial value at x = 2 by hand.
NB. `x ^ i. # coefs` gives the powers [1, x, x^2, x^3] = [1,2,4,8].
NB. `coefs * powers` is element-wise product.
NB. `+/` reduces to a scalar.
NB. All of this fits TacitJ subset since `^`, `i.`, `*`, `+/`
NB. are all in the language.

NB. At x = 2:
NB.   powers = 2 ^ i.4 = 2 ^ 0 1 2 3 = 1 2 4 8
NB.   terms  = 1 2 3 4 * 1 2 4 8 = 1 4 12 32
NB.   value  = +/ terms = 49
smoutput 'p(2) = ' , (": +/ coefs * 2 ^ i. # coefs)
NB. -> 49

NB. --- Another point: x = 3 ----------------------------
NB. At x=3: 1 + 2*3 + 3*9 + 4*27 = 1 + 6 + 27 + 108 = 142.
smoutput 'p(3) = ' , (": +/ coefs * 3 ^ i. # coefs)
NB. -> 142

NB. --- Verification of values --------------------------
NB. p(0)=1, p(1)=10, p(2)=49, p(3)=142, p(4)=313, p(5)=586
NB. (verified by hand: 1+0+0+0=1, 1+2+3+4=10, ...)

NB. --- A composition ----------------------------------
NB. We can compose the whole evaluation as a tacit fork
NB. that takes a single argument x. The trick: we bind `coefs`
NB. by hand with `& coefs` and chain the rest.
NB.
NB. NB. The composition we want is:
NB.   poly = +/ @: (coefs&*) @: (^ i. # coefs)
NB.
NB. NB. The verb `^ i. # coefs` would need to take x and
NB. return x^i.0, x^i.1, ... — but `^` and `i.` are not
NB. NB. in the Stage 0 subset as easily combinable verbs.

NB. So we just evaluate directly at each x in a loop... but
NB. TacitJ subset has no loop constructs. So we have to
NB. duplicate the formula for each x we want to evaluate.
NB. That's a limitation of the subset, not a design flaw.

NB. --- Summary ---------------------------------------
smoutput ''
smoutput 'polynomial coefficients: 1 2 3 4  (constant, x, x^2, x^3)'
smoutput 'p(2) = 49'
smoutput 'p(3) = 142'