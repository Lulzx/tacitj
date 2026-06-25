NB. ============================================================
NB. mdl.ijs - Solon-style MDL cost and grammar induction
NB. ============================================================
NB. Implements SPEC §8: a Minimum Description Length cost function
NB. for IRs and a frequency-based grammar induction that finds
NB. common subexpressions across a corpus.
NB.
NB. The MDL cost decomposes as:
NB.
NB.   mdl(IR) = grammar_cost(IR) + data_cost(IR)
NB.
NB. grammar_cost is a per-opcode constant (the cost of the rule
NB. productions). data_cost is the size of literal values.
NB.
NB. The grammar inducer walks every IR in the corpus and collects
NB. structurally-identical sub-IRs (identified by their unparsed
NB. string). The most common ones are the "grammar" the corpus
NB. is using. This is a Solon-style frequency count, not full
NB. Bayesian inference, but it surfaces the same kind of pattern
NB. signal.
NB.
NB. The MDL minimizer is an alternative to the rule-based `opt`
NB. in src/opt.ijs. It generates candidate rewrites from
NB. optPass and picks the lowest-MDL-cost variant. Both
NB. minimizers can be used in sequence; the rule-based one is
NB. faster, the MDL one is more principled for tie-breaking.

load 'src/ir.ijs'
load 'src/opt.ijs'

NB. --- Per-opcode cost (the grammar half of MDL) ----

NB. opMdlCost: the "grammar" cost of a single opcode.
NB. Larger values mean the rule is more expensive (so we should
NB. prefer to eliminate uses of it). A train-3 fork is cheaper
NB. than a generic call because a fork is more compact.
opMdlCost =: 3 : 0
  op =. y
  if.     op = IR_LIT    do. 1     NB. literal: cheap (a name binding)
  elseif. op = IR_REF    do. 1     NB. name reference
  elseif. op = IR_CALL   do. 4     NB. generic call: expensive
  elseif. op = IR_TRAIN2 do. 2     NB. hook: cheaper than call
  elseif. op = IR_TRAIN3 do. 2     NB. fork: cheaper than call
  elseif. op = IR_TRAIN  do. 2     NB. n-train: same as train2/3
  elseif. op = IR_ADVR   do. 3     NB. adverb application
  elseif. op = IR_CONJ   do. 3     NB. conjunction application
  elseif. op = IR_ASSN   do. 2     NB. assignment
  elseif. op = IR_SEQ    do. 1     NB. sequence
  elseif. op = IR_PROG   do. 1     NB. program
  else.                     0
  end.
)

NB. --- MDL score for an IR ---

NB. mdlScore: total MDL cost = sum over all nodes of opMdlCost,
NB. plus data cost for literals (length of the literal value).
NB.
NB. y = IR node (boxed triple)
NB. Result = non-negative number
mdlScore =: 3 : 0
  ir =. y
  NB. IR nodes may be wrapped in 1-box (from list selection) and
  NB. another 1-box (from the original irCall etc). Use unboxIr
  NB. to peel off all the wrappers until we hit the 3-element
  NB. representation.
  ir =. unboxIr ir
  if. (0 = # ir) +. (ir -: a:) do. 0 return. end.
  op =. irOp ir
  args =. irArgs ir
  base =. opMdlCost op
  data =. 0
  if. op = IR_LIT do.
    NB. Add 1 per char in the literal value (data cost).
    lit =. > 1 { ir
    if. 2 = 3!:0 lit do.
      data =. # lit
    elseif. 32 = 3!:0 lit do.
      data =. 1    NB. boxed literal: cost 1
    else.
      data =. 1
    end.
  end.
  childCost =. 0
  NB. Traverse children only if args is a non-empty boxed vector.
  if. (32 = 3!:0 args) *. (0 < # args) do.
    for_i. i. # args do.
      childCost =. childCost + mdlScore i { args
    end.
  end.
  base + data + childCost
)

NB. --- Grammar induction over a corpus ---

NB. allSubIrs: collect every sub-IR of y (including y itself).
NB. Walks the IR recursively. Returns a boxed list of IR nodes.
allSubIrs =: 3 : 0
  ir =. y
  if. (0 = # ir) +. (ir -: a:) do. a: return. end.
  out =. ,<ir
  args =. irArgs ir
  if. (32 -. -: 3!:0 args) *. (0 < # args) do.
    for_i. i. # args do.
      out =. out , allSubIrs i { args
    end.
  end.
  out
)

NB. grammarInduce: count structurally-identical sub-IRs across
NB. a corpus. Returns a boxed list of 3-boxes (count ; key ;
NB. sample), sorted by count descending.
NB.
NB. y = boxed list of IR nodes (the corpus)
NB. Result = boxed list of 3-boxes (count ; key ; sample)
grammarInduce =: 3 : 0
  corpus =. y
  if. 0 = # corpus do. (0 3 $ a:) return. end.
  NB. Collect every (key, sample) pair across the corpus.
  NB. Init as 0x2 matrix so `,` appends rows (not flattens).
  pairs =. 0 2 $ a:
  i =. 0
  while. i < # corpus do.
    subs =. allSubIrs i { corpus
    j =. 0
    while. j < # subs do.
      s =. j { subs
      NB. Wrap each element to a consistent 1-box level so
      NB. downstream column extraction is uniform.
      pairs =. pairs , (<unparseIr s) , <s
      j =. >: j
    end.
    i =. >: i
  end.
  if. 0 = # pairs do. (0 3 $ a:) return. end.
  NB. Group by key. pairs is a 2-column matrix where col 0 is
  NB. the unparsed-string key and col 1 is the sample IR.
  keys =. 0 {"1 pairs
  uniqKeys =. ~. keys
  NB. For each unique key, count and pick a sample.
  out =. 0 3 $ a:
  k =. 0
  while. k < # uniqKeys do.
    uk =. k { uniqKeys
    mask =. keys = uk
    count =. +/ mask
    NB. Find the first sample matching this key.
    where =. mask # i. # mask
    sampleRow =. 0 { where { pairs
    sample =. 1 { sampleRow    NB. the IR column
    NB. Build the row: count (unboxed scalar), uk (1-box), sample (1-box).
    NB. To keep all three at the same level for downstream
    NB. extraction, wrap count too. Note: uk is itself a 1-box
    NB. from `0 { keys`, so we need to unbox once before re-boxing.
    row =. (<count) , (< > uk) , <sample
    out =. out , row
    k =. >: k
  end.
  NB. Sort by count descending. J's sort is stable.
  counts =. 0 {"1 out
  NB. Use /: for grade-up, then reverse for descending.
  order =. (\: counts)
  order { out
)

NB. --- MDL minimizer ---

NB. mdlMinimize: run MDL-driven rewriting on an IR. Generates
NB. candidates from optPass and picks the lowest-MDL-cost
NB. variant. Repeats until cost stops decreasing or a safety
NB. bound is hit.
NB.
NB. y = IR node
NB. Result = IR node (possibly smaller / lower-cost)
mdlMinimize =: 3 : 0
  ir =. y
  if. (0 = # ir) +. (ir -: a:) do. ir return. end.
  bestScore =. mdlScore ir
  best =. <ir
  i =. 0
  while. i < 8 do.
    next =. optPass ir
    if. -. 32 = 3!:0 next do. next =. < next end.
    s =. mdlScore (<next)
    if. s < bestScore do.
      bestScore =. s
      best =. <next
      ir =. best
    else.
      i =. >: i
    end.
  end.
  best
)

NB. --- Driver ---

NB. mdlDemo: a one-shot demo of MDL scoring and grammar
NB. induction. Picks a small corpus, scores it, finds common
NB. sub-IRs, and runs the MDL minimizer on each.
mdlDemo =: 3 : 0
  smoutput 'MDL demo'
  smoutput '========'
  smoutput ''
  NB. Build a small corpus: 1 + 2, 1 * 2, 1 + 3, 2 * 3
  irAdd12 =. irCall ((irLit '+') ; (irLit 1) ; (irLit 2))
  irMul12 =. irCall ((irLit '*') ; (irLit 1) ; (irLit 2))
  irAdd13 =. irCall ((irLit '+') ; (irLit 1) ; (irLit 3))
  irMul23 =. irCall ((irLit '*') ; (irLit 2) ; (irLit 3))
  corpus =. irAdd12 ; irMul12 ; irAdd13 ; irMul23

  smoutput 'Corpus MDL scores:'
  i =. 0
  while. i < # corpus do.
    s =. mdlScore i { corpus
    smoutput '  corpus[' , (": i) , ']: MDL=' , (": s)
    i =. >: i
  end.

  smoutput ''
  smoutput 'Total MDL cost (sum): '
  smoutput ": +/ mdlScore &> corpus

  smoutput ''
  smoutput 'Grammar induction (top patterns):'
  pat =. grammarInduce corpus
  i =. 0
  while. i < # pat do.
    row =. i { pat
    smoutput '  ' , (": 0 { row) , 'x  ' , (> 1 { row)
    i =. >: i
  end.

  smoutput ''
  smoutput 'MDL minimizer (each corpus IR):'
  i =. 0
  while. i < # corpus do.
    before =. mdlScore i { corpus
    min   =. mdlMinimize i { corpus
    after  =. mdlScore min
    smoutput '  corpus[' , (": i) , ']: ' , (": before) , ' -> ' , (": after)
    i =. >: i
  end.

  0
)