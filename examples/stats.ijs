NB. ============================================================
NB. examples/stats.ijs - Statistical functions
NB. ============================================================
NB. Demonstrates TacitJ's expressiveness with a small statistics
NB. library: mean, sum-of-squares, sum-of-deviations, range, and
NB. zero-mean / unit-variance normalizer. All defined as pure
NB. tacit compositions where possible.
NB.
NB. Run via `make run EXAMPLE=examples/stats.ijs`.

NB. --- Sample dataset -------------------------------
NB. Twelve measurements.
xs =. 1 2 3 4 5 6 7 8 9 10 11 12
smoutput 'data: ' , ": xs

NB. --- Mean -----------------------------------------
NB. Sum / count. The classic mean fork.
mean =. +/ % #
smoutput 'mean = ' , (": mean xs)
NB. -> 6.5

NB. --- Sum of squares ------------------------------
NB. Sum of element-wise squares. Pure-tacit.
sumsq =. +/ @: *:
smoutput 'sumsq = ' , (": sumsq xs)
NB. -> 650

NB. --- Sum of deviations ---------------------------
NB. Sum of element-wise deviations from the mean.
NB. Always 0 by construction (defining property of mean).
NB. Form:  +/  @:  -  @:  mean  ;  but `- mean` is a hook
NB. that the parser doesn't form without explicit grouping.
NB. We rewrite it as `+/ % # @: - 0 0 0 0 0 0 0 0 0 0 0 0`
NB. which is convoluted; instead use +/ @: | @: - mean.
NB. That gives sum of |x - mean(x)|.
absdev =. +/ @: | @: - mean
smoutput 'sum |x-mean(x)| = ' , (": absdev xs)
NB. -> 33

NB. --- Range ---------------------------------------
NB. min and max of a list, returned as a 2-element vector.
rng =. (<./ , >./)
smoutput 'range = ' , ": rng xs
NB. -> 1 12

NB. --- Element-wise deviations ----------------------
NB. Just `xs - mean xs`. We demonstrate the pattern by
NB. applying it to xs directly.
smoutput 'deviations:'
smoutput ": xs - mean xs
NB. -> _5.5 _4.5 _3.5 _2.5 _1.5 _0.5 0.5 1.5 2.5 3.5 4.5 5.5

NB. --- Sum of squares (alternative) ---------------
NB. Sum of squared deviations. Pure-tacit: `+/ @: *: @: - mean`
NB. The hook `- mean` parses as `(negate mean)` so this only
NB. works if `-` is forced into the right context. We rewrite
NB. it explicitly using a 2-stage compose: first subtract,
NB. then square, then sum.
NB. (Stage 0 subset doesn't include `*:` applied to `- mean`,
NB. so we use the workaround below.)
ssqdev =. +/ @: *: @: (- mean)
smoutput 'sum (x-mean(x))^2 = ' , (": ssqdev xs)
NB. -> 143

NB. --- Variance from sum of squared deviations -----
NB. We define variance = ssqdev / count. The composition
NB. `ssqdev % #` is a fork: (ssqdev x) % (# x). That's
NB. exactly variance.
var =. ssqdev % #
smoutput 'var = ' , (": var xs)
NB. -> 11.9167

NB. --- Standard deviation --------------------------
NB. Square root of variance. Pure-tacit: %: @: var.
stddev =. %: @: var
smoutput 'std = ' , (": stddev xs)
NB. -> 3.45205

NB. --- Summary -------------------------------------
NB. Apply all functions to xs and dump the results.
smoutput ''
smoutput 'summary:'
smoutput '  n         = ' , (": # xs)
smoutput '  sum       = ' , (": +/ xs)
smoutput '  sumsq     = ' , (": sumsq xs)
smoutput '  ssqdev    = ' , (": ssqdev xs)
smoutput '  mean      = ' , (": mean xs)
smoutput '  var       = ' , (": var xs)
smoutput '  std       = ' , (": stddev xs)
smoutput '  range     = ' , ": rng xs