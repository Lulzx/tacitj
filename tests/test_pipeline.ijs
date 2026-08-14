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


NB. --- v0.20: dfn, one-line defs, 2-char verbs, exec path ----

NB. A {{ }} dfn compiles and executes through the pipeline.
r =. compile 'double =: {{ y * 2 }}', LF, 'double 5'
assert r ; 10 ; <'compile: {{ }} dfn double 5 = 10'

NB. A one-line explicit def compiles and executes.
r =. compile 'f =: 3 : ''y + 1''', LF, 'f 5'
assert r ; 6 ; <'compile: one-line def f 5 = 6'

NB. The format verb ": unparses unquoted and executes.
r =. compile 'smoutput ":" 42'
assert (# r) ; (# r) ; <'compile: ": format (no crash)'

NB. The integers verb i. compiles and executes.
r =. compile '+/ i. 5'
assert r ; 10 ; <'compile: +/ i. 5 = 10'

NB. The stitch verb ,. compiles and executes.
r =. compile '1 2 ,. 3 4'
assert r ; (2 2 $ 1 3 2 4) ; <'compile: 1 2 ,. 3 4 = 2x2 stitch'

NB. --- Exec-path fidelity: emitted compiler runs end-to-end --
NB. Emit all modules, load them in a fresh locale, and run a
NB. program through the emitted compiler's own `compile` verb
NB. (lex -> parse -> sem -> lowerIr -> opt -> execIr).
emitAllModules =: 3 : 0
  shortNames =. 'lex';'parse';'sem';'ir';'opt';'eval';'codegen';'mdl';'tacitj'
  i =. 0
  while. i < # srcFiles do.
    path =. > i { srcFiles
    src =. 1!:1 < path
    resetOptEnv ''
    ir =. optWithEnv lowerIr semAnalyze parseProgram lex src
    j =. emitIr ir
    j 1!:2 < ('/tmp/tacitj_selfhost_' , (> i { shortNames)) , '.ijs'
    i =. >: i
  end.
  EMPTY
)
emitAllModules ''
cocurrent 'sh'
load '/tmp/tacitj_selfhost_lex.ijs'
load '/tmp/tacitj_selfhost_parse.ijs'
load '/tmp/tacitj_selfhost_sem.ijs'
load '/tmp/tacitj_selfhost_ir.ijs'
load '/tmp/tacitj_selfhost_opt.ijs'
load '/tmp/tacitj_selfhost_eval.ijs'
load '/tmp/tacitj_selfhost_codegen.ijs'
load '/tmp/tacitj_selfhost_mdl.ijs'
load '/tmp/tacitj_selfhost_tacitj.ijs'
cocurrent 'base'
rSelf =. compile_sh_ '2 + 3'
assert rSelf ; 5 ; <'selfhost: emitted compiler exec path 2 + 3 = 5'
rSelf2 =. compile_sh_ 'mean =: +/ % #', LF, 'mean 1 2 3 4 5'
assert rSelf2 ; 3 ; <'selfhost: emitted compiler exec path mean 1..5 = 3'

NB. --- v0.21: gerund tie ` and agenda @. (SPEC 2.1) ---------

NB. A gerund (tie) compiles and executes; 0 { g is the boxed 'hello'.
r =. compile 'g =: (<''hello'')`]', LF, '0 { g'
assert r ; (<'hello') ; <'compile: gerund g ; 0 { g = boxed hello'

NB. Agenda @. with constant verbs: pick 3 (odd) = 1, pick 4 (even) = 0.
r =. compile 'pick =: 0:`1:`2: @. (2&|)', LF, 'pick 3'
assert r ; 1 ; <'compile: agenda pick 3 = 1'
r =. compile 'pick =: 0:`1:`2: @. (2&|)', LF, 'pick 4'
assert r ; 0 ; <'compile: agenda pick 4 = 0'

NB. Constant verb round-trips as a fixed point.
cvSrc =. 'c =: 0:'
cv1 =. compileSrcToJs cvSrc
cv2 =. compileSrcToJs cv1
assert cv1 ; cv2 ; <'compile: 0: constant verb is a fixed point'
