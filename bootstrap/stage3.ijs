NB. ============================================================
NB. stage3.ijs - Stage 3 bootstrap (planned)
NB. ============================================================
NB. Stage 3 is the self-hosting milestone: the compiler source
NB. compiled by itself produces a binary/bytecode image that
NB. behaves identically to Stages 1 and 2.
NB.
NB. Verification:
NB.   diff bin/stage1.ijs  bin/stage3.ijs   NB. API contract
NB.   diff bin/stage2.ijs  bin/stage3.ijs   NB. canary output
NB.   checksum(Stage 3 source) == checksum(Stage 3 on itself)
NB.
NB. Status: planned.
NB.
NB. To run Stage 3 once it's wired up:
NB.   jconsole bootstrap/stage3.ijs SRC=src/tacitj.ijs OUTFILE=bin/stage3.ijs
NB.   diff bin/stage1.ijs bin/stage3.ijs
NB.
NB. Prerequisites:
NB.   - Stage 1 must be working (it is).
NB.   - Stage 2 must be working (planned).
NB.   - A self-host check must compare Stage 3's output on the
NB.     Stage 3 source against Stage 2's output on the same source.

NB. This file is a stub. It loads Stage 0 and prints the plan.

load 'bootstrap/stage0.ijs'

stage3Run =: 3 : 0
  if. 0 = nc <'compile' do.
    smoutput 'stage3: FATAL compile not defined after loading stage0'
    1 return.
  end.
  smoutput 'stage3: STUB - self-hosting not yet achieved'
  smoutput '  '
  smoutput '  plan:'
  smoutput '    1. Stage 1 must compile TacitJ source (DONE)'
  smoutput '    2. Stage 2 refactors to higher tacit density (TODO)'
  smoutput '    3. Stage 3 = full tacit source compiled by Stage 2 (TODO)'
  smoutput '    4. Verify diff(stage2_emit, stage3_emit) == "" on canary'
  rc =. selfhost0 ''
  rc = 0
)

exit stage3Run ''
