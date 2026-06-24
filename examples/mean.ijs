NB. ============================================================
NB. examples/mean.ijs - Mean via 3-train
NB. ============================================================
NB. `mean =: +/ % #` defines a fork that, given a list,
NB. returns its arithmetic mean.

mean =: +/ % #

mean 1 2 3 4 5        NB. -> 3
mean 10 20 30         NB. -> 20

NB. Compose with another tacit verb
NB. (mean is rank-1, so we use @ to force rank-0 composition)
squaredMean =: *: @ mean

squaredMean 1 2 3 4 5  NB. -> 9
