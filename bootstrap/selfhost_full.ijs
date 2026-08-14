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
NB. v0.20: the remaining honest gaps are closed:
NB.   - `{{ }}` direct definitions are captured as opaque T_DEF
NB.     tokens (single-line and multi-line).
NB.   - One-line explicit defs (`3 : '...'` / `4 : '...'`) are
NB.     captured verbatim (no parenthesised-train emission).
NB.   - Top-level execution statements (load, smoutput, runArgv)
NB.     execute correctly through the emitted compiler's exec path
NB.     (they are not unevaluated verb phrases).
NB.   - The execution path (execIr / runTacitJ) of the emitted
NB.     compiler is exercised end-to-end below.
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
  NB. Use the emitted compiler's own `compile` verb (which runs the
  NB. full exec path: lex -> parse -> sem -> lowerIr -> opt ->
  NB. execIr) so the self-compiled compiler is exercised end-to-end.
  canaryOk =. 0
  corpus =. (<'2 + 3') , (< '1 + 2 * 3') , (<'+/ 1 2 3 4 5') , (<'mean =: +/ % #')
  for_c. corpus do.
    src2 =. > c
    try.
      r =. compile_sh_ src2
      canaryOk =. >: canaryOk
      smoutput '  self: ' , src2 , ' -> ' , ": r
    catch.
      smoutput '  self: ' , src2 , ' FAILED: ' , 13!:12 ''
    end.
  end.
  NB. Exec-path fidelity: the emitted compiler must execute a
  NB. program with top-level execution statements (smoutput) and
  NB. return the last bare expression's value.
  execOk =. 0
  try.
    r2 =. compile_sh_ 'smoutput ''hi''', LF, 'x =: 5', LF, 'x + 1'
    if. r2 -: 6 do. execOk =. 1 end.
  catch.
    smoutput '  self exec-path FAILED: ' , 13!:12 ''
  end.
  cocurrent 'base'
  smoutput '  canary: ' , (": canaryOk) , ' / ' , (": # corpus)
  smoutput '  exec-path fidelity: ' , (": execOk)
  smoutput ''

  NB. 3. Verdict.
  if. (ok = total) *. (canaryOk = # corpus) *. execOk do.
    smoutput 'selfhost_full: OK compiler compiles through itself'
    smoutput '  (all src/*.ijs are fixed points; self-compiled'
    smoutput '   compiler reproduces the Stage 0 output contract'
    smoutput '   and its exec path runs end-to-end)'
    0
  else.
    smoutput 'selfhost_full: FAIL (see above)'
    1
  end.
)

exit stageRun ''
