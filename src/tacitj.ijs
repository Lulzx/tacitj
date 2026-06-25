NB. ============================================================
NB. tacitj.ijs - TacitJ top-level pipeline
NB. ============================================================
NB. Loads lexer, parser, semantic, IR, optimizer, codegen, and
NB. evaluator, then exposes the canonical compile pipeline as a
NB. tacit composition:
NB.
NB.   compile =: execIr @ optWithEnv @ lowerIr @ semAnalyze @ parseProgram @ lex
NB.
NB. The codegen module (src/codegen.ijs) provides:
NB.   emitIr     - unparse IR to J source string
NB.   emitFile   - write IR as J source to a file
NB.   compileFile - read source, compile, emit to output file
NB.
NB. `runTacitJ` shells to J's 0!:101 for validation and multi-line
NB. programs. The IR pipeline (`compile`) is used by tests.

load 'src/lex.ijs'
load 'src/parse.ijs'
load 'src/sem.ijs'
load 'src/ir.ijs'
load 'src/opt.ijs'
load 'src/eval.ijs'
load 'src/codegen.ijs'

NB. lowerIr: AST -> IR (the IR Stage's entry point)
lowerIr =: lowerAst

NB. codegen: emit J source from the IR and execute it via J.
NB. (The codegen.ijs module provides emitIr for non-execution use.)
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
