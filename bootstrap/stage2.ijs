NB. ============================================================
NB. stage2.ijs - Stage 2 bootstrap (planned)
NB. ============================================================
NB. Stage 2 takes the same source as Stage 1 but with increasing
NB. tacit density. The goal is to demonstrate that the same
NB. program can be written in progressively more compact tacit
NB. style, with the optimizer still able to produce the same
NB. output.
NB.
NB. Status: planned.
NB.
NB. To run Stage 2 once it's wired up:
NB.   jconsole bootstrap/stage2.ijs SRC=src/tacitj.ijs OUTFILE=bin/stage2.ijs
NB.
NB. The current Stage 0 source in src/ is already a mix of
NB. tacit and explicit verbs. A future refactor (Stage 2) will:
NB.
NB.   1. Re-express each pass as a tacit composition where possible.
NB.   2. Keep the same public API (compile, lex, parse, etc.)
NB.      so Stage 1 == Stage 2 == Stage 3 by API contract.
NB.   3. Add a verification step that diffs Stage 1 vs Stage 2
NB.      output on a fixed canary input.

NB. This file is a stub. It loads Stage 0 and prints a status
NB. message; it does NOT yet refactor anything.

load 'bootstrap/stage0.ijs'

stage2Run =: 3 : 0
  if. 0 = nc <'compile' do.
    smoutput 'stage2: FATAL compile not defined after loading stage0'
    1 return.
  end.
  smoutput 'stage2: STUB - not yet implemented'
  smoutput '  current source already mixes tacit + explicit'
  smoutput '  planned: refactor to higher tacit density, verify'
  smoutput '  same canary output as Stage 1'
  rc =. selfhost0 ''
  smoutput '  stage0 canary still = ' , tacitj0 ''
  rc = 0
)

exit stage2Run ''
