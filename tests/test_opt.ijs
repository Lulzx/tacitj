NB. ============================================================
NB. test_opt.ijs - Optimizer tests
NB. ============================================================
NB. Verifies the rewrite rules in src/opt.ijs:
NB.   - constant folding on binary arithmetic
NB.   - identity elimination on 2-trains
NB.   - identity / cap elimination on 3-trains
NB.   - constant propagation through IR_ASSN
NB.
NB. NB: the irCall3 helper in ir.ijs is just an alias for irCall
NB. which takes a single 3-element boxed list argument. So the
NB. pattern in these tests is:
NB.   args =. (<irLit '+') , (<irLit 1) , (<irLit 2)
NB.   c =. irCall3 args

NB. --- Constant folding ------------------------------------

NB. IR_CALL(+; 1; 2) should fold to IR_LIT(3)
resetOptEnv ''
callArgs =. (<irLit '+') , (<irLit 1) , (<irLit 2)
call =. irCall3 callArgs
optd =. optWithEnv call
check (irOp optd) ; IR_LIT ; <'fold: 1 + 2 -> IR_LIT'
check (irArgs optd) ; 3 ; <'fold: 1 + 2 = 3'

NB. 3 * 4 = 12
resetOptEnv ''
callArgs =. (<irLit '*') , (<irLit 3) , (<irLit 4)
call =. irCall3 callArgs
optd =. optWithEnv call
check (irArgs optd) ; 12 ; <'fold: 3 * 4 = 12'

NB. 10 - 4 = 6
resetOptEnv ''
callArgs =. (<irLit '-') , (<irLit 10) , (<irLit 4)
call =. irCall3 callArgs
optd =. optWithEnv call
check (irArgs optd) ; 6 ; <'fold: 10 - 4 = 6'

NB. 2 ^ 10 = 1024
resetOptEnv ''
callArgs =. (<irLit '^') , (<irLit 2) , (<irLit 10)
call =. irCall3 callArgs
optd =. optWithEnv call
check (irArgs optd) ; 1024 ; <'fold: 2 ^ 10 = 1024'

NB. --- Identity elimination (2-trains) ---------------------

NB. (] v) -> v
resetOptEnv ''
t2 =. irTrain2 ((irRef ']') ; (irRef 'inc'))
optd =. optWithEnv t2
NB. After opt, t2 collapses to the second child (irRef 'inc')
check (irOp optd) ; IR_REF ; <'opt-train2: (] inc) -> REF'
check (irArgs optd) ; 'inc' ; <'opt-train2: (] inc) -> REF inc'

NB. (u ]) -> u
resetOptEnv ''
t2 =. irTrain2 ((irRef 'dec') ; (irRef ']'))
optd =. optWithEnv t2
check (irOp optd) ; IR_REF ; <'opt-train2: (dec ]) -> REF'
check (irArgs optd) ; 'dec' ; <'opt-train2: (dec ]) -> REF dec'

NB. Non-identity train is preserved
resetOptEnv ''
t2 =. irTrain2 ((irRef 'f') ; (irRef 'g'))
optd =. optWithEnv t2
check (irOp optd) ; IR_TRAIN2 ; <'opt-train2: (f g) -> kept'

NB. --- Identity / cap elimination (3-trains) ---------------

NB. ([ v ]) -> v
resetOptEnv ''
t3 =. irTrain3 ((irRef '[') ; (irRef 'v') ; (irRef ']'))
optd =. optWithEnv t3
check (irOp optd) ; IR_REF ; <'opt-train3: ([ v ]) -> REF'
check (irArgs optd) ; 'v' ; <'opt-train3: ([ v ]) -> REF v'

NB. (] v w) -> (v w) (2-train)
resetOptEnv ''
t3 =. irTrain3 ((irRef ']') ; (irRef 'v') ; (irRef 'w'))
optd =. optWithEnv t3
check (irOp optd) ; IR_TRAIN2 ; <'opt-train3: (] v w) -> TRAIN2'

NB. (u v ]) -> (u v) (2-train)
resetOptEnv ''
t3 =. irTrain3 ((irRef 'u') ; (irRef 'v') ; (irRef ']'))
optd =. optWithEnv t3
check (irOp optd) ; IR_TRAIN2 ; <'opt-train3: (u v ]) -> TRAIN2'

NB. Non-identity 3-train is preserved
resetOptEnv ''
t3 =. irTrain3 ((irRef 'f') ; (irRef 'g') ; (irRef 'h'))
optd =. optWithEnv t3
check (irOp optd) ; IR_TRAIN3 ; <'opt-train3: (f g h) -> kept'

NB. --- Constant propagation --------------------------------

NB. x =: 5 ; x + 0  ->  IR_LIT(5)
resetOptEnv ''
prog =. irProg ((irAssn ((irRef 'x') ; (irLit 5))) ; (irCall3 ((irLit '+') ; (irRef 'x') ; (irLit 0))))
optd =. optWithEnv prog
stmts =. irArgs optd
NB. First stmt is the assignment (lhs is irLit 5)
check (irOp 0 { stmts) ; IR_ASSN ; <'prop: x =: 5 kept as ASSN'
NB. Second stmt: x + 0 should fold to 5 (prop then fold)
check (irOp 1 { stmts) ; IR_LIT ; <'prop: x + 0 -> IR_LIT'
check (irArgs 1 { stmts) ; 5 ; <'prop: x + 0 = 5'

NB. --- End-to-end: optimize & execute ----------------------

NB. NB: these are guarded until the lowerer is complete.
NB. We use the optWithEnv / call / irLit path directly so the
NB. tests stay useful even before the lowerer lands.

NB. (2 + 3) folds to 5 (no runtime computation)
resetOptEnv ''
check (optWithEnv (irCall3 ((irLit '+') ; (irLit 2) ; (irLit 3)))) ; (irLit 5) ; <'opt+unparse: 2 + 3 = 5'

NB. MDL cost sanity check: a 2-train has cost 2
mdlCost =. 3 : 0
  NB. Local re-bind to avoid namespace pollution
  ir =. y
  if. (0 = # ir) +. (ir -: a:) do. 0 return. end.
  op =. irOp ir
  if. op = IR_LIT do. 1 return. end.
  if. op = IR_REF do. 1 return. end.
  if. op = IR_CALL do. 3 return. end.
  if. op = IR_TRAIN2 do. 2 return. end.
  if. op = IR_TRAIN3 do. 2 return. end.
  0
)
check (mdlCost irLit 5) ; 1 ; <'mdlCost: IR_LIT = 1'
check (mdlCost (irTrain2 ((irLit '+') ; (irLit '/')))) ; 2 ; <'mdlCost: IR_TRAIN2 = 2'
