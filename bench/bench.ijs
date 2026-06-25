NB. ============================================================
NB. bench.ijs - TacitJ benchmark suite
NB. ============================================================
NB. Measures the time and output size of the compile pipeline
NB. on a fixed set of canary inputs. Run via:
NB.
NB.   jconsole bench/bench.ijs
NB.   make bench
NB.
NB. Output is a fixed-width table:
NB.   case              | compile-ms | out-chars | exec-ms | result
NB.   ------------------+------------+-----------+---------+-------
NB.   <name>            | <ms>       | <chars>   | <ms>    | <r>
NB.
NB. Goal: track regressions as the compiler grows, and compare
NB. Stages 0 / 1 / 2 / 3 output sizes on the same canary.

load 'src/lex.ijs'
load 'src/parse.ijs'
load 'src/sem.ijs'
load 'src/ir.ijs'
load 'src/opt.ijs'
load 'src/eval.ijs'
load 'src/codegen.ijs'
load 'src/tacitj.ijs'

NB. --- benchmark cases ---------------------------------------
NB. Each case is a boxed pair (name ; source).
NB. NB: LF is whitespace in J, so multi-line source where the
NB. second line should be a separate sentence is NOT supported
NB. by the current parser. Stick to single-statement programs
NB. (or single-statement-with-parens) here.
NB. Defined with =: (global) so explicit verbs can see it.
cases =: <(<'arith_2_plus_3')  ; <'2 + 3'
cases =: cases , <(<'identity_42')    ; <'42'
cases =: cases , <(<'mean_5')         ; <'+/ % # 1 2 3 4 5'
cases =: cases , <(<'paren_chain')    ; <'( ( 1 + 2 ) * 3 ) - 4'
cases =: cases , <(<'nested_arith')   ; <'( ( ( 1 + 2 ) * 3 ) - 4 ) % 5'
cases =: cases , <(<'assign_only')    ; <'x =: 1 + 2'
cases =: cases , <(<'train_3_assign') ; <'mean =: +/ % #'
cases =: cases , <(<'big_expr')       ; <'( ( ( ( 1 + 2 ) * 3 ) + ( 4 * 5 ) ) - 6 ) % 7'

NB. --- timing helper -----------------------------------------

NB. timeIt: invoke f on y once, return ms elapsed.
timeIt =: 4 : 0
  t0 =. 6!:1 ''
  z =. x y
  t1 =. 6!:1 ''
  NB. We can't return both z and t1-t0 from x y, so use a global.
  NB. Caller is expected to use `result` and `elapsed` below.
  result =. z
  elapsed =. 1000 * t1 - t0
  0
)

NB. --- one case, all metrics ---------------------------------

NB. benchOne: time the full pipeline on a single case.
NB. y = boxed pair (name ; source). Each field is 1-boxed.
NB. Returns a char-vec row ready to print.
benchOne =: 3 : 0
  y2 =. > y                  NB. unbox the outer 1-box to get the 2-element list
  'nameBox srcBox' =. y2      NB. destructure: each is 1-boxed
  name =. > nameBox           NB. unbox to get the char vec
  src  =. > srcBox

  NB. --- compile phase
  t0 =. 6!:1 ''
  ir =. optWithEnv lowerIr semAnalyze parseProgram lex src
  jsrc =. emitIr ir
  t1 =. 6!:1 ''
  compileMs =. 1000 * t1 - t0

  NB. --- exec phase (run the emitted J source as a string)
  t0 =. 6!:1 ''
  resetOptEnv ''
  r =. 0!:0 jsrc
  t1 =. 6!:1 ''
  execMs =. 1000 * t1 - t0

  NB. --- format the row
  NB. Pad name to 16 chars, then " | " (3) + compile (8) + " | "
  NB. + jsrc len (9) + " | " + exec (7) + " | " + result.
  NB. NB: an empty result (0x0 char) would 2D-ify the whole row,
  NB. so substitute a placeholder if needed.
  pad =. (16 - # name) $ ' '
  result =. ": r
  if. 0 = # , result do.
    result =. '(empty)'   NB. placeholder for 0x0 results
  end.
  row =. name , pad , ' | ' , (8 ": compileMs) , ' | ' , (9 ": # jsrc) , ' | ' , (7 ": execMs) , ' | ' , result
  row
)

NB. --- driver ------------------------------------------------

NB. benchRun: print header, then one row per case.
benchRun =: 3 : 0
  hdr =. 'TacitJ benchmark'
  smoutput hdr
  smoutput '================='
  smoutput ''
  smoutput 'case              | compile-ms | out-chars | exec-ms | result'
  smoutput '------------------+------------+-----------+---------+-------'
  n =. # cases
  i =. 0
  while. i < n do.
    row =. benchOne i { cases
    smoutput row
    i =. >: i
  end.
  smoutput ''
  smoutput ('cases=' , ": n) , '  done.'
  0
)

NB. Force a noun result for the verb.
NB. The while loop body doesn't produce a noun, so the last
NB. expression is the smoutput on the summary line. We add
NB. an explicit `0` to make the function's result unambiguous.
runBench =: 3 : 0
  rc =. benchRun ''
  rc
)

exit runBench ''
