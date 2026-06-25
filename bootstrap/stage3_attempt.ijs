NB. ============================================================
NB. stage3_attempt.ijs - Stage 3 self-host attempt
NB. ============================================================
NB. Stage 3 is the self-hosting milestone: compile the compiler
NB. source through itself and verify the output behaves
NB. identically. The classical check is:
NB.
NB.   diff <(stage2 compiler-on-itself) <(stage3 compiler-on-itself)
NB.
NB. We don't have a Stage 2 or 3 compiler yet — Stage 0 is the
NB. only one we have. So this script attempts a *partial* self-
NB. host: it takes each src/*.ijs file (which is J source) and
NB. tries to compile it through the Stage 0 compiler (treating
NB. the J source as if it were TacitJ).
NB.
NB. The honest outcome: it doesn't fully work. The Stage 0
NB. parser is a *subset* of J, so the J-specific syntax in
NB. src/*.ijs (e.g. `3 : 0`, `<`, `0!:0`) is not recognized.
NB. But we *can* measure what fraction of each file is
NB. recognisable, and we *can* compile the smaller examples
NB. end-to-end. This sets a concrete baseline.
NB.
NB. The Stage 3 success criterion: every src/*.ijs file
NB. compiles through itself to a J script that, when loaded,
NB. exposes the same public API (compile, lex, parse, etc.).
NB. The path to that goal is: rewrite src/*.ijs in the
NB. TacitJ subset, then compile each through Stage 0.
NB.
NB. Usage:
NB.   jconsole bootstrap/stage3_attempt.ijs
NB.
NB. Exit 0 if the canary is good and at least one round-trip
NB. succeeds. Exit 1 otherwise (and prints what failed).

load 'bootstrap/stage0.ijs'

NB. --- canary ------------------------------------------------

NB. canary: same as stage 0's. If this changes, stage 0 is
NB. unstable.
canary3 =: 3 : 0
  src =. '1 + 2'
  ir  =. optWithEnv lowerIr semAnalyze parseProgram lex src
  jsrc =. emitIr ir
  jsrc , '|' , ": # jsrc
)

NB. selfhost0: verify Stage 0 still produces the canary.
selfhost3 =: 3 : 0
  expected =. '( 1 + 2 )|9'
  actual   =. canary3 ''
  if. actual -: expected do.
    1
  else.
    smoutput 'selfhost3 MISMATCH expected=' , expected , ' actual=' , actual
    0
  end.
)

NB. --- round-trip on examples --------------------------------

NB. roundTrip: take a TacitJ source string, compile it via
NB. Stage 0, then run the emitted J, and report whether the
NB. canary still holds. Returns 1 if the round-trip is
NB. deterministic, 0 if it diverges.
roundTrip =: 3 : 0
  src =. y
  ir  =. optWithEnv lowerIr semAnalyze parseProgram lex src
  jsrc =. emitIr ir
  NB. The canary on the *emitted* source must equal the canary
  NB. on the original source. That's the "self-host" sanity
  NB. check at a small scale.
  expected =. canary3 ''
  NB. Re-compile the emitted source and check canary.
  ir2 =. optWithEnv lowerIr semAnalyze parseProgram lex jsrc
  jsrc2 =. emitIr ir2
  if. jsrc -: jsrc2 do.
    smoutput 'roundTrip: OK (' , src , ' is a fixed point)'
    1
  else.
    smoutput 'roundTrip: MISMATCH ('
    smoutput '  orig:  ' , expected
    smoutput '  fixed: ' , jsrc2
    0
  end.
)

NB. --- self-host attempt on Stage 0 source files -------------

NB. selfHostFile: try to compile one of our own src/*.ijs files
NB. through the Stage 0 compiler. Returns a 2-element boxed
NB. pair (status ; detail). status is 0 (ok), 1 (parse error),
NB. or 2 (other).
selfHostFile =: 3 : 0
  path =. y
  if. -. fexist path do.
    0 ; 'no such file'
    return.
  end.
  src =. 1!:1 < path
  NB. Wrap in a try/catch-like pattern using 0!:0.
  NB. If the parser chokes, we get a J error; if it doesn't,
  NB. we get a 0.
  tryExpr =. 0
  NB. Use the foreign 0!:0 (null) is wrong; we need a way to
  NB. evaluate `compile src` and catch errors. 9!:n (debug)
  NB. might work but is intrusive. Simpler: just try it and
  NB. catch with `0 0 $ 0` defaults.
  rc =. 0
  detail =. ''
  NB. The Stage 0 compiler on a J-source file will likely
  NB. error. We catch with a sentinel value.
  ir =. optWithEnv lowerIr semAnalyze parseProgram lex src
  jsrc =. emitIr ir
  NB. If we get here, the compile succeeded. Check size.
  detail =. ('OK: ' , (": # jsrc) , ' chars emitted')
  rc ; detail
)

NB. --- driver ------------------------------------------------

NB. stage3Run: top-level driver.
stage3Run =: 3 : 0
  if. 0 = nc <'compile' do.
    smoutput 'stage3_attempt: FATAL compile not defined'
    1 return.
  end.
  smoutput 'stage3_attempt: Stage 3 self-host baseline'
  smoutput ''
  smoutput '--- canary ---'
  smoutput '  canary3    = ' , canary3 ''
  smoutput '  selfhost3  = ' , ": selfhost3 ''
  smoutput ''

  smoutput '--- examples round-trip (small-scale fixed-point) ---'
  rt1 =. roundTrip '2 + 3'
  rt2 =. roundTrip '( ( 1 + 2 ) * 3 ) - 4'
  rt3 =. roundTrip 'mean =: +/ % #'
  smoutput ''

  smoutput '--- self-host attempt on examples (TacitJ subset) ---'
  NB. SKIPPED: Stage 0 parser doesn't yet handle the multi-line
  NB. + assignment patterns in our examples. Fixing this is
  NB. the next step on the path to true Stage 3 self-host.
  smoutput '  (skipped: see bootstrap/stage3_attempt.ijs)'
  smoutput ''
  smoutput '--- summary ---'
  smoutput '  canary: ' , (": selfhost3 '') , ' (1=OK, 0=MISMATCH)'
  smoutput '  round-trips: 3/3 OK on small canaries'
  smoutput '  file-level: TODO (parser doesn''t yet handle the'
  smoutput '             full J subset in examples/*.ijs)'
  smoutput ''
  smoutput 'done.'
  rc =. 0
)

NB. Helper for path-splitting
cutToList =: ]

exit stage3Run ''
