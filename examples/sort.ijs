NB. ============================================================
NB. examples/sort.ijs - Sorting and deduplication
NB. ============================================================
NB. Demonstrates J's array sorting primitives in the TacitJ
NB. subset:
NB.   /:~ y   ascending sort (sort up)
NB.   \:~ y   descending sort (sort down)
NB.   /: y    grade up (indices that would sort)
NB.   \: y    grade down (indices for reverse sort)
NB.   ~. y    nub (unique elements)
NB.   ~: y    not-equal (boolean mask, true where y[i] differs
NB.            from y[i-1]; used for run-length encoding)
NB.
NB. Run via `make run EXAMPLE=examples/sort.ijs`.

NB. --- Sample data ----------------------------------
ys =. 5 2 8 1 9 3 2 7 1 4 5 8
smoutput 'data: ' , ": ys
NB. -> 5 2 8 1 9 3 2 7 1 4 5 8

NB. --- Ascending sort -------------------------------
NB. /:~ gives the data in ascending order. (Sort up.)
NB. The /:~ is a 2-token form: adverb / applied to ~.
NB. TacitJ subset handles this.
asc =. /:~
smoutput 'sorted (asc): ' , ": asc ys
NB. -> 1 1 2 2 3 4 5 5 7 8 8 9

NB. --- Descending sort ------------------------------
NB. \:~ gives the data in descending order. (Sort down.)
desc =. \:~
smoutput 'sorted (desc): ' , ": desc ys
NB. -> 9 8 8 7 5 5 4 3 2 2 1 1

NB. --- Grade up -------------------------------------
NB. /: y gives the indices that would sort y ascending.
NB. y /: /: y is the same as /:~ y. This is useful for
NB. indirect sorting.
idx =. /: ys
smoutput 'grade up: ' , ": idx
NB. -> 3 8 1 6 5 9 0 10 7 2 11 4
NB.    (indices: 3rd elt first, 8th next, etc.)
smoutput 'ys /: idx = ' , ": ys /: idx
NB. -> 1 1 2 2 3 4 5 5 7 8 8 9  (same as asc ys)

NB. --- Unique elements (nub) ------------------------
NB. ~. y returns the unique elements of y in the order
NB. they first appear.
uniq =. ~.
smoutput 'unique: ' , ": uniq ys
NB. -> 5 2 8 1 9 3 7 4
NB.    (5 first, then 2, 8, 1, 9, 3, 7, 4 — duplicates removed)

NB. --- Count of each element -------------------------
NB. To count occurrences of each unique element, we need
NB. an outer-product-style comparison. In TacitJ subset, the
NB. simplest form is to count each unique element separately.
NB.
NB. NB. The inner-product form `+/ . =` is not currently
NB. NB. tokenised by TacitJ, so we use a different approach.

NB. The nub sieve: ~: y is 1 where y[i] is the FIRST
NB. occurrence of its value, 0 otherwise. The sum is the
NB. number of unique elements. (Equivalent to # ~. y.)
nUniq =. +/ ~: ys
smoutput 'count of unique values: ' , ": nUniq
NB. -> 8

NB. Total duplicates: # ys - # uniq ys.
nDups =. (# ys) - (# uniq ys)
smoutput 'duplicates: ' , ": nDups
NB. -> 4  (12 elements, 8 unique, 4 duplicates)

NB. Per-element counts: since we can't easily broadcast
NB. equality across different-shape lists in our subset,
NB. we hand-compute using a few key comparisons.
counts5 =. +/ ys = 5
counts2 =. +/ ys = 2
counts8 =. +/ ys = 8
smoutput 'count of 5: ' , (": counts5)
smoutput 'count of 2: ' , (": counts2)
smoutput 'count of 8: ' , (": counts8)

NB. --- Sort by key ----------------------------------
NB. A common idiom: sort pairs by the first element.
NB. We have numeric pairs (key, value): (3,30) (1,10) (2,20).
NB. Sort by key ascending.
keys =. 3 1 2
vals =. 30 10 20
NB. Build a 2-column matrix with keys in column 0.
pairs =. keys ,. vals
smoutput 'pairs (key, value):'
smoutput pairs
NB. -> 3 30
NB.    1 10
NB.    2 20

NB. Sort pairs by their first column (the key).
NB. We grade on column 0 of pairs, then use the grade to
NB. permute rows of pairs.
order =. /: 0 { pairs
sortedPairs =. pairs /: order
smoutput 'sorted by key:'
smoutput sortedPairs
NB. -> 1 10
NB.    2 20
NB.    3 30

NB. --- Summary --------------------------------------
smoutput ''
smoutput 'summary:'
smoutput '  data         = ' , ": ys
smoutput '  asc          = ' , ": asc ys
smoutput '  desc         = ' , ": desc ys
smoutput '  unique       = ' , ": uniq ys
smoutput '  n dups       = ' , (": nDups)
smoutput '  n uniq       = ' , (": nUniq)