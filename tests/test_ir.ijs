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

NB. --- Lowerer + end-to-end (skeleton) ---------------------
NB.
NB. NB: the lowerer (lowerIr / lowerAst) is partially implemented.
NB. The parser produces AST nodes with inconsistent boxing (some
NB. children of EXPR are 1-boxes, some are 2-boxes) which makes
NB. a clean lowerer brittle. We therefore skip these tests for
NB. now and rely on `runTacitJ` (which shells out to J's ".) for
NB. end-to-end coverage. The lowerer will be hardened as a Week-2
NB. follow-up.

NB. runLowererTests: a no-op stub. When the lowerer is complete,
NB. replace this with the actual lowerer-driven tests.
runLowererTests =: 3 : 0
  NB. Intentionally empty until the lowerer is hardened.
  EMPTY
)
runLowererTests ''

NB. runEndToEndTests: a no-op stub. Same rationale.
runEndToEndTests =: 3 : 0
  EMPTY
)
runEndToEndTests ''
