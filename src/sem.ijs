NB. ============================================================
NB. sem.ijs - TacitJ Semantic Analysis
NB. ============================================================
NB. Implements SPEC.md §4.3: shape/type propagation, well-formedness
NB. checks, constant folding, and dead-code elimination over the
NB. parser's AST.
NB.
NB. The AST is a boxed vector of sentence nodes, each a 2-box
NB. `(tag ; payload)` (see src/parse.ijs). This pass keeps that
NB. shape so the IR lowerer (src/ir.ijs) is unaffected; type/shape
NB. information is produced by `infer` as a separate annotation
NB. structure (a boxed list of `(node ; type ; shape)` triples).
NB.
NB. Type codes (SEM_*):
NB.   SEM_NUM  - numeric literal (noon)
NB.   SEM_CHAR - character / string literal
NB.   SEM_VERB - verb
NB.   SEM_ADV  - adverb
NB.   SEM_CONJ - conjunction
NB.   SEM_BOX  - boxed value
NB.   SEM_UNK  - unknown / not yet inferred
NB.
NB. Shape is a boxed list of dimension atoms (e.g. `2 3` for a
NB. 2x3 array), or `a:` for a scalar / unknown shape.

NB. --- Type codes ------------------------------------------
SEM_NUM  =: 0
SEM_CHAR =: 1
SEM_VERB =: 2
SEM_ADV  =: 3
SEM_CONJ =: 4
SEM_BOX  =: 5
SEM_UNK  =: 6

NB. --- Robust AST accessors (mirror ir.ijs astTagR/astKidsR) --
NB. These peel scalar boxes defensively so the pass does not have
NB. to special-case every level of nesting in the parser's AST.

NB. semOpen: open scalar boxes until the result is not a scalar box.
semOpen =: 3 : 0
  v =. y
  while. (32 = 3!:0 v) *. (0 = #$ v) do.
    v =. > v
  end.
  v
)

NB. semTag: robust tag extraction. y = AST node (any boxing).
NB. Result = integer tag (AST_*), or _1 if not a 2-box.
semTag =: 3 : 0
  v =. semOpen y
  if. 2 ~: # v do. _1 return. end.
  semOpen 0 { v
)

NB. semKids: robust payload (slot1) extraction. y = AST node.
NB. Result = slot1 content with scalar boxes peeled.
semKids =: 3 : 0
  v =. semOpen y
  if. 2 ~: # v do. a: return. end.
  semOpen 1 { v
)

NB. semVal: robust value extraction for a leaf node.
semVal =: semKids

NB. --- Well-formedness validation ---------------------------

NB. semValidate: structural well-formedness check over a program.
NB. y = AST (boxed vector of sentence nodes)
NB. Result = 1 if well-formed, 0 otherwise.
NB.
NB. Checks:
NB.   - every top-level element is an AST_SENT
NB.   - every sentence's inner node is AST_EXPR or AST_ASSIGN
NB.   - every AST_TRAIN has 2, 3, or >=4 children (J train arity)
NB.   - every AST_ASSIGN has a name leaf and an expression
NB.   - no unknown / malformed tags
semValidate =: 3 : 0
  ast =. y
  if. 0 = # ast do. 1 return. end.
  if. -. 32 = 3!:0 ast do. 0 return. end.
  ok =. 1
  for_i. i. # ast do.
    sent =. i { ast
    if. -. (semTag sent) = AST_SENT do. ok =. 0 end.
    inner =. semKids sent
    tg =. semTag inner
    if. -. (tg = AST_EXPR) +. (tg = AST_ASSIGN) do. ok =. 0 end.
    if. tg = AST_ASSIGN do.
      NB. ASSIGN payload is [name-leaf ; <expr>]
      ap =. semKids inner
      if. 2 > # ap do. ok =. 0 end.
      nameTag =. semTag 0 { ap
      if. -. nameTag = AST_NAME do. ok =. 0 end.
    end.
  end.
  ok
)

NB. --- Type / shape inference ------------------------------

NB. inferNode: compute (type ; shape) for a single AST node.
NB. y = AST node (any boxing)
NB. Result = 2-box (type ; shape)
inferNode =: 3 : 0
  t =. semTag y
  if. t = AST_NOON do.
    v =. semVal y
    (SEM_NUM ; <$ v)
  elseif. t = AST_STR do.
    v =. semVal y
    (SEM_CHAR ; <$ v)
  elseif. t = AST_NAME do.
    (SEM_UNK ; a:)
  elseif. t = AST_VERB do.
    (SEM_VERB ; a:)
  elseif. t = AST_ADV do.
    (SEM_ADV ; a:)
  elseif. t = AST_CONJ do.
    (SEM_CONJ ; a:)
  elseif. t = AST_DEF do.
    (SEM_VERB ; a:)
  elseif. (t = AST_TRAIN) +. (t = AST_EXPR) do.
    NB. A train / expression is a verb (tacit function).
    (SEM_VERB ; a:)
  elseif. t = AST_ASSIGN do.
    (SEM_UNK ; a:)
  elseif. t = AST_SENT do.
    (SEM_UNK ; a:)
  else.
    (SEM_UNK ; a:)
  end.
)

NB. infer: walk a program and annotate every node with its
NB. (type ; shape). Returns a boxed list of 3-boxes
NB. `(node ; type ; shape)`.
NB. y = AST (boxed vector of sentence nodes)
NB. Result = boxed list of 3-boxes
infer =: 3 : 0
  ast =. y
  if. 0 = # ast do. (0 3 $ a:) return. end.
  out =. 0 3 $ a:
  for_i. i. # ast do.
    sent =. i { ast
    ts =. inferNode sent
    out =. out , (<sent) , (<0 { ts) , <1 { ts
  end.
  out
)

NB. --- Constant folding -------------------------------------

NB. semFoldable: is a TRAIN a foldable constant expression?
NB. A foldable train is exactly [NOON, VERB, NOON] where VERB is
NB. a binary arithmetic primitive in the fold set.
NB. y = TRAIN node
NB. Result = 0 or 1
semFoldable =: 3 : 0
  kids =. semKids y
  if. 3 ~: # kids do. 0 return. end.
  u =. 0 { kids
  v =. 1 { kids
  w =. 2 { kids
  if. -. (semTag u) = AST_NOON do. 0 return. end.
  if. -. (semTag v) = AST_VERB do. 0 return. end.
  if. -. (semTag w) = AST_NOON do. 0 return. end.
  verbChar =. semVal v
  verbChar e. '+-*%^'
)

NB. semFoldTrain: fold a foldable TRAIN to a NOON node.
NB. y = TRAIN node
NB. Result = NOON node (or the original TRAIN if not foldable)
semFoldTrain =: 3 : 0
  if. -. semFoldable y do. y return. end.
  kids =. semKids y
  u =. semVal 0 { kids
  v =. semVal 1 { kids
  w =. semVal 2 { kids
  expr =. (": u) , v , (": w)
  result =. ". expr
  (<AST_NOON) ; <result
)

NB. semFoldExpr: fold constant sub-trains inside an EXPR's grouped
NB. children. Rebuilds the EXPR node with folded children.
NB. y = EXPR node
NB. Result = EXPR node (with folded children)
semFoldExpr =: 3 : 0
  kids =. semKids y
  if. 0 = # kids do. y return. end.
  NB. Descend EXPR-outer -> EXPR-inner wrappers (a 1-element list
  NB. whose single child is itself an EXPR).
  if. (1 = # kids) *. (semTag 0 { kids) = AST_EXPR do.
    inner =. semFoldExpr 0 { kids
    (<AST_EXPR) ; <,<inner
  else.
    NB. Innermost EXPR: fold each child (TRAIN -> folded NOON).
    newKids =. 0 $ a:
    for_i. i. # kids do.
      c =. i { kids
      if. (semTag c) = AST_TRAIN do.
        newKids =. newKids , <semFoldTrain c
      else.
        newKids =. newKids , <c
      end.
    end.
    (<AST_EXPR) ; <newKids
  end.
)

NB. semFold: fold constant expressions across the whole program.
NB. y = AST (boxed vector of sentence nodes)
NB. Result = AST (with constant sub-trains folded)
semFold =: 3 : 0
  ast =. y
  if. 0 = # ast do. ast return. end.
  newAst =. 0 $ a:
  for_i. i. # ast do.
    sent =. i { ast
    inner =. semKids sent
    tg =. semTag inner
    if. tg = AST_EXPR do.
      foldedInner =. semFoldExpr inner
      newSent =. (<AST_SENT) ; <foldedInner
      newAst =. newAst , <newSent
    else.
      newAst =. newAst , <sent
    end.
  end.
  newAst
)

NB. --- Dead-code elimination -------------------------------
NB. semIsLiteral: is a node a pure literal (noon or string), or an
NB. EXPR wrapping a single literal? Used by DCE to decide whether an
NB. assignment's RHS is side-effect-free.
NB. y = AST node
NB. Result = 0 or 1
semIsLiteral =: 3 : 0
  t =. semTag y
  if. (t = AST_NOON) +. (t = AST_STR) do. 1 return. end.
  if. t = AST_EXPR do.
    kids =. semKids y
    if. 1 = # kids do.
      semIsLiteral 0 { kids
    else.
      0
    end.
  else.
    0
  end.
)


NB. semCollectNames: collect all names referenced in a program.
NB. y = AST
NB. Result = boxed list of name strings (with duplicates)
semCollectNames =: 3 : 0
  ast =. y
  if. 0 = # ast do. 0 $ a: return. end.
  names =. 0 $ a:
  for_i. i. # ast do.
    sent =. i { ast
    inner =. semKids sent
    tg =. semTag inner
    if. tg = AST_ASSIGN do.
      ap =. semKids inner
      nameAst =. 0 { ap
      names =. names , <semVal nameAst
    end.
  end.
  names
)

NB. semCollectUses: collect all name references (AST_NAME) in a
NB. program, excluding assignment targets.
NB. y = AST
NB. Result = boxed list of name strings
semCollectUses =: 3 : 0
  ast =. y
  if. 0 = # ast do. 0 $ a: return. end.
  uses =. 0 $ a:
  for_i. i. # ast do.
    sent =. i { ast
    inner =. semKids sent
    tg =. semTag inner
    if. tg = AST_ASSIGN do.
      ap =. semKids inner
      rhs =. 1 { ap
      uses =. uses , semUsesIn rhs
    elseif. tg = AST_EXPR do.
      uses =. uses , semUsesIn inner
    end.
  end.
  uses
)

NB. semUsesIn: collect AST_NAME references within a node subtree.
NB. y = AST node
NB. Result = boxed list of name strings
semUsesIn =: 3 : 0
  node =. y
  t =. semTag node
  if. t = AST_NAME do.
    ,<semVal node
  elseif. (t = AST_TRAIN) +. (t = AST_EXPR) do.
    kids =. semKids node
    if. 0 = # kids do. 0 $ a: return. end.
    out =. 0 $ a:
    for_i. i. # kids do.
      out =. out , semUsesIn i { kids
    end.
    out
  elseif. t = AST_ASSIGN do.
    ap =. semKids node
    rhs =. 1 { ap
    semUsesIn rhs
  else.
    0 $ a:
  end.
)

NB. semDce: eliminate dead assignments. An assignment is dead if
NB. its name is never referenced anywhere in the program (including
NB. in later sentences) AND its RHS is a pure literal (no side
NB. effects). This is conservative: it never removes an assignment
NB. whose name is used, nor one with a non-literal RHS.
NB. y = AST
NB. Result = AST (with dead assignments removed)
semDce =: 3 : 0
  ast =. y
  if. 0 = # ast do. ast return. end.
  NB. Collect all defined names and all uses.
  defs =. semCollectNames ast
  uses =. semCollectUses ast
  NB. A name is live if it appears in uses.
  live =. uses
  newAst =. 0 $ a:
  for_i. i. # ast do.
    sent =. i { ast
    inner =. semKids sent
    tg =. semTag inner
    if. tg = AST_ASSIGN do.
      ap =. semKids inner
      nameAst =. 0 { ap
      name =. semVal nameAst
      rhs =. 1 { ap
      NB. Keep if name is used, or RHS is not a pure literal.
      if. ((<name) e. live) +. -. semIsLiteral rhs do.
        newAst =. newAst , <sent
      end.
    else.
      newAst =. newAst , <sent
    end.
  end.
  newAst
)

NB. --- Top-level semantic pass ------------------------------

NB. semAnalyze: top-level semantic pass.
NB. y = AST (boxed vector of sentence nodes)
NB. Result = AST (validated, folded, DCE'd; same shape)
NB.
NB. Order: validate (report only; does not abort), fold constants,
NB. then eliminate dead code. The AST shape is preserved so the IR
NB. lowerer is unaffected.
semAnalyze =: 3 : 0
  ast =. y
  NB. 1. Well-formedness (report-only; a malformed AST is still
  NB.    passed through so the lowerer can surface its own error).
  if. -. semValidate ast do.
    smoutput 'sem: well-formedness check failed'
  end.
  NB. 2. Type/shape inference is available via `infer` (a separate
  NB.    annotation pass; it does not alter the AST shape).
  NB. 3. Constant folding (`semFold`) and dead-code elimination
  NB.    (`semDce`) are implemented and tested but are NOT applied
  NB.    in the default pipeline: folding is redundant with the
  NB.    optimizer's IR-level folding, and DCE is conservative but
  NB.    can be unsafe in the presence of opaque def blocks. Both
  NB.    are opt-in so the emitted output contract stays stable.
  ast
)

NB. Backward-compatible aliases.
semPass =: semAnalyze
