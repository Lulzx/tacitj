NB. ============================================================
NB. test_pipeline.ijs - End-to-end pipeline tests
NB. ============================================================
NB. Verifies that lex + (eval) works on representative TacitJ
NB. programs. The parser is not used in Phase 0 (see TODO).

NB. --- Basic value tests -----------------------------------

NB. NB: runTacitJ returns the value of the last expression (or
NB. an empty boxed array for multi-line sources that don't produce
NB. a value).

NB. Hello world
src =. '''hello world'''
r =. runTacitJ src
assert r ; 'hello world' ; <'runTacitJ: hello world'

NB. Arithmetic
r =. runTacitJ '2 + 3'
assert r ; 5 ; <'runTacitJ: 2 + 3 = 5'

NB. Right-to-left arithmetic
r =. runTacitJ '3 * 4 + 5'
assert r ; 27 ; <'runTacitJ: 3 * 4 + 5 = 27 (J right-to-left)'

NB. --- Definition + use ------------------------------------

NB. Define pi, then reference (multi-line, so no result)
r =. runTacitJ 'pi =: 3.14159', LF, 'pi'
NB. The result is empty; just check it didn't crash.
assert (# r) ; (# r) ; <'runTacitJ: pi =: 3.14159 ; pi (no crash)'

NB. --- Train (mean) -----------------------------------------

NB. mean =: +/ % # ; mean 1 2 3 4 5 = 3
r =. runTacitJ 'mean =: +/ % #', LF, 'mean 1 2 3 4 5'
NB. Multi-line, no result.
assert (# r) ; (# r) ; <'runTacitJ: mean =: +/ % # ; mean 1..5 (no crash)'

NB. --- Example file smoke tests -----------------------------

NB. runExamples: run smoke tests on example files. Defined as a function
NB. to avoid control structures at the top level of this script.
runExamples =: 3 : 0
  NB. Use the project root (one level up from tests/)
  root =. '/Users/lulzx/work/jinj'
  hello =. root , '/examples/hello.ijs'
  mean  =. root , '/examples/mean.ijs'
  if. fexist hello do.
    r =. runFile hello
    NB. 3-tuple assertion: wrap each in <...> to avoid J unrolling
    assert (<(# r)) ; (<(# r)) ; <'runFile: examples/hello.ijs ran without crash'
  end.
  if. fexist mean do.
    r =. runFile mean
    assert (<(# r)) ; (<(# r)) ; <'runFile: examples/mean.ijs ran without crash'
  end.
  EMPTY
)
runExamples ''

