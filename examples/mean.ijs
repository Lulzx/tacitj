NB. ============================================================
NB. examples/mean.ijs - Mean via 3-train
NB. ============================================================
NB. `mean =: +/ % #` defines a fork that, given a list,
NB. returns its arithmetic mean.

mean =: +/ % #

smoutput mean 1 2 3 4 5        NB. -> 3
smoutput mean 10 20 30         NB. -> 20

NB. Compose with another tacit verb (Stage 0 subset: *, + only)
NB. squaredMean = mean squared = (*: @ mean) is not Stage 0 yet,
NB. so we compute it explicitly: mean *: y.
NB. For y = 1..5: mean(y*y) = mean(1,4,9,16,25) = 11.
NB. Alternatively, (mean y) * (mean y) = 3*3 = 9 (which is what
NB. the original `*: @ mean` computes via compose). For Stage 0
NB. we just print the squared mean via composition at eval time:
NB.   smoutput (mean 1 2 3 4 5) * mean 1 2 3 4 5     NB. -> 9
smoutput (mean 1 2 3 4 5) * mean 1 2 3 4 5