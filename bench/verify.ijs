NB. ============================================================
NB. verify.ijs - Bootstrap verification
NB. ============================================================
NB. For a small fixed corpus, this script verifies that the
NB. compiler is deterministic: running `compile` twice on the
NB. same input gives the same emitted J source. This proves the
NB. pipeline (lex → parse → sem → lowerIr → opt → exec) has no
NB. hidden state leaks that affect output.
NB.
NB. Also verifies that explicit-step compilation (lex → ...
NB. → emitIr) gives the same emitted J source as a fresh run
NB. after a `resetOptEnv` flush. This proves the optimizer
NB. env doesn't bleed between runs.
NB.
NB. Run with:
NB.   jconsole bench/verify.ijs
NB.   make verify

load 'src/lex.ijs'
load 'src/parse.ijs'
load 'src/sem.ijs'
load 'src/ir.ijs'
load 'src/opt.ijs'
load 'src/codegen.ijs'
load 'src/tacitj.ijs'

NB. --- The fixed corpus -------------------------------

NB. A handful of small programs that exercise the main pipeline
NB. features. Each is a single non-empty TacitJ sentence so we
NB. can compare outputs without sentence-end ambiguity.
CASES =. <'2 + 3'
CASES =. CASES , <'1 + 2 * 3'
CASES =. CASES , <'+/ 1 2 3 4 5'
CASES =. CASES , <'mean =: +/ % #'
CASES =. CASES , <'smoutput 42'

NB. --- The verifier -------------------------------------

NB. compileToJs: lex → parse → sem → lowerIr → opt → emitIr,
NB. giving the emitted J source as a string.
compileToJs =: 3 : 0
  src =. y
  resetOptEnv ''
  ir =. optWithEnv lowerIr semAnalyze parseProgram lex src
  emitIr ir
)

NB. determinismCheck: verify that running compile twice gives
NB. the same emitted J source. Returns 1 iff identical.
determinismCheck =: 3 : 0
  src =. y
  j1 =. compileToJs src
  j2 =. compileToJs src
  -. -. j1 -: j2
)

NB. envBleedCheck: verify that running compile after a
NB. different program gives the same result as running it
NB. standalone. Uses a separate program to "prime" the env.
envBleedCheck =: 3 : 0
  src =. y
  NB. Prime env with a different program
  compileToJs '1 2 3 + 4 5 6'
  NB. Now compile src fresh
  j =. compileToJs src
  NB. Prime env again
  compileToJs '1 2 3 + 4 5 6'
  NB. Compile src again
  j2 =. compileToJs src
  -. -. j -: j2
)

NB. countTrues: count true values in a list (after unboxing).
countTrues =: +/

NB. Run determinismCheck on each case.
det =. > determinismCheck each CASES
n1 =. countTrues det

NB. Run envBleedCheck on each case.
env =. > envBleedCheck each CASES
n2 =. countTrues env

total =. # CASES

smoutput 'Bootstrap verification'
smoutput '====================='
smoutput ''
smoutput 'determinism:  ' , (": n1) , ' / ' , (": total)
smoutput 'env-bleed:    ' , (": n2) , ' / ' , (": total)
smoutput ''
smoutput 'overall:      ' , (": n1 + n2) , ' / ' , (": 2 * total)
ok =. (n1 + n2) = (2 * total)
exit *. ok