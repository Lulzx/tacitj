NB. ============================================================
NB. stage0_run.ijs - One-shot Stage 0 loader + smoke test
NB. ============================================================
NB. Loads stage0 (which is the canonical Stage 0 compiler) and
NB. runs the selfhost check. Exits 0 on success, 1 on failure.
NB.
NB. Use:
NB.   jconsole bootstrap/stage0_run.ijs
NB.
NB. This is what CI runs as `make stage0`. The module form
NB. (stage0.ijs) is what other stages import.

load 'bootstrap/stage0.ijs'

stage0Run =: 3 : 0
  if. 0 = nc <'compile' do.
    smoutput 'stage0: FATAL compile not defined after loading src/'
    1 return.
  end.
  smoutput 'stage0 loaded.'
  smoutput '  canary    = ' , tacitj0 ''
  rc =. selfhost0 ''
  smoutput '  selfhost0 = ' , ": rc
  rc = 0
)

exit stage0Run ''
