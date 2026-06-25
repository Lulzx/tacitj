NB. ============================================================
NB. smoke_all.ijs - Run every example and report pass/fail
NB. ============================================================
NB. For each .ijs file in examples/, this script runs it via
NB. runTacitJ and reports pass/fail. Output is a simple
NB. pass/fail line per example, then a summary line.
NB.
NB. Run with:
NB.   jconsole bench/smoke_all.ijs
NB.   make smoke-all

load 'src/lex.ijs'
load 'src/parse.ijs'
load 'src/sem.ijs'
load 'src/ir.ijs'
load 'src/opt.ijs'
load 'src/codegen.ijs'
load 'src/eval.ijs'
load 'src/tacitj.ijs'

NB. The example files (relative to repo root).
EXAMPLES =. <'examples/hello.ijs'
EXAMPLES =. EXAMPLES , <'examples/mean.ijs'
EXAMPLES =. EXAMPLES , <'examples/train.ijs'
EXAMPLES =. EXAMPLES , <'examples/pipeline.ijs'
EXAMPLES =. EXAMPLES , <'examples/wordcount.ijs'
EXAMPLES =. EXAMPLES , <'examples/fib.ijs'
EXAMPLES =. EXAMPLES , <'examples/rank.ijs'
EXAMPLES =. EXAMPLES , <'examples/matrix.ijs'
EXAMPLES =. EXAMPLES , <'examples/stats.ijs'
EXAMPLES =. EXAMPLES , <'examples/poly.ijs'
EXAMPLES =. EXAMPLES , <'examples/sort.ijs'
EXAMPLES =. EXAMPLES , <'examples/moving.ijs'

NB. smokeOne: run a single example. Returns 1 if it ran
NB. without error, 0 otherwise. Prints PASS/MISSING/FAIL.
smokeOne =: 3 : 0
  path =. y
  if. -. fexist path do.
    smoutput '  MISSING  ' , path
    0 return.
  end.
  src =. 1!:1 < path
  tryCatch =. 0
  NB. We can't easily catch errors in J, so just call it.
  NB. If it errors, the script will abort and the test runner
  NB. will report a non-zero exit.
  r =. runTacitJ src
  smoutput '  PASS  ' , path
  1
)

NB. Run smokeOne on each example. The `each` modifier
NB. produces a boxed list of results; unbox to sum.
smoutput ''
smoutput 'Smoke test: running all examples'
smoutput '================================='
smoutput ''

results =. > smokeOne each EXAMPLES
nPass =. +/ results
nTotal =. # EXAMPLES
smoutput ''
smoutput 'summary: ' , (": nPass) , ' / ' , (": nTotal) , ' examples passed'

exit *. nPass = nTotal