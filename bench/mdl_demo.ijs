NB. ============================================================
NB. mdl_demo.ijs - MDL / grammar-induction demo runner
NB. ============================================================
NB. Run with:
NB.   jconsole bench/mdl_demo.ijs
NB.
NB. Builds a small corpus of 4 IRs (1+2, 1*2, 1+3, 2*3),
NB. then:
NB.   1. Scores each IR with mdlScore (grammar + data cost)
NB.   2. Induces the common sub-IRs across the corpus
NB.   3. Runs mdlMinimize on each IR and reports cost reduction
NB.
NB. Run via `make mdl-demo`.

load 'src/mdl.ijs'
mdlDemo ''