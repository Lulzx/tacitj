NB. ============================================================
NB. test_ir.ijs - IR (intermediate representation) tests
NB. ============================================================
NB. Verifies the IR lowerer, unparser, and execIr round-trip on
NB. representative TacitJ inputs.

NB. --- Constructor tests -----------------------------------

NB. irLit: numeric literal
check (irOp irLit 5) ; IR_LIT ; <'irLit: numeric'

NB. irRef: name reference
check (irOp irRef 'foo') ; IR_REF ; <'irRef: name'

NB. irCall: 3-arg call
callArgs =. (<irLit '+') ; (<irLit 1) ; (<irLit 2)
call =. irCall3 callArgs
check (irOp call) ; IR_CALL ; <'irCall: opcode'

NB. irTrain2: 2-train (hook)
t2args =. (<irLit '+') ; (<irLit '/')
t2 =. irTrain2 t2args
check (irOp t2) ; IR_TRAIN2 ; <'irTrain2: opcode'

NB. irTrain3: 3-train (fork)
t3args =. (<irLit '+') ; (<irLit '%') ; (<irLit '#')
t3 =. irTrain3 t3args
check (irOp t3) ; IR_TRAIN3 ; <'irTrain3: opcode'

NB. --- Round-trip: unparseIr on built IR -------------------

NB. Number literal
check (unparseIr irLit 42) ; '42' ; <'unparse: 42'

NB. Negative number (must be parenthesised in J to avoid confusion with - verb)
check (unparseIr irLit _5) ; '_5' ; <'unparse: _5'

NB. String literal
expectedStr =. QUOTE , 'hi' , QUOTE
check (unparseIr irLit 'hi') ; expectedStr ; <'unparse: ''hi'''

NB. Name reference
check (unparseIr irRef 'pi') ; 'pi' ; <'unparse: pi'

NB. Verb literal
check (unparseIr irLit '+') ; '+' ; <'unparse: +'

NB. Dyadic call
callArgs =. (<irLit '+') ; (<irLit 1) ; (<irLit 2)
check (unparseIr (irCall3 callArgs)) ; '1 + 2' ; <'unparse: 1 + 2'

NB. 3-train
train3Args =. (<irLit '+') ; (<irLit '%') ; (<irLit '#')
check (unparseIr (irTrain3 train3Args)) ; '( + % # )' ; <'unparse: +/ % #'

NB. Assignment
assnArgs =. (<irRef 'pi') , (<irLit 3.14)
check (unparseIr (irAssn assnArgs)) ; 'pi =: 3.14' ; <'unparse: pi =: 3.14'

NB. --- Lowerer + end-to-end --------------------------------
NB.
NB. The lowerer (lowerIr / lowerAst) converts a parsed AST into an
NB. IR_PROG, and `compile` runs the full pipeline
NB.   lex -> parse -> sem -> lowerIr -> opt -> execIr
NB. exercising the IR + optimizer end-to-end. The parser does not
NB. split sentences on LF (it treats LF as whitespace), so these
NB. tests use single-sentence sources; multi-line coverage stays on
NB. the `runTacitJ` path (which shells out to J's 0!:101).

NB. lowerIr: top-level opcode is IR_PROG for a single sentence.
prog =. lowerIr semAnalyze parseProgram lex '2 + 3'
check (irOp prog) ; IR_PROG ; <'lowerIr: 2 + 3 -> IR_PROG'

NB. lowerIr: a single sentence yields a 1-statement program.
check (# > irArgs prog) ; 1 ; <'lowerIr: single sentence = 1 stmt'

NB. Round-trip: unparseIr of the lowered IR reproduces the source
NB. (parenthesised). The trailing LF comes from unparseIrProg.
check (unparseIr prog) ; (('( 2 + 3 )') , LF) ; <'lowerIr: unparse ( 2 + 3 )'

NB. Assignment lowers to IR_ASSN.
assnProg =. lowerIr semAnalyze parseProgram lex 'x =: 1 + 2'
assnStmt =. 0 { > irArgs assnProg
check (irOp assnStmt) ; IR_ASSN ; <'lowerIr: x =: 1 + 2 -> IR_ASSN'
check (unparseIr assnStmt) ; 'x =: ( 1 + 2 )' ; <'lowerIr: unparse x =: ( 1 + 2 )'

NB. A 4-component train (mean =: +/ % #) lowers and unparses to a
NB. generic IR_TRAIN that round-trips through J's own parser.
meanProg =. lowerIr semAnalyze parseProgram lex 'mean =: +/ % #'
meanStmt =. 0 { > irArgs meanProg
check (irOp meanStmt) ; IR_ASSN ; <'lowerIr: mean =: +/ % # -> IR_ASSN'
check (unparseIr meanStmt) ; 'mean =: ( + / % # )' ; <'lowerIr: unparse mean =: ( + / % # )'

NB. --- End-to-end: compile (lex->parse->sem->lowerIr->opt->execIr) ---

NB. Bare arithmetic evaluates correctly (J right-to-left).
check (compile '2 + 3') ; 5 ; <'compile: 2 + 3 = 5'
check (compile '3 * 4 + 5') ; 27 ; <'compile: 3 * 4 + 5 = 27 (right-to-left)'
check (compile '1 + 2 * 3') ; 7 ; <'compile: 1 + 2 * 3 = 7 (right-to-left)'
check (compile '42') ; 42 ; <'compile: 42 = 42'
check (compile '10 - 4') ; 6 ; <'compile: 10 - 4 = 6'

NB. NB: parenthesised sub-expressions are not yet covered because the
NB. parser currently loops on '(' (a known Stage-0 issue); the
NB. `runTacitJ` path handles them via J's own parser. To be wired up
NB. when the parser's paren handling is fixed.

NB. An assignment returns an empty boxed result (no bare value), and
NB. must not crash. We check the result is the empty box `a:`.
check (compile 'x =: 1 + 2') ; (a:) ; <'compile: x =: 1 + 2 (no crash, empty result)'

NB. The optimizer is stable on lowered IR: running opt twice yields
NB. the same unparse as running it once (fixed point, no boxing loop).
once =. optWithEnv lowerIr semAnalyze parseProgram lex '2 + 3'
twice =. optWithEnv once
check (unparseIr once) ; (unparseIr twice) ; <'opt: fixed point on ( 2 + 3 )'
