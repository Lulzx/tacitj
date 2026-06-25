NB. ============================================================
NB. codegen.ijs - TacitJ Code Generator
NB. ============================================================
NB. Emits J source from the IR and provides file-output utilities
NB. for the bootstrap stages. The Stage 0 emitter generates
NB. human-readable J source; future stages will add a bytecode
NB. emitter (J bytecode via 9!:) or C backend.
NB.
NB. The top-level `emitIr` verb unparses the IR to a J source
NB. string. `emitFile` writes it to a path. `compileFile` is
NB. the end-to-end: source file -> IR -> emit -> J execution.
NB.
NB. For the bootstrap, `emitTacitJ` produces a standalone .ijs
NB. from a given IR, suitable for `0!:101`.

load 'src/ir.ijs'

NB. emitProg: emit a full program (J source, one line per stmt).
NB. y = IR_PROG node
NB. Result = char vector
emitProg =: 3 : 0
  prog =. y
  stmts =. > irArgs prog
  ns =. # stmts
  if. ns = 0 do. '' return. end.
  first =. unparseIr 0 { stmts
  rest =. }. stmts
  if. 0 = # rest do. first return. end.
  first , LF , emitSeqRest rest
)

NB. emitSeqRest: tail of a program (recursive).
emitSeqRest =: 3 : 0
  stmts =. y
  if. 0 = # stmts do. '' return. end.
  first =. unparseIr 0 { stmts
  rest =. }. stmts
  if. 0 = # rest do. first return. end.
  first , LF , emitSeqRest rest
)

NB. emitIr: emit J source from any IR node.
NB. y = IR node
NB. Result = char vector
emitIr =: 3 : 0
  ir =. y
  op =. irOp ir
  if. op = IR_PROG do. emitProg ir return. end.
  unparseIr ir
)

NB. emitFile: write IR as J source to a file path.
NB. y = (ir ; path)
NB. Result = 0 (success) or error
emitFile =: 3 : 0
  'ir path' =. y
  if. ir -: <a: do. 1 return. end.
  src =. emitIr ir
  if. 0 = # src do. 1 return. end.
  src 1!:2 < path
  0
)

NB. compileFile: read a TacitJ source file, compile via the full
NB. pipeline (lex->parse->sem->lowerIr->opt), emit J source, and
NB. write to an output path. Does NOT execute.
NB. y = (src-path ; out-path)
NB. Result = 0 on success, error code on failure
compileFile =: 3 : 0
  'srcPath outPath' =. y
  if. -. fexist srcPath do. 1 return. end.
  src =. 1!:1 < srcPath
  ir =. optWithEnv lowerIr semAnalyze parseProgram lex src
  emitFile ir ; outPath
)

NB. execSource: execute a J source string via 0!:1.
NB. Returns the result (the last expression value, or a:).
NB. Wraps the source so r is assigned, then returns it.
NB. y = char vector of J source
execSource =: 3 : 0
  src =. y
  if. 0 = # src do. a: return. end.
  tmpf =. '/tmp/tacitj_src.ijs'
  wrapped =. 'r =: ' , src , LF , 'r'
  wrapped 1!:2 < tmpf
  0!:1 < tmpf
  r [ smoutput r
)

NB. runCompile: compile and execute. Convenience verb.
NB. y = source char vector
NB. Result = execution result
NB. 0!:1 executes and sets `r` in the caller's namespace (return is void).
NB. We capture r and return it after printing.
runCompile =: 3 : 0
  src =. y
  ir =. optWithEnv lowerIr semAnalyze parseProgram lex src
  jsrc =. emitIr ir
  if. 0 = # jsrc do. a: return. end.
  tmpf =. '/tmp/tacitj_exec.ijs'
  wrapped =. 'r =: ' , jsrc , LF , 'r'
  wrapped 1!:2 < tmpf
  0!:1 < tmpf
  r [ smoutput r
  r [ smoutput r
)
