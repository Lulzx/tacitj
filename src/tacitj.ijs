NB. ============================================================
NB. tacitj.ijs - TacitJ top-level pipeline
NB. ============================================================
NB. Loads lexer, parser, semantic, and evaluator, then exposes
NB. the canonical compile pipeline as a tacit composition.

load 'src/lex.ijs'
load 'src/parse.ijs'
load 'src/sem.ijs'
load 'src/eval.ijs'

NB. opt: Phase-1 placeholder.
opt =: ]

NB. codegen: Phase-1 = evaluate (transpile + run).
codegen =: evalProgram

NB. compile: source char vector -> boxed result vector
NB. Tacit: compose lex; parse; sem; opt; codegen.
compile =: codegen @ opt @ semAnalyze @ parseProgram @ lex

NB. runFile: read a TacitJ source file and run it.
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
