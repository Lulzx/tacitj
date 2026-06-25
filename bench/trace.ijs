NB. ============================================================
NB. trace.ijs - Pipeline trace demo
NB. ============================================================
NB. Runs a sample program through each stage of the compiler
NB. pipeline and prints the output of each stage. Useful for
NB. understanding the architecture and for debugging.
NB.
NB. Run with:
NB.   jconsole bench/trace.ijs
NB.   make trace

load 'src/lex.ijs'
load 'src/parse.ijs'
load 'src/sem.ijs'
load 'src/ir.ijs'
load 'src/opt.ijs'
load 'src/codegen.ijs'
load 'src/tacitj.ijs'

NB. --- The sample program ------------------------------

NB. A small but interesting program: sum of squares of 1..5.
NB. Uses a 3-train (sum, divide, count) and a 2-char verb (*:).
SAMPLE =: 'mean =: +/ % #' , LF , 'smoutput mean 1 2 3 4 5'

NB. --- The trace -------------------------------------------

NB. show: print a labeled value, truncated for readability.
show =: 3 : 0
  label =. 0 { y
  val   =. > 1 { y
  smoutput '----- '
  smoutput label
  smoutput ' -----'
  NB. Truncate very long outputs to keep the trace readable.
  s =. ": val
  if. 200 < # s do.
    smoutput (200 {. s) , '  ... [truncated]'
  else.
    smoutput s
  end.
)

NB. runTrace: print each stage's output for SAMPLE.
NB. Result = 0 (success) or 1 (error).
runTrace =: 3 : 0
  src =. SAMPLE
  smoutput 'TacitJ pipeline trace'
  smoutput '===================='
  smoutput ''
  smoutput 'Source:'
  smoutput src
  smoutput ''

  show '1. Lexer output' ; lex src

  toks =. lex src
  show '2. Parser (AST)' ; semAnalyze parseProgram toks

  ast =. semAnalyze parseProgram toks
  show '3. IR (unoptimized)' ; unparseIr lowerAst ast

  ir =. lowerAst ast
  smoutput '----- 4. Optimized IR -----'
  smoutput unparseIr ir

  optIr =. optWithEnv ir
  smoutput '----- 5. After optimizer -----'
  smoutput unparseIr optIr

  smoutput '----- 6. Emitted J source -----'
  smoutput emitIr optIr

  smoutput ''
  smoutput '----- 7. Execution (via 0!:0 on temp file) -----'
  tmpf =. '/tmp/tacitj_trace.ijs'
  (emitIr optIr) 1!:2 < tmpf
  0!:0 < tmpf
  0
)

exit runTrace ''