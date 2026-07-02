NB. ============================================================
NB. stage2.ijs - Stage 2 bootstrap (output-contract freeze)
NB. ============================================================
NB. Stage 2 freezes the Stage 0 *output contract*: a fixed
NB. canary corpus whose emitted J source is a round-trip
NB. fixed point. A fixed point means:
NB.
NB.     emit(compile(src)) == emit(compile(emit(compile(src))))
NB.
NB. That property is the seed of self-hosting: if a compiler
NB. source were itself such a fixed point, the classical
NB. `diff(stage2, stage3)` check would hold. Stage 2 establishes
NB. the contract that Stage 3 must preserve, and records a
NB. tacit-density baseline over src/*.ijs that a future
NB. tacit refactor of the compiler source must increase.
NB.
NB. This is NOT (yet) a tacit rewrite of the compiler source.
NB. The current src/*.ijs already mixes tacit and explicit
NB. verbs; Stage 2 measures that mix and pins the output
NB. contract. A later refactor keeps this contract green while
NB. raising the tacit density, and Stage 3 then proves the
NB. self-compiled compiler reproduces the same contract.
NB.
NB. Usage:
NB.   jconsole bootstrap/stage2.ijs
NB.   make stage2
NB.
NB. Exit 0 iff: Stage 0 canary holds AND every corpus case is a
NB. round-trip fixed point. Exit 1 otherwise.

load 'bootstrap/stage0.ijs'

NB. --- The canary corpus -------------------------------------
NB. A small fixed set of TacitJ sentences that exercise the
NB. main pipeline shapes (arithmetic, precedence, insert
NB. adverb, assignment+fork, bare expression). These are the
NB. Stage 1 == Stage 2 output contract: any change to the
NB. compiler that alters emitted output for these cases is a
NB. contract break.
CORPUS =: (<'2 + 3') , (< '1 + 2 * 3') , (<'+/ 1 2 3 4 5') , (<'mean =: +/ % #') , (<'smoutput 42')

NB. --- The fixed-point check ---------------------------------
NB. compileToJs: lex -> ... -> emitIr, the emitted J source.
NB. resetOptEnv first so the optimizer env doesn't bleed.
compileToJs =: 3 : 0
  resetOptEnv ''
  ir =. optWithEnv lowerIr semAnalyze parseProgram lex y
  emitIr ir
)

NB. isFixedPoint: 1 iff y is a round-trip fixed point, i.e.
NB. re-compiling the emitted J source reproduces it verbatim.
isFixedPoint =: 3 : 0
  j1 =. compileToJs y
  j2 =. compileToJs j1
  j1 -: j2
)

NB. --- Tacit-density baseline -------------------------------
NB. A coarse metric over src/*.ijs: count tacit definitions
NB. (`name =: <expr>` on one line) vs explicit definitions
NB. (`name =: 3 : 0`, `name =: 4 : 0`, `name =: {{`). The
NB. ratio is the baseline a future tacit refactor must raise.
NB. This is a measurement, not a judgement.

NB. isExplicitLine: 1 if a line opens an explicit definition.
NB. Matches `3 : 0`, `4 : 0`, or `{{`.
isExplicitLine =: 3 : 0
  line =. y
  (0 < +/ '3 : 0' E. line) +. (0 < +/ '4 : 0' E. line) +. (0 < +/ '{{' E. line)
)

NB. isTacitDef: 1 if a line looks like a one-line tacit
NB. definition `name =: <expr>` (has `=:` but is not explicit).
isTacitDef =: 3 : 0
  line =. y
  hasAssign =. 0 < +/ '=:' E. line
  (hasAssign) *. -. isExplicitLine line
)

NB. countDefs: (tacitCount ; explicitCount) for one file path.
countDefs =: 3 : 0
  src =. 1!:1 < y
  lines =. <;._2 src , LF
  tac =. 0
  exp =. 0
  for_l. lines do.
    line =. > l
    if. 0 < # line do.
      if. isTacitDef line do. tac =. >: tac
      elseif. isExplicitLine line do. exp =. >: exp end.
    end.
  end.
  tac ; exp
)

NB. densityReport: scan src/*.ijs, print per-file and total
NB. tacit-vs-explicit counts, and the tacit fraction.
densityReport =: 3 : 0
  files =. 'src/lex.ijs';'src/parse.ijs';'src/sem.ijs';'src/ir.ijs';'src/opt.ijs';'src/eval.ijs';'src/codegen.ijs';'src/mdl.ijs';'src/tacitj.ijs'
  totalTac =. 0
  totalExp =. 0
  smoutput '--- tacit-density baseline (src/*.ijs) ---'
  for_f. files do.
    'tac exp' =. countDefs > f
    totalTac =. totalTac + tac
    totalExp =. totalExp + exp
    smoutput '  ' , (16 {. > f) , ' tacit=' , (": tac) , '  explicit=' , (": exp)
  end.
  tot =. totalTac + totalExp
  frac =. 0
  if. 0 < tot do. frac =. totalTac % tot end.
  smoutput '  total          tacit=' , (": totalTac) , '  explicit=' , (": totalExp) , '  fraction=' , (": frac)
  totalTac ; totalExp
)

NB. --- Driver -----------------------------------------------
stage2Run =: 3 : 0
  if. 0 = nc <'compile' do.
    smoutput 'stage2: FATAL compile not defined after loading stage0'
    1 return.
  end.
  smoutput 'stage2: output-contract freeze + tacit-density baseline'
  smoutput ''

  NB. 1. Stage 0 canary must hold (compiler is stable).
  smoutput '--- stage 0 canary ---'
  rc =. selfhost0 ''
  smoutput '  selfhost0 = ' , (": rc) , ' (1=OK, 0=MISMATCH)'
  if. 0 = rc do.
    smoutput 'stage2: FAIL stage 0 canary broken'
    1 return.
  end.
  smoutput '  canary    = ' , tacitj0 ''
  smoutput ''

  NB. 2. Canaries corpus: every case must be a fixed point.
  smoutput '--- output contract (round-trip fixed points) ---'
  ok =. 0
  total =. # CORPUS
  for_c. CORPUS do.
    src =. > c
    fp =. isFixedPoint src
    if. fp do. ok =. >: ok end.
    j =. compileToJs src
    smoutput '  ' , src , ' -> ' , j , '  fixed=' , (": fp)
  end.
  smoutput '  contract: ' , (": ok) , ' / ' , (": total) , ' cases are fixed points'
  smoutput ''

  NB. 3. Tacit-density baseline.
  'tac exp' =. densityReport ''
  smoutput ''

  NB. 4. Verdict.
  if. (rc = 1) *. (ok = total) do.
    smoutput 'stage2: OK output contract frozen, tacit-density baseline recorded'
    0
  else.
    smoutput 'stage2: FAIL contract broken (see above)'
    1
  end.
)

exit stage2Run ''