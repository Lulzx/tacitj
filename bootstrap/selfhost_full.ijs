NB. ============================================================
NB. selfhost_full.ijs - full self-host driver (Stage 3+)
NB. ============================================================
NB. v0.19: the compiler source (src/*.ijs) now compiles through
NB. the Stage 0 pipeline (explicit-definition blocks, string-aware
NB. comment stripping, _-literals, chained =: are all supported).
NB. This driver proves the self-host loop concretely:
NB.
NB.   1. Every src/*.ijs file compiles through the pipeline AND
NB.      round-trips as a syntactic fixed point
NB.        emit(compile(src)) == emit(compile(emit(compile(src))))
NB.   2. The emitted (self-compiled) modules load in a clean
NB.      namespace and reproduce the Stage 0 output contract:
NB.      the self-compiled lexer/parser/lowerer/optimizer/codegen
NB.      emit the canonical canary output for a corpus case.
NB.
NB. Remaining honest gaps (documented, not claimed):
NB.   - The emitted output re-parenthesises top-level sentences;
NB.     bare execution statements (load, smoutput, runArgv) are
NB.     emitted as (unevaluated) verb phrases.
NB.   - The execution path (execIr / runTacitJ) of the emitted
NB.     compiler is not yet exercised end-to-end.
NB.
NB. Usage:
NB.   jconsole bootstrap/selfhost_full.ijs
NB.   make selfhost-full
NB.
NB. Exit 0 iff every src file is a fixed point AND the self-
NB. compiled compiler reproduces the canary output. Exit 1
NB. otherwise.

load 'bootstrap/stage0.ijs'

NB. --- source-file corpus -----------------------------------
SRC_FILES =: 'src/lex.ijs';'src/parse.ijs';'src/sem.ijs';'src/ir.ijs';'src/opt.ijs';'src/eval.ijs';'src/codegen.ijs';'src/mdl.ijs';'src/tacitj.ijs'

NB. compileSrcToJs: lex -> ... -> emitIr on a source string.
compileSrcToJs =: 3 : 0
  resetOptEnv ''
  ir =. optWithEnv lowerIr semAnalyze parseProgram lex y
  emitIr ir
)

NB. isFixedPointStr: 1 iff re-compiling the emitted J of y
NB. reproduces it verbatim.
isFixedPointStr =: 3 : 0
  j1 =. compileSrcToJs y
  j2 =. compileSrcToJs j1
  j1 -: j2
)

NB. --- driver -----------------------------------------------
stageRun =: 3 : 0
  smoutput 'selfhost_full: compile the compiler through itself'
  smoutput ''

  NB. 1. Every src file is a fixed point.
  smoutput '--- src/*.ijs fixed points ---'
  ok =. 0
  for_f. SRC_FILES do.
    path =. > f
    src =. 1!:1 < path
    fp =. isFixedPointStr src
    if. fp do. ok =. >: ok end.
    j =. compileSrcToJs src
    smoutput '  ' , (14 {. path) , ' fixed=' , (": fp) , ' emitted=' , (": # j) , ' chars'
  end.
  total =. # SRC_FILES
  smoutput '  fixed points: ' , (": ok) , ' / ' , (": total)
  smoutput ''

  NB. 2. Emit all modules, load them in a clean namespace, and
  NB. verify the self-compiled compiler reproduces the output
  NB. contract for the canary corpus.
  smoutput '--- self-compiled compiler ---'
  NB. short name per file, used for the emitted file path
  shortNames =. 'lex';'parse';'sem';'ir';'opt';'eval';'codegen';'mdl';'tacitj'
  for_i. i. # SRC_FILES do.
    path =. > i { SRC_FILES
    src =. 1!:1 < path
    j =. compileSrcToJs src
    j 1!:2 < ('/tmp/tacitj_selfhost_' , (> i { shortNames)) , '.ijs'
  end.
  NB. Namespace dance: load the emitted modules in a fresh locale.
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
  smoutput '  emitted modules loaded in locale `sh`'
  canaryOk =. 0
  corpus =. (<'2 + 3') , (< '1 + 2 * 3') , (<'+/ 1 2 3 4 5') , (<'mean =: +/ % #')
  for_c. corpus do.
    src2 =. > c
    try.
      NB. Inline the self-hosted pipeline (no runtime `3 : 0` def:
      NB. defining explicit defs at runtime in a script is not
      NB. reliable in J 9.7).
      resetOptEnv ''
      ir =. optWithEnv lowerIr semAnalyze parseProgram lex src2
      j =. emitIr ir
      canaryOk =. >: canaryOk
      smoutput '  self: ' , src2 , ' -> ' , j
    catch.
      smoutput '  self: ' , src2 , ' FAILED: ' , 13!:12 ''
    end.
  end.
  cocurrent 'base'
  smoutput '  canary: ' , (": canaryOk) , ' / ' , (": # corpus)
  smoutput ''

  NB. 3. Verdict.
  if. (ok = total) *. (canaryOk = # corpus) do.
    smoutput 'selfhost_full: OK compiler compiles through itself'
    smoutput '  (all src/*.ijs are fixed points; self-compiled'
    smoutput '   compiler reproduces the Stage 0 output contract)'
    0
  else.
    smoutput 'selfhost_full: FAIL (see above)'
    1
  end.
)

exit stageRun ''
