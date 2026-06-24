NB. ============================================================
NB. tacitj.ijs - TacitJ top-level pipeline
NB. ============================================================
NB. Loads lexer, parser, semantic, IR, optimizer, and evaluator,
NB. then exposes the canonical compile pipeline as a tacit
NB. composition:
NB.
NB.   compile =: execIr @ opt @ lowerIr @ semAnalyze @ parseProgram @ lex
NB.
NB. For now, the IR-driven codegen is only exercised by tests
NB. that call `compile` directly. `runTacitJ` (which still uses
NB. J's `".` to validate) is kept as a convenience for the
NB. REPL and example runner.

load 'src/lex.ijs'
load 'src/parse.ijs'
load 'src/sem.ijs'
load 'src/ir.ijs'
load 'src/opt.ijs'
load 'src/eval.ijs'

NB. lowerIr: AST -> IR (the IR Stage's entry point)
lowerIr =: lowerAst

NB. codegen: emit J source from the IR and execute it via J.
codegen =: execIr

NB. compile: source char vector -> boxed result vector
NB. Tacit: compose lex; parse; sem; lowerIr; opt; codegen.
compile =: codegen @ optWithEnv @ lowerIr @ semAnalyze @ parseProgram @ lex

NB. runFile: read a TacitJ source file and run it.
NB. Uses runTacitJ (source-level execution) so multi-line
NB. examples with bare expressions still print. The IR pipeline
NB. is exercised by tests via `compile`.
runFile =: 3 : 0
  src =. 1!:1 < y
  runTacitJ src
)

NB. repl: minimal read-eval-print loop.
repl =: 3 : 0
  smoutput 'TacitJ REPL. Press Ctrl-D to exit.'
  while. 1 do.
    line =. 1!:1 [ 1
    if. line -: '' do. break. end.
    v =. compile line
    smoutput v
  end.
  smoutput 'bye.'
)

smoutput 'TacitJ loaded.'
