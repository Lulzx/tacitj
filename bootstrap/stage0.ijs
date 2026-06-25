NB. ============================================================
NB. stage0.ijs - Stage 0 bootstrap loader (module form)
NB. ============================================================
NB. The Stage 0 compiler is the hand-written J source in src/.
NB. This loader script:
NB.
NB.   1. Loads every src/*.ijs into the current namespace.
NB.   2. Defines the canary fingerprint helper (`tacitj0`).
NB.   3. Defines the selfhost check helper (`selfhost0`).
NB.
NB. Use:
NB.   load 'bootstrap/stage0.ijs'    NB. inside another script
NB.   jconsole bootstrap/stage0.ijs  NB. as a one-shot smoke test
NB.
NB. After this loads, the user namespace contains the full
NB. Stage 0 compiler (compile, lex, parse, semAnalyze, lowerIr,
NB. optWithEnv, execIr, emitIr, emitFile, compileFile, runCompile).
NB.
NB. Stage 0 is what Stages 1+ are measured against. If stage0
NB. changes, all later stages must be regenerated.
NB.
NB. NOTE: This module form has no top-level `exit` or `if.`
NB. control flow. Use `stage0Run` from stage0_run.ijs (or any
NB. other script) to do the load + check + exit dance.

load 'src/lex.ijs'
load 'src/parse.ijs'
load 'src/sem.ijs'
load 'src/ir.ijs'
load 'src/opt.ijs'
load 'src/eval.ijs'
load 'src/codegen.ijs'
load 'src/tacitj.ijs'

NB. --- canary helpers ----------------------------------------

NB. canary: a fixed-expression fingerprint used for self-host checks.
NB. Compiles the canary through the full pipeline and returns a
NB. short stable string (the emitted J source + a length tag).
tacitj0 =: 3 : 0
  src =. '1 + 2'
  ir  =. optWithEnv lowerIr semAnalyze parseProgram lex src
  jsrc =. emitIr ir
  jsrc , '|' , ": # jsrc
)

NB. selfhost0: verify Stage 0 by running the canary and comparing.
NB. Returns 1 (success) or 0 (mismatch).
selfhost0 =: 3 : 0
  expected =. '( 1 + 2 )|9'
  actual   =. tacitj0 ''
  if. actual -: expected do.
    1
  else.
    smoutput 'selfhost0 MISMATCH expected=' , expected , ' actual=' , actual
    0
  end.
)
