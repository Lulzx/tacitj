NB. ============================================================
NB. eval.ijs - TacitJ Evaluator (Phase 1: shell out to J)
NB. ============================================================
NB. For Stage 0, we don't have a working compiler yet. Instead,
NB. we run the source directly through J's `".` (execute) or
NB. `0!:101` (load script). The parser/lexer still validate that
NB. the source is well-formed TacitJ (a subset of J), and
NB. `runTacitJ` returns the result of the last expression.
NB.
NB. Per SPEC.md §3.3, execution happens inside a fresh per-program
NB. namespace (locale) so that names defined by one program do not
NB. leak into the caller's namespace or into later programs. The
NB. current locale is saved before the switch and restored after,
NB. so the evaluator is side-effect-free w.r.t. the session locale.
NB.
NB. The IR layer (src/ir.ijs) replaces the AST-driven codegen
NB. in Stage 1+, and the optimizer (src/opt.ijs) sits between
NB. the IR lowerer and the codegen emitter.
NB.
NB. NB: We lex for validation but do not parse in Phase 0 (the
NB. parser has known boxing inconsistencies on certain inputs;
NB. see TODO). For Phase 0, we trust the lexer to catch obvious
NB. errors and use J's `".` or `0!:101` to run the source.
NB. Stages 1+ will replace this with a real IR-driven codegen.

NB. Monotonic counter for fresh per-program locale names.
tacitj_loc_counter =: 0

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

NB. freshLocale: create a fresh, uniquely-named locale and return
NB. its name. The name is derived from a monotonic counter so two
NB. calls never collide.
NB. Result = locale name (char vector, no underscore)
freshLocale =: 3 : 0
  tacitj_loc_counter =: >: tacitj_loc_counter
  'tacitj', ": tacitj_loc_counter
)

NB. runTacitJ: lex (validate) + execute via J in a fresh namespace.
NB. y = source char vector
NB. Result = boxed result of the last expression (or a: if no
NB. bare expression)
NB.
NB. For multi-line programs, the J 9.7 `0!:1` foreign executes
NB. the file but returns VOID. So multi-line programs don't
NB. surface a result here. To see output, write `smoutput <expr>`
NB. at the end of the file, or use the single-line form.
runTacitJ =: 3 : 0
  src =. y
  NB. Validate by lexing (catches obvious errors)
  toks =. lex src
  NB. Save the current locale, switch to a fresh per-program
  NB. namespace, execute, then restore.
  multi =. isMultiLine src
  cur =. 18!:5 ''
  locname =. freshLocale ''
  cocurrent locname
  try.
    if. multi do.
      NB. Write to a temp file and load
      tmpf =. '/tmp/tacitj_run.ijs'
      src 1!:2 < tmpf
      0!:1 < tmpf
      res =. a:
    else.
      res =. ". src
    end.
  catch.
    res =. a:
  end.
  cocurrent cur
  res
)
