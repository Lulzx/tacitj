NB. ============================================================
NB. eval.ijs - TacitJ Evaluator (Phase 1: shell out to J)
NB. ============================================================
NB. For Stage 0, we don't have a working compiler yet. Instead,
NB. we run the source directly through J's `".` (execute) or
NB. `0!:101` (load script). The parser/lexer still validate that
NB. the source is well-formed TacitJ (a subset of J), and
NB. `runTacitJ` returns the result of the last expression.
NB.
NB. Stages 1+ replace this with a real AST -> bytecode/C codegen.

NB. isMultiLine: does the source have more than one top-level sentence?
NB. y = source char vector
NB. Result = 0 or 1
isMultiLine =: 3 : 0
  src =. y
  depth =. 0
  for_i. i. # src do.
    c =. i { src
    if. c = '(' do. depth =. >: depth end.
    if. c = ')' do. depth =. <: depth end.
    if. (c = LF) *. depth = 0 do.
      1 return.
    end.
  end.
  0
)

NB. runTacitJ: lex (validate) + execute via J
NB. y = source char vector
NB. Result = boxed result of the last expression (or a: if no
NB. bare expression)
NB. NB: We lex for validation but do not parse in Phase 0 (the parser
NB. has known bugs on certain inputs; see TODO). For Phase 0, we trust
NB. the lexer to catch obvious errors and use J's `".` or `0!:101` to
NB. run the source. Stages 1+ will replace this with a real AST-driven
NB. codegen.
runTacitJ =: 3 : 0
  src =. y
  NB. Validate by lexing (catches obvious errors)
  toks =. lex src
  NB. Execute: use ". for single line, 0!:101 for multi-line
  if. isMultiLine src do.
    NB. Write to a temp file and load
    tmpf =. '/tmp/tacitj_run.ijs'
    src 1!:2 < tmpf
    0!:101 < tmpf
    a:
  else.
    ". src
  end.
)
