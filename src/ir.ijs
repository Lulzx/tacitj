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

NB. Opcode labels (for diagnostics)
IR_LABELS =: 'LIT';'REF';'CALL';'TRAIN2';'TRAIN3';'ADVR';'CONJ';'ASSN';'SEQ';'PROG'

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
NB. y = AST_SENT node (1-box wrapping 2-box)
NB. Result = IR node (boxed triple)
lowerSent =: 3 : 0
  sent =. y
  NB. SENT's payload is the inner node (a 2-box of (tag, inner-payload)).
  inner =. astPayload sent
  innerTag =. > 0 { > inner
  if. innerTag = AST_ASSIGN do.
    NB. ASSIGN payload: (nameAst ; exprAst)
    inner2 =. > 1 { > inner
    nameAst =. > 0 { inner2
    exprAst =. > 1 { inner2
    nameVal =. > 1 { > nameAst
    exprIr  =. lowerExpr exprAst
    irAssn (<(<irRef (>nameVal)) , (<exprIr))
  elseif. innerTag = AST_EXPR do.
    NB. EXPR payload: a 2-element 2-box of (EXPR-tag, children-payload).
    NB. children-payload is itself a 1-box wrapping the children vector.
    NB. We use ,"1 (cat on axis 1) to ravel the 1x2 matrix to a list.
    innerExpr =. > 1 { > inner
    kids =. > 1 {"1 innerExpr
    lowerExpr kids
  else.
    NB. Unknown: return empty
    irSeq (0 $ a:)
  end.
)

NB. lowerExpr: lower a list of AST children to a single IR.
NB. y = boxed vector of AST child nodes (output of groupTrains
NB.     and parseExpr, but opened one level)
NB.
NB. We apply J's right-to-left evaluation: a flat sequence
NB.   t1 v1 t2 v2 t3 ...
NB. is folded as
NB.   t1 v1 (t2 v2 (t3 ...))
NB. A 2-train (hook) children = [u ; v] becomes IR_TRAIN2.
NB. A 3-train (fork) children = [u ; v ; w] becomes IR_TRAIN3.
lowerExpr =: 3 : 0
  children =. y
  nc =. # children
  if. nc = 0 do. a: return. end.
  if. nc = 1 do.
    NB. Single child. If the child is itself an EXPR (parser
    NB. nesting), unwrap it recursively by extracting the
    NB. inner EXPR's children vector.
    head =. > 0 { children
    if. (astTag head) = AST_EXPR do.
      innerPayload =. astPayload head
      lowerExpr (> 1 { > innerPayload)
      return.
    end.
    lowerNode head
    return.
  end.
  if. nc = 2 do. lowerExpr2 children return. end.
  if. nc = 3 do. lowerExpr3 children return. end.
  lowerFold children
)

NB. lowerExpr2: lower a 2-element child list to a 2-train or
NB. monadic call.
NB. y = boxed vector of 2 AST nodes
lowerExpr2 =: 3 : 0
  a =. > 0 { y
  b =. > 1 { y
  if. isAstVerb b do.
    irCall3 ((irLitVerb b) ; a: ; (lowerNode a))
  elseif. isAstVerb a do.
    irCall3 ((irLitVerb a) ; a: ; (lowerNode b))
  else.
    irTrain2 (<(lowerNode a) ; <(lowerNode b))
  end.
)

NB. lowerExpr3: lower a 3-element child list. If all three are
NB. verbs, this is a 3-train (fork); otherwise it's a
NB. right-to-left dyadic fold.
NB. y = boxed vector of 3 AST nodes
lowerExpr3 =: 3 : 0
  a =. > 0 { y
  b =. > 1 { y
  c =. > 2 { y
  if. (isAstVerb a) *. (isAstVerb b) *. (isAstVerb c) do.
    irTrain3 (<(lowerNode a) ; <(lowerNode b) ; <(lowerNode c))
  else.
    irCall3 ((irLitVerb a) ; (lowerNode b) ; (lowerNode c))
  end.
)

NB. lowerTwo: lower a pair (verb ; arg) where verb is the verb char
NB. AST and arg is a noun AST. Result is a partial IR for the
NB. sub-expression.
NB. y = boxed pair (verbAst ; nounAst)
lowerTwo =: 3 : 0
  'verbAst nounAst' =. y
  if. isAstVerb verbAst do.
    irCall3 ((irLitVerb verbAst) ; a: ; (lowerNode nounAst))
  else.
    lowerNode nounAst
  end.
)

NB. lowerFold: right-to-left fold of a 4+ element child list.
NB. y = boxed vector of AST children, length >= 4
NB. The pattern is interpreted as
NB.   child[0] verb[1] child[2] verb[3] child[4] ...
NB. where verbs are at odd positions and nouns/exprs are at even
NB. positions. Result is the IR for the whole expression.
lowerFold =: 3 : 0
  children =. y
  NB. The rightmost child is always a noun/expr.
  right =. lowerNode > ({. _1) { children
  NB. Then walk back: pair each verb with the accumulated rhs.
  i =. <: nc =. # children
  while. i > 0 do.
    NB. i is the verb position (1, 3, 5, ...). Its left arg is
    NB. the noun at position i-1.
    verbAst =. i { children
    if. isAstVerb verbAst do.
      NB. Dyadic: (lhs) verb (rhs)
      lhs =. lowerNode > (i - 1) { children
      right =. irCall3 ((irLitVerb verbAst) ; lhs ; right)
    else.
      NB. Verb position is not a verb: treat as part of the
      NB. left-hand expression. This is rare in J (e.g., adverbs
      NB. at odd positions); for Stage 0 we just keep folding.
      right =. irCall3 ((irLitVerb verbAst) ; (lowerNode > (i-1) { children) ; right)
    end.
    i =. i - 2
  end.
  right
)

NB. lowerNode: lower a single AST node (one element of the EXPR's
NB. child list) to an IR node.
NB. y = AST node (1-box wrapping 2-box)
NB. Result = IR node
lowerNode =: 3 : 0
  node =. y
  t =. astTag node
  if. t = AST_NOON do.
    p =. astPayload node
    irLit (> p)
  elseif. t = AST_STR do.
    p =. astPayload node
    irLit > p
  elseif. t = AST_NAME do.
    p =. astPayload node
    irRef > p
  elseif. (t = AST_VERB) +. (t = AST_ADV) +. (t = AST_CONJ) do.
    p =. astPayload node
    irLit > p
  elseif. t = AST_TRAIN do.
    NB. AST_TRAIN's payload is the children list (boxed vector).
    children =. astPayload node
    lowerExpr children
  elseif. t = AST_EXPR do.
    NB. Nested EXPR (from parens): the payload is a 2-box of
    NB. (EXPR-tag, children-vector). Recurse.
    children =. > 1 { > node
    lowerExpr children
  else.
    NB. Unknown: a literal a:
    a:
  end.
)

NB. isAstVerb: is the given AST node a verb/adv/conj?
NB. (verbs, adverbs, and conjunctions all behave as operators in
NB. J's evaluation; we lump them together for the fold.)
isAstVerb =: 3 : 0
  t =. astTag y
  t e. AST_VERB , AST_ADV , AST_CONJ
)

NB. irLitVerb: extract a single char from a verb/adv/conj AST
NB. and wrap it in an IR_LIT.
NB. y = AST verb/adv/conj node
NB. Result = IR_LIT (1-char char vec)
irLitVerb =: 3 : 0
  p =. > astPayload y
  irLit (,p)
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
    NB. char - if it's a J primitive verb/adverb/conjunction, emit as-is.
    if. +./ (v = {. prims) , (v = 1 { prims) , (v = 2 { prims) , (v e. 3 }. prims) do.
      v return.
    end.
    NB. not a prim - quote it
    q , v , q
  else.
    ": v
  end.
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
execIrSingle =: 3 : 0
  's src' =. y
  if. (irOp s) = IR_ASSN do.
    tmpf =. '/tmp/tacitj_run.ijs'
    src 1!:2 < tmpf
    0!:101 < tmpf
    a: return.
  end.
  ". src
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
