NB. ============================================================
NB. ir.ijs - TacitJ Intermediate Representation (IR)
NB. ============================================================
NB. The IR is a normalised, lower-level form of a TacitJ AST that
NB. sits between the parser and the codegen. It is the canonical
NB. input to the optimizer and the bytecode emitter.
NB.
NB. IR node shape: boxed triple
NB.   (<opcode ; <args ; <meta)
NB. where
NB.   opcode : integer (IR_* constant)
NB.   args   : boxed scalar (for LIT/REF) or boxed vector of IR
NB.             nodes / values (for the rest)
NB.   meta   : boxed scalar (source-loc marker, type, etc.; `a:`
NB.             for no metadata)
NB.
NB. Each IR is a single boxed value (the 1-box wrapping the triple
NB. inside the link) that downstream code can recur on uniformly.
NB.
NB. The Stage 0 lowerer is intentionally minimal: it walks the
NB. AST's flat EXPR sequences and produces a chain of IR_CALL /
NB. IR_TRAIN2 / IR_TRAIN3 nodes, applying J's right-to-left
NB. evaluation rule. Weeks 2-3 will replace this with a more
NB. rigorous lowerer (see SPEC.md §4.4).

NB. --- IR opcodes ------------------------------------------
IR_LIT    =: 0    NB. literal: number or char vector
IR_REF    =: 1    NB. name reference
IR_CALL   =: 2    NB. function call (monadic or dyadic)
IR_TRAIN2 =: 3    NB. 2-train (hook): (u v) y = u y v y
IR_TRAIN3 =: 4    NB. 3-train (fork): (u v w) y = (u y) v (w y)
IR_ADVR   =: 5    NB. adverb application: u m
IR_CONJ   =: 6    NB. conjunction: u n v  (e.g., f @ g)
IR_ASSN   =: 7    NB. assignment: name =: expr
IR_SEQ    =: 8    NB. sequence of statements
IR_PROG   =: 9    NB. top-level program: list of sentences
IR_TRAIN  =: 10   NB. generic N-train (N>=4): unparses to ( c0 c1 ... )
                 NB.   J's own parser handles train reduction on round-trip.

NB. Opcode labels (for diagnostics)
IR_LABELS =: 'LIT';'REF';'CALL';'TRAIN2';'TRAIN3';'ADVR';'CONJ';'ASSN';'SEQ';'PROG';'TRAIN'

NB. --- IR constructors -------------------------------------

NB. mkIr: build a boxed IR triple from a 3-element boxed list.
NB. y = boxed 3-list (op ; args ; meta), each part already 1-boxed
NB.
NB. The result is y itself, since the input is already in the
NB. canonical IR shape (3-element boxed list, each part 1-boxed).
NB. mkIr exists as a single chokepoint for any future
NB. validation / instrumentation, and to make call sites
NB. self-documenting.
NB.
NB. IR node shape: 1-box wrapping a boxed 3-list of 1-boxes.
NB.   The boxed list has 3 elements: 1-box-op, 1-box-args, 1-box-meta.
NB.   The outer 1-box protects the IR from being unrolled by
NB.   J's `,` (catenate) when used in compound expressions.
NB.
NB. For a 1-box wrapping a boxed 3-list:
NB.   > ir            ->  boxed 3-list of 1-boxes
NB.   0 { > ir        ->  1-box-op (of 1-element list of op)
NB.   > 0 { > ir      ->  1-element list of op
NB.   > > 0 { > ir    ->  op (the scalar, unboxed)
NB.
NB. mkIr's input is a 3-element boxed list. Each value should
NB. be wrapped as a 1-box of a 1-element list (use `,` to
NB. catenate a single element to make a 1-element list, then
NB. `<` to box it). The 1-element list wrapping defeats J's
NB. `,` unrolling of the boxed 3-list.
mkIr =: 3 : 0
  y
)

NB. irOp: extract opcode of an IR node.
NB. y = IR node (possibly multi-boxed).
NB. Result = unboxed integer opcode (a scalar).
NB. We normalize via unboxIr then extract the first slot's value.
irOp =: 3 : 0
  if. 0 = # y do. _1 return. end.
  ir =. unboxIr y
  slot =. 0 { ir
  NB. Unbox if boxed, otherwise return as-is.
  if. 32 = 3!:0 slot do. > slot else. slot end.
)

NB. irArgs: extract args of an IR node.
NB. y = IR node.
NB. Result = the args slot value (unboxed).
NB. The slot is stored as `<value` (1-box). We unbox it so callers
NB. get the value directly (atom, list, or a:).
irArgs =: 3 : 0
  if. 0 = # y do. a: return. end.
  ir =. unboxIr y
  if. 3 > # ir do. a: return. end.
  slot =. 1 { ir
  > slot
)

NB. irMeta: extract metadata of an IR node.
NB. y = IR node.
NB. Result = the meta slot value (usually a:).
irMeta =: 3 : 0
  if. 0 = # y do. a: return. end.
  ir =. unboxIr y
  slot =. 2 { ir
  if. 32 = 3!:0 slot do. > slot else. slot end.
)

NB. irIs: predicate: is this IR of the given opcode?
NB. (ir, opcode) -> 0/1
irIs =: 4 : 0
  (irOp x) = y
)

NB. --- Higher-level builders --------------------------------

NB. The IR shape is `1-box of 3-element boxed list`. Each slot in
NB. the 3-element list is itself a `1-box of value`. We assemble
NB. the 3-element list by hand: each slot is bound to a name, then
NB. the names are combined via `,` (catenate). Each slot is a
NB. single `<X` (1-box of X) so `,` preserves the 1-boxing and the
NB. slot value is directly accessible by one `>` unbox.

NB. irLit: build an IR_LIT from a scalar value.
irLit =: 3 : 0
  slot0 =. < IR_LIT
  slot1 =. < y
  slot2 =. < a:
  ir =. slot0 , slot1 , slot2
  < ir
)

NB. irRef: build an IR_REF from a name (char vec).
irRef =: 3 : 0
  slot0 =. < IR_REF
  slot1 =. < y
  slot2 =. < a:
  ir =. slot0 , slot1 , slot2
  < ir
)

NB. irCall: build an IR_CALL.
NB. y = boxed vector of (verb ; lhs-or-a: ; rhs)
irCall =: 3 : 0
  slot0 =. < IR_CALL
  slot1 =. < y
  slot2 =. < a:
  ir =. slot0 , slot1 , slot2
  < ir
)

NB. irCall3: convenience constructor for IR_CALL with 3 args.
NB. y = boxed 3-list (verb ; lhs-or-a: ; rhs)
irCall3 =: 3 : 0
  slot0 =. < IR_CALL
  slot1 =. < y
  slot2 =. < a:
  ir =. slot0 , slot1 , slot2
  < ir
)

NB. irTrain2: build an IR_TRAIN2.
NB. y = boxed pair (u ; v) - may be assembled with `;`
NB. We extract each element and re-box if needed to ensure
NB. consistent IR shape.
irTrain2 =: 3 : 0
  if. 2 > # y do.
    slot0 =. < IR_TRAIN2
    slot1 =. < a:
    slot2 =. < a:
    < slot0 , slot1 , slot2
  return. end.
  u =. 0 { y
  v =. 1 { y
  if. -. 32 = 3!:0 u do. u =. < u end.
  if. -. 32 = 3!:0 v do. v =. < v end.
  slot0 =. < IR_TRAIN2
  slot1 =. < (u ; v)
  slot2 =. < a:
  ir =. slot0 , slot1 , slot2
  < ir
)

NB. irTrain3: build an IR_TRAIN3.
NB. y = boxed triple (u ; v ; w) - may be assembled with `;`
irTrain3 =: 3 : 0
  if. 3 > # y do. < (<<IR_TRAIN3) , (<<a:) , (<<a:) return. end.
  u =. 0 { y
  v =. 1 { y
  w =. 2 { y
  if. -. 32 = 3!:0 u do. u =. < u end.
  if. -. 32 = 3!:0 v do. v =. < v end.
  if. -. 32 = 3!:0 w do. w =. < w end.
  slot0 =. < IR_TRAIN3
  slot1 =. < (u ; v ; w)
  slot2 =. < a:
  ir =. slot0 , slot1 , slot2
  < ir
)

NB. irTrainN: build a generic IR_TRAIN from a boxed vector of child IRs.
NB. y = boxed vector of IR nodes (the train's components, in order).
NB. Used for N>=4 trains (and N=2/3 may also use this as a uniform path).
NB. Unparses to ( c0 c1 ... cN-1 ) so J's parser recovers train semantics.
irTrainN =: 3 : 0
  kids =. y
  if. 0 = # kids do. < (<IR_TRAIN) , (<a:) , (<a:) return. end.
  NB. Ensure each child is boxed.
  boxed =. 0 $ a:
  for_i. i. # kids do.
    c =. i { kids
    if. -. 32 = 3!:0 c do. c =. < c end.
    boxed =. boxed , <c
  end.
  slot0 =. < IR_TRAIN
  slot1 =. < boxed
  slot2 =. < a:
  < (slot0 , slot1 , slot2)
)

NB. irCall: build an IR_CALL.
NB. y = boxed vector of (verb ; lhs-or-a: ; rhs) - may be assembled with `;`
irCall =: 3 : 0
  u =. 0 { y
  v =. 1 { y
  w =. 2 { y
  if. -. 32 = 3!:0 u do. u =. < u end.
  if. -. 32 = 3!:0 v do. v =. < v end.
  if. -. 32 = 3!:0 w do. w =. < w end.
  slot0 =. < IR_CALL
  slot1 =. < (u ; v ; w)
  slot2 =. < a:
  ir =. slot0 , slot1 , slot2
  < ir
)

NB. irCall3: same as irCall
irCall3 =: irCall

NB. irAdv: build an IR_ADVR.
NB. y = boxed vector of (verb ; adverb) - may be assembled with `;`
irAdv =: 3 : 0
  u =. 0 { y
  v =. 1 { y
  if. -. 32 = 3!:0 u do. u =. < u end.
  if. -. 32 = 3!:0 v do. v =. < v end.
  slot0 =. < IR_ADVR
  slot1 =. < (u ; v)
  slot2 =. < a:
  ir =. slot0 , slot1 , slot2
  < ir
)

NB. irConj: build an IR_CONJ.
NB. y = boxed vector of (u ; conj ; v) - may be assembled with `;`
irConj =: 3 : 0
  u =. 0 { y
  v =. 1 { y
  w =. 2 { y
  if. -. 32 = 3!:0 u do. u =. < u end.
  if. -. 32 = 3!:0 v do. v =. < v end.
  if. -. 32 = 3!:0 w do. w =. < w end.
  slot0 =. < IR_CONJ
  slot1 =. < (u ; v ; w)
  slot2 =. < a:
  ir =. slot0 , slot1 , slot2
  < ir
)

NB. irAssn: build an IR_ASSN.
NB. y = boxed pair (name-char ; expr-IR) - may be assembled with `;`
irAssn =: 3 : 0
  u =. 0 { y
  v =. 1 { y
  if. -. 32 = 3!:0 u do. u =. < u end.
  if. -. 32 = 3!:0 v do. v =. < v end.
  slot0 =. < IR_ASSN
  slot1 =. < (u ; v)
  slot2 =. < a:
  ir =. slot0 , slot1 , slot2
  < ir
)

NB. irSeq: build an IR_SEQ of multiple statements.
irSeq =: 3 : 0
  slot0 =. < IR_SEQ
  slot1 =. < y
  slot2 =. < a:
  ir =. slot0 , slot1 , slot2
  < ir
)

NB. irProg: build an IR_PROG (top-level program).
NB. y = boxed list of sentences (each sentence is an IR_SEQ)
irProg =: 3 : 0
  slot0 =. < IR_PROG
  slot1 =. < y
  slot2 =. < a:
  ir =. slot0 , slot1 , slot2
  < ir
)

NB. --- Robust AST accessors -----------------------------------
NB. The parser's AST has irregular boxing (scalar-boxed 2-boxes,
NB. double-boxed leaves inside trains, EXPR-outer wrapping an
NB. EXPR-inner via a 1-element ravel list). These accessors peel
NB. boxes defensively so the lowerer does not have to special-case
NB. every level of nesting.

NB. openToBox: open scalar boxes (rank-0 boxes) until the result is
NB. not a scalar box. A 2-box (a;b) has rank 1 so it is returned as-is.
NB. y = any value. Result = the first non-scalar-box value.
openToBox =: 3 : 0
  v =. y
  while. (32 = 3!:0 v) *. (0 = #$ v) do.
    v =. > v
  end.
  v
)

NB. astTagR: robust tag extraction. y = AST node (any boxing).
NB. Result = the integer tag (AST_*), or _1 if not a 2-box.
astTagR =: 3 : 0
  v =. openToBox y
  if. 2 ~: # v do. _1 return. end.
  openToBox 0 { v
)

NB. astKidsR: robust payload (slot1) extraction. y = AST node.
NB. Result = slot1 content with scalar boxes peeled.
NB.   - SENT  -> inner 2-box (EXPR-outer or ASSIGN)
NB.   - EXPR  -> grouped children vector (or, for EXPR-outer, the
NB.              1-element ravel list wrapping EXPR-inner)
NB.   - TRAIN -> leaves vector
NB.   - ASSIGN -> the [name ; <expr>] 2-box
NB.   - leaf  -> the value (number / char vec / name string)
astKidsR =: 3 : 0
  v =. openToBox y
  if. 2 ~: # v do. a: return. end.
  openToBox 1 { v
)

NB. astValR: robust value extraction for a leaf node. Same as astKidsR
NB. but named for clarity at leaf call sites.
astValR =: astKidsR

NB. groupedOf: descend EXPR wrappers and return the grouped children
NB. vector of the innermost EXPR. If the node is not an EXPR, return it
NB. as-is (so callers can lowerNode it).
NB. y = an EXPR node (any boxing). Result = the grouped children vector
NB. (a boxed list of TRAIN/leaf nodes), or the node itself if non-EXPR.
groupedOf =: 3 : 0
  node =. y
  while. (astTagR node) = AST_EXPR do.
    kids =. astKidsR node
    if. (1 = # kids) *. (AST_EXPR = astTagR 0 { kids) do.
      NB. EXPR-outer wraps EXPR-inner via a 1-element list: descend.
      node =. 0 { kids
    else.
      kids return.
    end.
  end.
  node
)

NB. --- Lowering: AST -> IR ---------------------------------

NB. lowerAst: convert a TacitJ AST (output of parseProgram) into
NB. an IR_PROG.
NB. y = boxed vector of 1-box AST_SENT nodes
NB. Result = IR_PROG node (boxed triple)
NB.
NB. Strategy:
NB.   1. For each sentence, lower the inner EXPR / ASSIGN to IR.
NB.   2. Wrap the resulting list in IR_PROG.
lowerAst =: 3 : 0
  sents =. y
  irs =. lowerSentList sents
  irProg irs
)

NB. lowerSentList: lower a boxed vector of sentence ASTs to a
NB. boxed vector of IR nodes (one IR per sentence).
lowerSentList =: 3 : 0
  sents =. y
  if. 0 = # sents do.
    0 $ a:
  else.
    head =. lowerSent 0 { sents
    rest =. }. sents
    head , lowerSentList rest
  end.
)

NB. lowerSent: lower a single sentence AST to an IR node.
NB. y = AST_SENT node (any boxing; robust accessors peel it).
NB. Result = IR node (IR_ASSN for an assignment, the expr IR for a
NB. bare expression, or an empty IR_SEQ for an unknown shape).
lowerSent =: 3 : 0
  inner =. astKidsR y                       NB. inner 2-box (EXPR-outer or ASSIGN)
  tg =. astTagR inner
  if. tg = AST_ASSIGN do.
    payload =. astKidsR inner                NB. [name-leaf ; <expr-EXPR>]
    name =. astValR 0 { payload              NB. the name string
    exprIr =. lowerExprNode 1 { payload      NB. <EXPR-inner> (scalar-boxed)
    irAssn ((<irRef name) , <exprIr)
  elseif. tg = AST_EXPR do.
    lowerExprNode inner
  else.
    irSeq 0 $ a:
  end.
)

NB. lowerExprNode: lower an EXPR node (any boxing) to an IR.
NB. Descends EXPR-outer -> EXPR-inner wrappers via `groupedOf`, then
NB. lowers the innermost grouped children vector with `lowerSeq`.
lowerExprNode =: 3 : 0
  lowerSeq groupedOf y
)

NB. lowerSeq: lower a boxed vector of AST nodes (TRAIN children or
NB. grouped expression children) into a single IR.
NB. y = boxed vector of AST nodes (each any boxing).
NB. Result = IR node.
NB.
NB. The flat node sequence is emitted as a parenthesised train so
NB. that J's own parser recovers the correct semantics on round-trip
NB. (verified for bare expressions, value assignments, and tacit-train
NB. definitions). N=2 -> IR_TRAIN2, N=3 -> IR_TRAIN3, N>=4 -> IR_TRAIN
NB. (generic), N=1 -> the single child's IR.
lowerSeq =: 3 : 0
  nodes =. y
  n =. # nodes
  if. n = 0 do. a: return. end.
  irs =. 0 $ a:
  i =. 0
  while. i < n do.
    irs =. irs , <lowerNode i { nodes
    i =. >: i
  end.
  if. n = 1 do. > 0 { irs return. end.
  if. n = 2 do. irTrain2 ((0 { irs) ; (1 { irs)) return. end.
  if. n = 3 do. irTrain3 ((0 { irs) ; (1 { irs) ; (2 { irs)) return. end.
  irTrainN irs
)

NB. lowerNode: lower a single AST node (a TRAIN or a leaf) to an IR.
NB. y = AST node (any boxing; robust accessors peel it).
NB. Result = IR node.
lowerNode =: 3 : 0
  t =. astTagR y
  if. t = AST_NOON do.
    irLit astValR y
  elseif. t = AST_STR do.
    irLit astValR y
  elseif. t = AST_NAME do.
    irRef astValR y
  elseif. (t = AST_VERB) +. (t = AST_ADV) +. (t = AST_CONJ) do.
    irLit astValR y
  elseif. t = AST_TRAIN do.
    lowerSeq astKidsR y
  elseif. t = AST_EXPR do.
    lowerExprNode y
  else.
    a:
  end.
)

NB. --- Unparsing: IR -> J source ----------------------------

NB. unparseIr: convert an IR node back to a J source char vector.
NB. y = IR node (boxed triple)
NB. Result = char vector of valid J source
NB. unboxIr: peel outer 1-boxes until we hit the 3-element list.
NB. y = IR node (possibly multi-boxed due to ; semantics)
NB. Result = 3-element boxed list (op ; args ; meta) or a: if empty.
NB.
NB. We peel one box at a time using `> ir`. This is safe because
NB. `>` on a 1-box always succeeds (it just returns the content).
NB. We check `# inner` to see if we've reached the 3-elem list.
NB. Note: `# <1-box-of-3-list` = 1 (the box has 1 element).
NB.       `# 3-elem-list` = 3 (the list has 3 elements).
NB. A safety bound of 8 iterations prevents infinite loops on
NB. pathological inputs.
unboxIr =: 3 : 0
  ir =. y
  cnt =. 0
  while. (32 = 3!:0 ir) *. (cnt < 8) do.
    if. 3 = # ir do. ir return. end.
    ir =. > ir
    cnt =. >: cnt
  end.
  ir
)

unparseIr =: 3 : 0
  ir =. unboxIr y
  if. ir -: a: do.
    '' return.
  end.
  if. 0 = # ir do.
    '' return.
  end.
  if. -. 3 = $ ir do.
    '' return.
  end.
  op =. irOp y
  args =. irArgs y
  if. op = IR_LIT do. unparseIrLit args return. end.
  if. op = IR_REF do. args return. end.
  if. op = IR_CALL do. unparseIrCall args return. end.
  if. op = IR_TRAIN2 do. unparseIrTrain2 args return. end.
  if. op = IR_TRAIN3 do. unparseIrTrain3 args return. end.
  if. op = IR_TRAIN  do. unparseIrTrain  args return. end.
  if. op = IR_ADVR do. unparseIrAdv args return. end.
  if. op = IR_CONJ do. unparseIrConj args return. end.
  if. op = IR_ASSN do. unparseIrAssn args return. end.
  if. op = IR_SEQ do. unparseIrSeq args return. end.
  if. op = IR_PROG do. unparseIrProg args return. end.
  ''
)

NB. unparseIrCall: emit J source for IR_CALL.
NB. y = args (boxed 3-list of children)
unparseIrCall =: 3 : 0
  args =. y
  a =. 0 { args
  b =. 1 { args
  c =. 2 { args
  if. b -: a: do.
    (unparseIr a) , ' ' , unparseIr c
  else.
    (unparseIr b) , ' ' , (unparseIr a) , ' ' , unparseIr c
  end.
)

NB. unparseIrTrain2: emit J source for IR_TRAIN2.
NB. y = args (boxed pair of children)
unparseIrTrain2 =: 3 : 0
  args =. y
  '( ' , (unparseIr 0 { args) , ' ' , (unparseIr 1 { args) , ' )'
)

NB. unparseIrTrain3: emit J source for IR_TRAIN3.
NB. y = args (boxed triple of children)
unparseIrTrain3 =: 3 : 0
  args =. y
  '( ' , (unparseIr 0 { args) , ' ' , (unparseIr 1 { args) , ' ' , (unparseIr 2 { args) , ' )'
)

NB. unparseIrTrain: emit J source for a generic IR_TRAIN (N>=2).
NB. y = args (boxed vector of child IR nodes).
NB. Emits ( c0 c1 ... cN-1 ) so J's parser recovers train semantics.
unparseIrTrain =: 3 : 0
  args =. y
  n =. # args
  if. n = 0 do. '(  )' return. end.
  out =. '( '
  i =. 0
  while. i < n do.
    out =. out , (unparseIr i { args) , ' '
    i =. >: i
  end.
  out , ')'
)

NB. unparseIrAdv: emit J source for IR_ADVR.
NB. y = args (boxed pair of children)
unparseIrAdv =: 3 : 0
  args =. y
  (unparseIr 0 { args) , ' ' , (unparseIr 1 { args)
)

NB. unparseIrConj: emit J source for IR_CONJ.
NB. y = args (boxed triple of children)
unparseIrConj =: 3 : 0
  args =. y
  (unparseIr 0 { args) , ' ' , (unparseIr 1 { args) , ' ' , (unparseIr 2 { args)
)

NB. unparseIrAssn: emit J source for IR_ASSN.
NB. y = args (boxed pair of children)
unparseIrAssn =: 3 : 0
  args =. y
  (unparseIr 0 { args) , ' =: ' , (unparseIr 1 { args)
)

NB. unparseIrSeq: emit J source for IR_SEQ.
NB. y = boxed vector of IR nodes
unparseIrSeq =: 3 : 0
  stmts =. y
  if. 0 = # stmts do.
    ''
  else.
    head =. unparseIr 0 { stmts
    rest =. }. stmts
    head , LF , unparseIrSeqRest rest
  end.
)

NB. unparseIrProg: emit J source for IR_PROG.
NB. y = boxed vector of IR nodes
unparseIrProg =: 3 : 0
  stmts =. y
  if. 0 = # stmts do.
    ''
  else.
    head =. unparseIr 0 { stmts
    rest =. }. stmts
    head , LF , unparseIrSeqRest rest
  end.
)

NB. unparseIrSeqRest: tail of an unparseIr SEQ/PROG.
NB. y = boxed vector of IR nodes (length >= 0)
unparseIrSeqRest =: 3 : 0
  stmts =. y
  if. 0 = # stmts do.
    ''
  else.
    head =. unparseIr 0 { stmts
    rest =. }. stmts
    head , LF , unparseIrSeqRest rest
  end.
)

NB. unparseIrLit: unparse an IR_LIT node's args.
NB. y = boxed scalar (the value)
NB. Result = char vector of J source for the literal
NB.
NB. Heuristics:
NB.   - 1-char primitive char (verb/adv/conj) -> bare
NB.   - char vec that's empty or multi-char -> quoted string
NB.   - number (any kind) -> ":
NB.   - anything else -> ":
isPrimChar =: 4 : 0
  r =. 0
  r =. r + (x = {. y)
  r =. r + (x = 1 { y)
  r =. r + (x = 2 { y)
  r > 0
)

unparseIrLit =: 3 : 0
  v =. y
  prims =. PRIM_VERB , PRIM_ADV , PRIM_CONJ
  q =. QUOTE
  if. 2 = 3!:0 v do.
    NB. char - if v is a single J primitive, emit as-is.
    NB. Multi-char strings always get quoted; single primitives don't.
    if. 1 = # v do.
      if. v e. prims do.
        v return.
      end.
    end.
    NB. quote the string; double any internal quotes for escape.
    NB. Build with explicit append to avoid operator-precedence
    NB. traps (q , body , q parses as (q , body) , q which doubles
    NB. the right operand).
    (q , (quoteEscape v)) , q
  else.
    ": v
  end.
)

NB. quoteEscape: turn each QUOTE in y into QUOTE,QUOTE.
NB. Used to safely re-quote a string body in J source.
quoteEscape =: 3 : 0
  s =. y
  lim =. # s
  out =. ''
  i =. 0
  while. i < lim do.
    if. (i { s) = QUOTE do.
      out =. out , QUOTE , QUOTE
    else.
      out =. out , (i { s)
    end.
    i =. >: i
  end.
  out
)

NB. execIr: run an IR_PROG via J's "."
NB. y = IR_PROG node
NB. Result = boxed result of the last bare expression
NB.   (or a: if there is none)
NB.
NB. Strategy:
NB.   1. Unparse to J source.
NB.   2. If the program is a single bare expression, run via ".
NB.   3. Otherwise, write to a temp file and load via 0!:101,
NB.      returning a: (the last statement is treated as the
NB.      "result" only if it's a bare expression and was executed
NB.      on its own line).
execIr =: 3 : 0
  prog =. y
  src =. unparseIr prog
  if. 0 = # src do. a: return. end.
  stmts =. > irArgs prog
  ns =. # stmts
  if. ns = 0 do. a: return. end.
  if. ns = 1 do. execIrSingle (0 { stmts) ; src return. end.
  execIrMulti stmts ; src
)

NB. execIrSingle: execute a single-statement program.
NB. y = boxed pair (stmt-IR ; source-char-vec)
NB. We unparse the single statement directly (rather than using the
NB. program-level `src`, which carries a trailing LF from unparseIrProg)
NB. so `".` does not choke on the newline.
execIrSingle =: 3 : 0
  's src' =. y
  ssrc =. unparseIr s
  if. (irOp s) = IR_ASSN do.
    tmpf =. '/tmp/tacitj_run.ijs'
    ssrc 1!:2 < tmpf
    0!:101 < tmpf
    a: return.
  end.
  ". ssrc
)

NB. execIrMulti: execute a multi-statement program.
NB. Loads via temp file, then re-evaluates the last non-assign
NB. IR (if any) and returns its value.
NB. y = boxed pair (stmts-boxed-vector ; source-char-vec)
execIrMulti =: 3 : 0
  'stmts src' =. y
  tmpf =. '/tmp/tacitj_run.ijs'
  src 1!:2 < tmpf
  0!:101 < tmpf
  lastExpr =. findLastExpr stmts
  if. lastExpr -: a: do. a: return. end.
  ". unparseIr lastExpr
)

NB. findLastExpr: scan a statement list for the last non-assign,
NB. non-seq IR and return it (or a: if none).
NB. y = boxed vector of IR nodes
findLastExpr =: 3 : 0
  stmts =. y
  ns =. # stmts
  lastExpr =. a:
  i =. 0
  while. i < ns do.
    s =. i { stmts
    if. -. (irOp s) e. IR_ASSN , IR_SEQ do.
      lastExpr =. s
    end.
    i =. >: i
  end.
  lastExpr
)
