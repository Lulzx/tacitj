NB. ============================================================
NB. examples/train.ijs - Demonstrate 2- and 3-trains (tacit)
NB. ============================================================
NB. `+/ % #` is a 3-train (fork) that computes the mean of a
NB. list. `+/"1` is a tacit composition: apply +/ to each
NB. row of a 2-D array.

mean =: +/ % #
sum  =: +/
len  =: #

mean 1 2 3 4 5
sum  1 2 3 4 5
len  1 2 3 4 5

NB. A 2-train (hook): `2&*` is the same as `*` with a constant 2
double =: 2&*
double 7

NB. A 2-train (hook): `1&+` increments
incr =: 1&+
incr 41
