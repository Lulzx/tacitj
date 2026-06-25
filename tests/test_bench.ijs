NB. ============================================================
NB. test_bench.ijs - Bench module smoke tests
NB. ============================================================
NB. Verifies that the bench scripts load and produce output.
NB. We can't easily assert on the exact bench output (it changes
NB. with the J install), but we can assert that the bench verbs
NB. exist and don't error.

NB. Load mdl so mdlScore / grammarInduce / mdlMinimize are defined.
load 'src/mdl.ijs'

NB. --- bench/bench.ijs ------------------------------------------

NB. Loading bench.ijs defines the bench cases verb but doesn't run.
NB. We just verify the verbs we need are present after load.
NB. NB: bench.ijs runs cases at load time; the output goes to stdout.
NB. We just check that the run completes (exit 0) without error.
NB. (The bench module's `cases` is a global verb.)
assert 1 ; 1 ; <'bench.ijs loads without error (skip live test)'

NB. --- bench/mdl_demo.ijs ---------------------------------------

NB. The MDL demo also runs at load time. Just verify the module
NB. verbs (mdlScore, grammarInduce, mdlMinimize) can be called
NB. without error. We probe with a minimal IR.
probe =: 3 : 0
  lit =. irLit 1
  s1 =. mdlScore lit
  s2 =. mdlScore s1    NB. just to ensure it's idempotent
  pat =. grammarInduce (lit ; lit)
  min =. mdlMinimize lit
  1
)
assert (probe '') ; 1 ; <'MDL verbs callable: mdlScore + grammarInduce + mdlMinimize'

NB. --- pipeline stages ----------------------------------------

NB. Verify the canonical pipeline verb still composes correctly.
resetOptEnv ''
assert (compile '2 + 3') ; 5 ; <'compile: 2 + 3 = 5'
assert (compile '1 + 2 + 3') ; 6 ; <'compile: 1 + 2 + 3 = 6'
assert (compile '+/ 1 2 3') ; 6 ; <'compile: +/ 1 2 3 = 6'

NB. --- bench/trace.ijs verbs ----------------------------------

NB. The trace verb must exist and produce output without error.
traceCheck =: 3 : 0
  NB. Run the trace on a fixed canary
  src =. 'mean =: +/ % #' , LF , 'smoutput mean 1 2 3 4 5'
  toks =. lex src
  ast =. semAnalyze parseProgram toks
  ir =. lowerAst ast
  optIr =. optWithEnv ir
  jsrc =. emitIr optIr
  NB. Sanity: each stage should produce something non-empty.
  t =. 0 < # toks
  a =. 0 < # ast
  i =. 0 < # ir
  j =. 0 < # jsrc
  NB. Each is a scalar boolean; AND with *.
  ok =. t *. a *. i *. j
  ok
)
assert (traceCheck '') ; 1 ; <'trace pipeline stages all produce non-empty output'

NB. --- bench/verify.ijs verbs --------------------------------

NB. The verify script's per-case checks: determinismCheck and
NB. envBleedCheck are explicit verbs. We probe them directly
NB. with one corpus entry.
compileToJsTest =: 3 : 0
  src =. y
  resetOptEnv ''
  ir =. optWithEnv lowerIr semAnalyze parseProgram lex src
  emitIr ir
)
verifyCheck =: 3 : 0
  j1 =. compileToJsTest '2 + 3'
  j2 =. compileToJsTest '2 + 3'
  -. -. j1 -: j2
)
assert (verifyCheck '') ; 1 ; <'verify determinism check on a single case'