NB. ============================================================
NB. runtests.ijs - TacitJ test runner
NB. ============================================================
NB. Loads modules and runs all test_<module>.ijs files.
NB. Each test file uses `assert` to record pass/fail.
NB. The runner prints a summary and exits with status 0/1.

NB. --- Test infrastructure ----------------------------------

NB. Counters (boxed scalars to allow mutation by helper verbs)
tpass =: <0
tfail =: <0

NB. assert: monadic. y = 3-element list (actual, expected, desc)
NB. Use as: assert actual ; expected ; <'description'
NB. (J right-to-left parses this as assert ((actual ; expected) ; <'description'))
assert =: 3 : 0
  triple =. y
  if. 3 = # triple do.
    'act exp desc' =. triple
  elseif. 2 = # triple do.
    'act exp' =. triple
    desc =. ''
  else.
    smoutput 'assert: bad arg count ' , ": # triple
    EMPTY return.
  end.
  if. act -: exp do.
    tpass =: < (1 + > tpass)
    smoutput '  PASS  ' , desc
  else.
    tfail =: < (1 + > tfail)
    smoutput '  FAIL  ' , desc
    smoutput '        expected: ' , ": exp
    smoutput '        actual  : ' , ": act
  end.
  EMPTY
)

NB. --- Run all test groups ----------------------------------

smoutput '=== TacitJ test suite ==='
smoutput ''

smoutput '-- Loading modules --'
load 'src/lex.ijs'
load 'src/parse.ijs'
load 'src/sem.ijs'
load 'src/ir.ijs'
load 'src/opt.ijs'
load 'src/eval.ijs'
load 'src/tacitj.ijs'
smoutput '   modules loaded.'
smoutput ''

smoutput '-- Lexer tests --'
load 'tests/test_lex.ijs'
smoutput ''

smoutput '-- Parser tests --'
load 'tests/test_parse.ijs'
smoutput ''

smoutput '-- IR tests --'
load 'tests/test_ir.ijs'
smoutput ''

smoutput '-- Optimizer tests --'
load 'tests/test_opt.ijs'
smoutput ''

smoutput '-- Pipeline tests --'
load 'tests/test_pipeline.ijs'
smoutput ''

smoutput '-- Codegen tests --'
load 'tests/test_codegen.ijs'
smoutput ''

smoutput '-- MDL tests --'
load 'tests/test_mdl.ijs'
smoutput ''

NB. --- Summary & exit ---------------------------------------

passN =. > tpass
failN =. > tfail
smoutput '=== Summary ==='
smoutput (": passN) , ' passed, ' , (": failN) , ' failed.'

exit (failN = 0) { 1 0
