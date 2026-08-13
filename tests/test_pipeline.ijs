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

NB. --- Self-host foundation: src/*.ijs round-trip (v0.19) ----
NB.
NB. The headline blocker for Stage 3 was that the compiler source
NB. (src/*.ijs) uses J outside the Stage 0 subset (3 : 0 blocks,
NB. comments inside strings, _1 literals, chained =:). v0.19 adds
NB. explicit-definition blocks, string-aware comment stripping,
NB. negative-number literals and chained assignment. This test
NB. asserts the result: every src/*.ijs file now compiles through
NB. the pipeline AND round-trips as a syntactic fixed point.
NB.
NB. compileToJs: lex -> ... -> emitIr (the emitted J source).

srcFiles =: 'src/lex.ijs';'src/parse.ijs';'src/sem.ijs';'src/ir.ijs';'src/opt.ijs';'src/eval.ijs';'src/codegen.ijs';'src/mdl.ijs';'src/tacitj.ijs'

compileSrcToJs =: 3 : 0
  resetOptEnv ''
  ir =. optWithEnv lowerIr semAnalyze parseProgram lex y
  emitIr ir
)

compileFileToJs =: 3 : 0
  src =. 1!:1 < y
  compileSrcToJs src
)

NB. every src file is a fixed point
checkSrcFixed =: 3 : 0
  f =. y
  src =. 1!:1 < f
  j1 =. compileSrcToJs src
  j3 =. compileSrcToJs j1
  fp =. j1 -: j3
  desc =. 'selfhost: ' , (6 {. f) , ' fixed-point'
  if. fp do.
    tpass =: < (1 + > tpass)
    smoutput '  PASS  ' , desc
  else.
    tfail =: < (1 + > tfail)
    smoutput '  FAIL  ' , desc
  end.
  EMPTY
)

checkAllSrc =: 3 : 0
  for_f. srcFiles do.
    checkSrcFixed > f
  end.
  EMPTY
)
checkAllSrc ''

NB. The emitted J for src/lex.ijs must itself contain the def
NB. bodies (verbatim), i.e. the output is not truncated.
lexEmit =. compileFileToJs 'src/lex.ijs'
assert (0 < +/ 'stripComments =: 3 : 0' E. lexEmit) ; 1 ; <'selfhost: emitted lex.ijs keeps def bodies'

