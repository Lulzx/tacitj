NB. ============================================================
NB. opt.ijs - TacitJ Optimizer (rewrite engine)
NB. ============================================================
NB. The optimizer takes an IR and applies a series of rewrite
NB. rules until a fixed point is reached. The rules are
NB. expressed as J gerunds (Tacit leaning) keyed by IR opcode.
NB.
NB. Stage 0 / Week 2 implements a small but useful subset:
NB.   1. Constant folding of binary arithmetic on numeric noons.
NB.   2. Identity elimination (a 2-train with `]` collapses to
NB.      the other side).
NB.   3. Constant propagation: a single-assigned name that is
NB.      bound to a literal is replaced at every use site.
NB.
NB. The shape of the rewrite table is a gerund: each branch is
NB. a verb of arity 1 (IR -> IR). At each node the optimizer
NB. dispatches via `agenda` (the implicit gerund at) against
NB. the node's opcode. This is the SPEC.md §4.4 "agenda
NB. dispatch" pattern.
NB.
NB. NB: The Solon / MDL cost function is sketched at the end of
NB. this file (mdlCost) but not yet wired into a minimiser --
NB. see the SPEC.md §8 stub for the eventual integration.

NB. --- Top-level entry -------------------------------------

NB. opt: optimize an IR node. Applies all rewrite rules until
NB. fixed point (or a safety bound of N iterations is reached).
NB. y = IR node (boxed triple)
NB. Result = IR node (rewritten)
opt =: 3 : 0
  ir =. y
  NB. Bound: don't loop forever on accidentally non-terminating
  NB. rules. 8 passes is sufficient for the current rewrite rules.
  i =. 0
  while. i < 8 do.
    next =. optPass ir
    NB. Ensure result is always wrapped in 1-box for consistent
    NB. downstream behavior (irOp, irArgs, etc. expect 1-box).
    if. -. 32 = 3!:0 next do. next =. < next end.
    if. (irEqual ((<next) , (<ir))) do.
      ir return.
    end.
    ir =. next
    i =. >: i
  end.
  ir
)

NB. optPass: apply the rewrite rules once, top-down.
NB. y = IR node (boxed or unboxed triple)
NB. Result = IR node (always boxed, i.e., wrapped in 1-box)
optPass =: 3 : 0
  ir =. y
  NB. Ensure ir is boxed for consistent processing.
  if. -. 32 = 3!:0 ir do. ir =. < ir end.
  if. (0 = # ir) +. (ir -: a:) do.
    ir return.
  end.
  NB. First, recurse into children.
  ir =. optChildren ir
  NB. Then apply the rule for this node's opcode.
  op =. irOp ir
  if. op = IR_LIT do.
    NB. IR_LIT is a leaf: nothing to do.
    ir
  elseif. op = IR_REF do.
    NB. IR_REF: apply constant-propagation.
    optRef ir
  elseif. op = IR_CALL do.
    NB. IR_CALL: apply constant-folding.
    optCall ir
  elseif. op = IR_TRAIN2 do.
    optTrain2 ir
  elseif. op = IR_TRAIN3 do.
    optTrain3 ir
  elseif. op = IR_TRAIN do.
    ir
  elseif. op = IR_ADVR do.
    optAdv ir
  elseif. op = IR_CONJ do.
    optConj ir
  elseif. op = IR_ASSN do.
    optAssn ir
  elseif. op = IR_SEQ do.
    ir
  elseif. op = IR_PROG do.
    ir
  else.
    ir
  end.
)

NB. optChildren: rebuild the IR with optimized children.
NB. y = IR node
optChildren =: 3 : 0
  ir =. y
  op =. irOp ir
  if. op = IR_LIT do. ir return. end.
  if. op = IR_REF do. ir return. end.
  if. op = IR_CALL do. optChildrenCall ir return. end.
  if. op = IR_TRAIN2 do. optChildrenTrain2 ir return. end.
  if. op = IR_TRAIN3 do. optChildrenTrain3 ir return. end.
  if. op = IR_TRAIN  do. optChildrenTrain  ir return. end.
  if. op = IR_ADVR do. optChildrenAdv ir return. end.
  if. op = IR_CONJ do. optChildrenConj ir return. end.
  if. op = IR_ASSN do. optChildrenAssn ir return. end.
  if. op = IR_SEQ do. optChildrenSeq ir return. end.
  if. op = IR_PROG do. optChildrenProg ir return. end.
  ir
)

NB. optChildrenCall: rebuild IR_CALL with optimized children.
optChildrenCall =: 3 : 0
  ir =. y
  args =. irArgs ir
  op =. irOp ir
  kids =. args
  if. 3 > # kids do. ir return. end.
  c0 =. optPass 0 { kids
  c1 =. optPass 1 { kids
  c2 =. optPass 2 { kids
  NB. Ensure children are boxed (optPass may return unboxed triples)
  if. -. 32 = 3!:0 c0 do. c0 =. < c0 end.
  if. -. 32 = 3!:0 c1 do. c1 =. < c1 end.
  if. -. 32 = 3!:0 c2 do. c2 =. < c2 end.
  irCall3 (c0 ; c1 ; c2)
)

NB. optChildrenTrain2: rebuild IR_TRAIN2 with optimized children.
optChildrenTrain2 =: 3 : 0
  ir =. y
  args =. irArgs ir
  op =. irOp ir
  kids =. args
  if. 2 > # kids do. ir return. end.
  c0 =. optPass 0 { kids
  c1 =. optPass 1 { kids
  if. -. 32 = 3!:0 c0 do. c0 =. < c0 end.
  if. -. 32 = 3!:0 c1 do. c1 =. < c1 end.
  irTrain2 (c0 ; c1)
)

NB. optChildrenTrain3: rebuild IR_TRAIN3 with optimized children.
optChildrenTrain3 =: 3 : 0
  ir =. y
  args =. irArgs ir
  op =. irOp ir
  kids =. args
  if. 3 > # kids do. ir return. end.
  c0 =. optPass 0 { kids
  c1 =. optPass 1 { kids
  c2 =. optPass 2 { kids
  if. -. 32 = 3!:0 c0 do. c0 =. < c0 end.
  if. -. 32 = 3!:0 c1 do. c1 =. < c1 end.
  if. -. 32 = 3!:0 c2 do. c2 =. < c2 end.
  irTrain3 (c0 ; c1 ; c2)
)

NB. optChildrenTrain: rebuild a generic IR_TRAIN with optimized children.
NB. The generic train has no rewrite rule of its own (yet); this just
NB. recurses so constant folding / propagation can fire inside it.
optChildrenTrain =: 3 : 0
  ir =. y
  args =. irArgs ir
  if. 0 = # args do. ir return. end.
  newKids =. optStmts args
  irTrainN newKids
)

NB. optChildrenAdv: rebuild IR_ADVR with optimized children.
optChildrenAdv =: 3 : 0
  ir =. y
  args =. irArgs ir
  op =. irOp ir
  kids =. args
  if. 2 > # kids do. ir return. end.
  c0 =. optPass 0 { kids
  c1 =. optPass 1 { kids
  if. -. 32 = 3!:0 c0 do. c0 =. < c0 end.
  if. -. 32 = 3!:0 c1 do. c1 =. < c1 end.
  irAdv (c0 ; c1)
)

NB. optChildrenConj: rebuild IR_CONJ with optimized children.
optChildrenConj =: 3 : 0
  ir =. y
  args =. irArgs ir
  op =. irOp ir
  kids =. args
  if. 3 > # kids do. ir return. end.
  c0 =. optPass 0 { kids
  c1 =. optPass 1 { kids
  c2 =. optPass 2 { kids
  if. -. 32 = 3!:0 c0 do. c0 =. < c0 end.
  if. -. 32 = 3!:0 c1 do. c1 =. < c1 end.
  if. -. 32 = 3!:0 c2 do. c2 =. < c2 end.
  irConj (c0 ; c1 ; c2)
)

NB. optChildrenAssn: rebuild IR_ASSN with optimized RHS.
optChildrenAssn =: 3 : 0
  ir =. y
  args =. irArgs ir
  op =. irOp ir
  kids =. args
  if. 2 > # kids do. ir return. end.
  c0 =. 0 { kids
  c1 =. optPass 1 { kids
  if. -. 32 = 3!:0 c0 do. c0 =. < c0 end.
  if. -. 32 = 3!:0 c1 do. c1 =. < c1 end.
  irAssn (c0 ; c1)
)

NB. optChildrenSeq: rebuild IR_SEQ with optimized stmts.
optChildrenSeq =: 3 : 0
  ir =. y
  stmts =. irArgs ir
  op =. irOp ir
  newStmts =. optStmts stmts
  irSeq newStmts
)

NB. optChildrenProg: rebuild IR_PROG with optimized stmts.
optChildrenProg =: 3 : 0
  ir =. y
  stmts =. irArgs ir
  op =. irOp ir
  newStmts =. optStmts stmts
  irProg newStmts
)

NB. optStmts: optimize each statement in a SEQ/PROG list.
optStmts =: 3 : 0
  stmts =. y
  if. 0 = # stmts do.
    stmts
  else.
    head =. optPass 0 { stmts
    rest =. }. stmts
    head , optStmts rest
  end.
)

NB. --- Per-opcode rules -------------------------------------

NB. optCall: constant-folding for binary arithmetic.
NB. If verb is +, -, *, %, ^ and both args are IR_LIT numbers,
NB. evaluate the result and replace the node with IR_LIT.
optCall =: 3 : 0
  ir =. y
  args =. irArgs ir
  verbIr =. 0 { args
  lhs  =. 1 { args
  rhs  =. 2 { args
  if. lhs -: a: do. ir return. end.
  if. (-. isNumericLit lhs) +. (-. isNumericLit rhs) do. ir return. end.
  l =. irArgs lhs
  r =. irArgs rhs
  verbChar =. irArgs verbIr
  folded =. arithFold (verbChar ; l ; r)
  if. folded -: a: do. ir return. end.
  irLit folded
)

NB. isNumericLit: is the IR node an IR_LIT of a number?
NB. y = IR node
NB. Result = 0 or 1
NB.
NB. J 9.7's 3!:0 type codes:
NB.   1: boolean (literal 0 or 1)
NB.   4: integer
NB.   8: float
NB.   16: complex
NB.   32: boxed
NB.   2: char
isNumericLit =: 3 : 0
  if. (0 = # y) +. (y -: a:) do. 0 return. end.
  if. -. (irOp y) = IR_LIT do. 0 return. end.
  v =. irArgs y
  t =. 3!:0 v
  ((1 = t) +. (4 = t) +. (8 = t) +. (16 = t)) > 0
)

NB. arithFold: evaluate a binary arithmetic op on two scalars.
NB. y = boxed triple (verb-char ; lhs-num ; rhs-num)
NB. Result = the result number, or a: if verb not foldable.
NB.
NB. This uses J's built-in `".` to evaluate the operation; we
NB. build the expression and let J compute it. The result is
NB. the numerical answer.
arithFold =: 3 : 0
  'verb lhs rhs' =. y
  if. (1 = # verb) *. verb e. '+-*/%^|<>~' do.
    expr =. (": lhs) , verb , (": rhs)
    ". expr
  elseif. (1 = # verb) *. (verb -: '*:') do.
    NB. monadic square, only folds for monadic
    if. 1 do. a: end.
  else.
    a:
  end.
)

NB. optTrain2: identity elimination for hooks.
NB.   (] v) y  ->  v y
NB.   (u ]) y  ->  u y
NB. If one side is a reference to the identity verb, the other
NB. side is the result.
optTrain2 =: 3 : 0
  ir =. y
  args =. irArgs ir
  if. 2 > # args do. ir return. end.
  u =. 0 { args
  v =. 1 { args
  if. isRefTo (u ; ']') do. v return. end.
  if. isRefTo (v ; ']') do. u return. end.
  ir
)

NB. optTrain3: identity / cap elimination for forks.
NB.   (] v w) y  ->  (v w) y
NB.   (u v ]) y  ->  (u v) y
NB.   ([ v ]) y  ->  v y
optTrain3 =: 3 : 0
  ir =. y
  args =. irArgs ir
  if. 3 > # args do. ir return. end.
  u =. 0 { args
  v =. 1 { args
  w =. 2 { args
  NB. Check ([ v ]) first since w=']' would also match the (u v ]) pattern
  if. (isRefTo (u ; '[')) *. (isRefTo (w ; ']')) do. v return. end.
  if. isRefTo (u ; ']') do. optTrain3HookL (v ; w) return. end.
  if. isRefTo (w ; ']') do. optTrain3HookR (u ; v) return. end.
  ir
)

NB. optTrain3HookL: optTrain3 helper for (] v w) case.
optTrain3HookL =: 3 : 0
  'v w' =. y
  if. isRefTo (w ; ']') do. < v return. end.
  < irTrain2 (v ; w)
)

NB. optTrain3HookR: optTrain3 helper for (u v ]) case.
optTrain3HookR =: 3 : 0
  'u v' =. y
  < irTrain2 (u ; v)
)

NB. optRef: constant propagation. If the name is bound to a
NB. literal somewhere in scope, substitute the literal.
NB.
NB. NB: Stage 0 keeps a per-program binding map threaded
NB. through opt; see `optWithEnv`. The default `opt` is a
NB. single-pass over the AST with the env built up as it
NB. walks. For the Stage 0 rewrite engine this is enough --
NB. a more sophisticated dataflow pass is a Stage 3 item.
optRef =: 3 : 0
  ir =. y
  name =. irArgs ir
  env =. optEnvGet ''
  if. -. (env -: a:) do.
    binding =. envLookup env ; name
    if. -. (binding -: a:) do.
      binding
      return.
    end.
  end.
  ir
)

NB. optAdv / optConj: structure-preserving pass for now.
optAdv =: ]  NB. identity
optConj =: ]  NB. identity

NB. optAssn: record name -> rhs in the env (if rhs is a
NB. simple literal; otherwise it's a non-foldable binding).
NB.
NB. After recording, the IR_ASSN node is returned as-is.
optAssn =: 3 : 0
  ir =. y
  args =. irArgs ir
  nameIr =. 0 { args
  rhs  =. 1 { args
  if. (irOp rhs) = IR_LIT do.
    NB. nameIr is an IR_REF; extract the name string
    name =. irArgs nameIr
    optEnvPut (name ; rhs)
  end.
  ir
)

NB. isRefTo: is the IR node a reference to the given name?
NB. y = (ir ; name)
NB. Result = 0 or 1
isRefTo =: 3 : 0
  'ir name' =. y
  if. (0 = # ir) +. (ir -: a:) do. 0 return. end.
  if. -. (irOp ir) = IR_REF do. 0 return. end.
  (irArgs ir) -: name
)

NB. --- Optimizer environment (constant propagation) ---------

NB. optEnv: boxed scalar holding a 2-col matrix of
NB. (name ; binding-IR). `a:` if empty.
NB.
NB. The env is shared across the optimizer via these thread-
NB. local helpers. We use a global boxed scalar so the value
NB. can be passed through a chain of `optRef` calls cheaply.
optEnv =: <a:

NB. optEnvGet: read the env.
optEnvGet =: 3 : 0
  > optEnv
)

NB. optEnvPut: update the env with (name ; binding).
NB. y = (name ; bindingIR)
optEnvPut =: 3 : 0
  'name binding' =. y
  env =. > optEnv
  if. env -: a: do.
    NB. First entry: create 2-col matrix
    optEnv =: < (<name) , (<binding)
  else.
    NB. Append; allow duplicates (last wins at lookup).
    NB. env is a 2-elem boxed list (names ; bindings)
    names =. 0 { env
    binds =. 1 { env
    optEnv =: < (names , <name) , (binds , <binding)
  end.
  EMPTY
)

NB. envLookup: find the most recent binding for name in env.
NB. y = (env ; name)
NB. Result = binding-IR, or a: if not found.
envLookup =: 3 : 0
  'env name' =. y
  if. env -: a: do. a: return. end.
  names =. 0 { env
  binds =. 1 { env
  NB. names is a boxed list of name atoms, search for name
  idx =. names i. <name
  if. idx < # names do.
    idx { binds
  else.
    a:
  end.
)

NB. --- Equality & utility -----------------------------------

NB. irEqual: structural equality of two IR nodes.
NB. y = boxed pair (ir1 ; ir2)
NB. Result = 0 or 1
NB.
NB. We compare the unparsed J source rather than the raw boxed
NB. args, because the IR constructors use `;` (link) which boxes
NB. elements inconsistently (e.g. the last child of a 3-train ends
NB. up at a different box depth than the first two). A raw `+:`
NB. (match) on irArgs would therefore report two semantically
NB. identical IRs as unequal, making `opt` loop until `unboxIr`'s
NB. depth limit overflows. Unparsing normalises the boxing, so this
NB. is a sound fixed-point test (and matches what the pipeline
NB. actually emits).
irEqual =: 3 : 0
  'a b' =. y
  aEmpty =. a -: a:
  bEmpty =. b -: a:
  if. aEmpty do.
    if. bEmpty do. 1 return. end.
    0 return.
  end.
  if. bEmpty do. 0 return. end.
  (unparseIr a) -: unparseIr b
)

NB. resetOptEnv: clear the env. Tests call this between
NB. optimization runs to keep state isolated.
resetOptEnv =: 3 : 0
  optEnv =: <a:
  EMPTY
)

NB. optWithEnv: optimize a program with a fresh env.
NB. y = IR node
NB. Result = IR node
optWithEnv =: 3 : 0
  resetOptEnv ''
  opt y
)

NB. --- Solon / MDL cost stub (sketch) -----------------------

NB. mdlCost: sketch of a Minimum Description Length cost function
NB. for an IR. Currently returns the node count. A full
NB. implementation would weight by (a) the cost of the rule
NB. productions, and (b) the negative log-likelihood of the
NB. data given the rule. See SPEC.md §8 for the integration
NB. plan.
NB.
NB. y = IR node
NB. Result = non-negative number
mdlCost =: 3 : 0
  ir =. y
  if. (0 = # ir) +. (ir -: a:) do. 0 return. end.
  op =. irOp ir
  args =. irArgs ir
  base =. opCost op
  if. 32 = 3!:0 args do.
    NB. Boxed scalar: no children
    base
  else.
    NB. Boxed vector: sum of children's cost + 1 per child link
    childCost =. 0
    for_i. i. # args do.
      childCost =. childCost + mdlCost i { args
    end.
    base + childCost
  end.
)

NB. opCost: per-opcode constant (the "rule cost" half of MDL).
NB. These are placeholder values; tune in Stage 3.
opCost =: 3 : 0
  op =. y
  if.     op = IR_LIT    do. 1
  elseif. op = IR_REF    do. 1
  elseif. op = IR_CALL   do. 3
  elseif. op = IR_TRAIN2 do. 2
  elseif. op = IR_TRAIN3 do. 2
  elseif. op = IR_TRAIN  do. 2
  elseif. op = IR_ADVR   do. 3
  elseif. op = IR_CONJ   do. 4
  elseif. op = IR_ASSN   do. 2
  elseif. op = IR_SEQ    do. 1
  elseif. op = IR_PROG   do. 1
  else.                     0
  end.
)
