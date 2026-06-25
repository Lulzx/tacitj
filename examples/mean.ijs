NB. ============================================================
NB. examples/mean.ijs - Mean via 3-train
NB. ============================================================
NB. `mean =: +/ % #` defines a fork that, given a list,
NB. returns its arithmetic mean.

mean =: +/ % #

smoutput mean 1 2 3 4 5        NB. -> 3
smoutput mean 10 20 30         NB. -> 20

NB. Compose with another tacit verb using @ (atop).
NB. squaredMean = *: @ mean — square the mean of a list.
NB. NB: *: @ mean means (*: (mean y)) for a list y.
NB. For y = 1..5: mean = 3, so *: 3 = 9.
squaredMean =: *: @ mean

smoutput squaredMean 1 2 3 4 5        NB. -> 9