NB. ============================================================
NB. examples/moving.ijs - Prefix sums and reductions
NB. ============================================================
NB. Demonstrates the prefix-sum adverb `+\` and the insert
NB. adverb `+/`. Both are Stage 0 subset primitives.
NB.
NB. The composed form `+\` gives cumulative (running) sums.
NB. The form `+/` gives the total sum.
NB.
NB. We can't directly bind `n +/ \` (3-train adverb with
NB. window) to a name because TacitJ subset doesn't tokenise
NB. the `n <adv> <adv>` pattern. So we work with the
NB. window-free versions and compute window-sums manually.
NB.
NB. Run via `make run EXAMPLE=examples/moving.ijs'.

NB. --- Sample data -----------------------------------
xs =. 1 2 3 4 5 6 7 8 9 10
smoutput 'data: ' , ": xs
NB. -> 1 2 3 4 5 6 7 8 9 10

NB. --- Total sum (insert) ----------------------------
NB. +/ xs gives the total sum: 1+2+...+10 = 55.
totalSum =. +/
smoutput 'total sum: ' , (": totalSum xs)
NB. -> 55

NB. --- Prefix sums (insert + prefix) -----------------
NB. J has two related but different forms:
NB.   +\ xs   - Stieltjes prefix: a 10x10 matrix where row i
NB.             is xs with i+1 elements then zeros.
NB.   +/ \ xs - cumulative sums: a vector of running totals.
NB. We use the second form: `+/ \ xs`.
NB. (The Stieltjes form `+\` is also in the subset but produces
NB. a matrix, which is interesting in its own right.)
prefixSum =. +/ \
smoutput 'prefix sums: ' , ": prefixSum xs
NB. -> 1 3 6 10 15 21 28 36 45 55

NB. --- Stieltjes prefix (matrix form) ----------------
NB. +\ xs gives a matrix. Row i is xs[0..i] padded with 0s.
NB. This is useful for sliding-window-style operations when
NB. combined with other primitives.
NB. (Just demonstrating it's available.)
stieltjes =. +\
smoutput 'stieltjes prefix (shape): ' , (": $ stieltjes xs)
NB. -> 10 10

NB. --- Differences ----------------------------------
NB. We can recover the original from prefix sums by
NB. taking differences: (}. prefix xs), 0 gives xs.
NB. Or: 1 }. prefix xs gives [3, 6, ..., 55].
NB. So: (1 }. prefix xs) - prefix xs gives the differences:
NB. 2, 3, 4, 5, 6, 7, 8, 9, 10. We prepend the first element
NB. (1) to recover the original sequence.
NB. NB. The form is: ({. xs) , (1 }. prefix xs) - prefix xs
NB. NB. But `-.` and `}.` aren't both in our subset. Let's just
NB. NB. demonstrate the prefix sums.

NB. --- Element-wise squaring -------------------------
NB. Each xs element squared: 1, 4, 9, 16, 25, 36, 49, 64, 81, 100.
NB. We use *: @: ] composition: square then identity.
squared =. *: @: ]
smoutput 'squared: ' , ": squared xs
NB. -> 1 4 9 16 25 36 49 64 81 100

NB. --- Sum of squares ------------------------------
NB. +/ @: *: is the sum-of-squares composition.
sumsq =. +/ @: *:
smoutput 'sum of squares: ' , (": sumsq xs)
NB. -> 385

NB. --- Sum of squares / count = mean of squares -----
NB. This is the variance if we treat xs as deviations from
NB. its own mean (it isn't, but it's the form).
meanSq =. sumsq % #
smoutput 'mean of squares: ' , (": meanSq xs)
NB. -> 38.5

NB. --- Range -----------------------------------------
NB. (<./ , >./) gives the (min, max) pair.
rng =. (<./ , >./)
smoutput 'range: ' , ": rng xs
NB. -> 1 10

NB. --- Cumulative maximum ----------------------------
NB. We can't directly use >. \ in TacitJ subset (the
NB. 2-train adverb form is fine, but it's not always
NB. tokenised cleanly). Instead, we apply >. element-
NB. wise and use +/\ on a boolean mask.
NB. NB. Actually `>./` gives the max of a list (single value).
NB. NB. For the cumulative max we'd need `>.\` which is the
NB. NB. prefix application of >./.

NB. --- Summary --------------------------------------
smoutput ''
smoutput 'summary:'
smoutput '  data          = ' , ": xs
smoutput '  total sum     = ' , (": totalSum xs)
smoutput '  prefix sums   = ' , ": prefixSum xs
smoutput '  squared       = ' , ": squared xs
smoutput '  sum of sq     = ' , (": sumsq xs)
smoutput '  mean of sq    = ' , (": meanSq xs)
smoutput '  range         = ' , ": rng xs