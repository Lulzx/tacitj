NB. ============================================================
NB. parse.ijs - TacitJ Parser
NB. ============================================================
NB. Recursive-descent parser for J-Tacit-Core. Input: token list
NB. (output of `lex`). Output: boxed AST.
NB.
NB. AST node shape: 2-box (tag ; payload) with both elements boxed.
NB.   tag: numeric (AST_* constants)
NB.   payload depends on tag:
NB.     - NOON/STR/NAME/VERB/ADV/CONJ : boxed scalar value
NB.     - TRAIN  : boxed 2- or 3-vector of child ASTs
NB.     - EXPR   : boxed vector of child ASTs (flat sequence)
NB.     - ASSIGN : boxed pair (name, expr)
NB.     - SENT   : boxed scalar containing ASSIGN or EXPR
NB.
NB. Convention for "return a pair": wrap in a 1-box to avoid J's
NB. unrolling of 2-boxes during catenation. Caller does:
NB.   'a b' =. > func arg

NB. --- AST tags --------------------------------------------
AST_NOON   =: 0
AST_STR    =: 1
AST_NAME   =: 2
AST_VERB   =: 3
AST_ADV    =: 4
AST_CONJ   =: 5
AST_TRAIN  =: 6
AST_EXPR   =: 7
AST_ASSIGN =: 8
AST_SENT   =: 9

NB. AST tag labels (for diagnostics)
AST_LABELS =: 'NOON';'STR';'NAME';'VERB';'ADV';'CONJ';'TRAIN';'EXPR';'ASSIGN';'SENT'

NB. --- Token-to-AST tag mapping ---------------------------

NB. tokenToAst: convert a single boxed token into an AST leaf.
NB. Returns 0 for tokens that do not correspond to a leaf.
NB. y = boxed 1-box wrapping a 2-box token
tokenToAst =: 3 : 0
  t =. tokType y
  v =. tokValue y
  if.     t = T_NAME do. (<AST_NAME) ; <v
  elseif. t = T_NUM  do. (<AST_NOON) ; <(0 ". v)
  elseif. t = T_STR  do. (<AST_STR)  ; <v
  elseif. t = T_VERB do. (<AST_VERB) ; <,v
  elseif. t = T_ADV  do. (<AST_ADV)  ; <,v
  elseif. t = T_CONJ do. (<AST_CONJ) ; <,v
  elseif.            do. 0  NB. not a leaf
  end.
)

NB. isOperator: is this AST node an operator (verb/adv/conj)?
NB. y = AST node (1-box wrapping 2-box)
isOperator =: 3 : 0
  t =. > 0 { > y
  t e. AST_VERB , AST_ADV , AST_CONJ
)

NB. isTerm: is this AST node a term (not an operator)?
NB. y = AST node
isTerm =: 3 : '-. isOperator y'

NB. --- Top-level entry: program -> list of sentence ASTs ---

NB. parseProgram: parse a token list into a boxed vector of
NB. sentence AST nodes.
NB. y = boxed vector of 1-box tokens
NB. Result = boxed vector of 1-box AST_SENT nodes
parseProgram =: 3 : 0
  toks =. y
  parseProgRec toks
)

NB. parseProgRec: (toks) -> boxed list of 1-box AST_SENT nodes
parseProgRec =: 3 : 0
  toks =. y
  out =. 0 $ a:
  while. 0 < # toks do.
    t0 =. tokType 0 { toks
    if. t0 = T_EOF do.
      toks =. 0 $ a:
    else.
      pair =. parseSentence toks
      'sent consumed' =. pair
      out =. out , <sent
      toks =. consumed
    end.
  end.
  out
)

NB. parseSentence: parse one sentence.
NB. y = boxed vector of 1-box tokens
NB. Result = 1-box wrapping (ast-node ; remaining-tokens)
parseSentence =: 3 : 0
  toks =. y
  isAssign =. (1 < # toks) *. ((tokType 0 { toks) = T_NAME) *. ((tokType 1 { toks) = T_ASSIGN)
  if. isAssign do.
    nameAst =. tokenToAst 0 { toks
    rest    =. 2 }. toks
    pair =. parseExpr rest
    'expr rest2' =. pair
    sent =. ((<AST_SENT) ; <((<AST_ASSIGN) ; (<nameAst ; <expr)))
    (sent) ; <rest2
  else.
    pair =. parseExpr toks
    'expr rest2' =. pair
    sent =. ((<AST_SENT) ; <((<AST_EXPR) ; <,expr))
    (sent) ; <rest2
  end.
)

NB. parseExpr: parse an expression.
NB. y = boxed vector of 1-box tokens
NB. Result = 1-box wrapping (ast-node ; remaining-tokens)
NB. To avoid J's unrolling of 2-boxes, we explicitly box each
NB. side of the pair, then `;` them as 2-boxes-of-boxes.
parseExpr =: 3 : 0
  toks =. y
  'flat rest' =. > parseTerms toks
  grouped =. groupTrains flat
  expr =. ((<AST_EXPR) ; <grouped)
  NB. Return a 1-box wrapping a 2-box: [<expr, <rest]
  (<expr) ; <rest
)

NB. parseTerms: (toks) -> 2-box [<out, <toks]
NB. Consumes a sequence of terms and operators. Stops at
NB. T_EOF, T_RPAREN, T_ASSIGN.
parseTerms =: 3 : 0
  toks =. y
  out =. 0 $ a:
  while. 0 < # toks do.
    t0 =. tokType 0 { toks
    if. (t0 = T_EOF) +. (t0 = T_RPAREN) +. (t0 = T_ASSIGN) do.
      break.
    elseif. t0 = T_LPAREN do.
      pair =. parseExpr 1 }. toks
      'inner rest' =. pair
      out =. out , <inner
      toks =. rest
    else.
      ast =. tokenToAst 0 { toks
      if. ast = 0 do.
        break.
      else.
        out =. out , <ast
        toks =. 1 }. toks
      end.
    end.
  end.
  NB. Return a 2-box [<out, <toks]
  <out ; <toks
)

NB. groupTrains: group runs of consecutive terms into AST_TRAIN.
NB. y = boxed vector of 1-box AST nodes
NB. Result = boxed vector of 1-box AST nodes (with AST_TRAIN inserted)
groupTrains =: 3 : 0
  children =. y
  if. 0 = # children do.
    children
  else.
    goRound children
  end.
)

NB. goRound: (children) -> boxed vector with trains inserted.
goRound =: 3 : 0
  children =. y
  result =. 0 $ a:
  i =. 0
  lim =. # children
  while. i < lim do.
    c =. i { children
    if. isTerm c do.
      run =. 0 $ a:
      j =. i
      while. j < lim do.
        e =. j { children
        if. isTerm e do.
          run =. run , <e
          j =. >: j
        else.
          break.
        end.
      end.
      rc =. # run
      if. rc = 2 do.
        result =. result , <((<AST_TRAIN) ; <run)
      elseif. rc = 3 do.
        result =. result , <((<AST_TRAIN) ; <run)
      elseif. rc = 1 do.
        result =. result , <(> 0 { run)
      else.
        result =. result , run
      end.
      i =. j
    else.
      result =. result , <c
      i =. >: i
    end.
  end.
  result
)

NB. --- AST utilities ---------------------------------------

NB. astTag: extract the tag of an AST node (unboxed number)
NB. y = AST node (1-box wrapping 2-box)
astTag =: 3 : 0
  if. 0 = # y do. _1 return. end.
  > 0 { > y
)

NB. astPayload: extract the payload of an AST node
NB. y = AST node
NB.
NB. The shape of the returned value depends on the node kind. Callers
NB. are responsible for knowing which kind they're dealing with.
NB.   - NOON / STR / VERB / ADV / CONJ : unboxed scalar value
NB.   - EXPR / TRAIN : the 2-box payload (tag, children-vector)
NB.   - ASSIGN / SENT : the 2-box payload (tag, inner-payload)
NB.
NB. NB: the EXPR/SENT payloads in this Stage 0 parser use a
NB. heterogeneous 2-box convention that downstream consumers (the
NB. IR lowerer) handle explicitly. The optimizer works on the IR,
NB. not the AST, so it doesn't need a clean AST view.
astPayload =: 3 : 0
  if. 0 = # y do. '' return. end.
  t =. astTag y
  > 1 { > y
)

NB. formatAst: pretty-print an AST (for diagnostics)
NB. y = AST (program: list of sentence nodes, or single node)
formatAst =: 3 : 0
  if. 0 = # y do. '' return. end.
  shape =. $ y
  if. 1 = # shape do.
    n =. # y
    out =. ''
    for_i. i. n do.
      out =. out , formatNode i { y
      out =. out , LF
    end.
    out
  else.
    formatNode y
  end.
)

NB. formatNode: pretty-print one AST node
NB. (Stage 0 diagnostic helper. The optimizer / IR layer is the
NB. real consumer of the AST.)
formatNode =: 3 : 0
  t =. astTag y
  tagName =. > ({. t) { AST_LABELS
  if. t = AST_NOON do.
    p =. > astPayload y
    tagName , ' ' , ": p
  elseif. t = AST_STR do.
    p =. > astPayload y
    tagName , ' ' , QUOTE , p , QUOTE
  elseif. t = AST_NAME do.
    p =. > astPayload y
    tagName , ' ' , p
  elseif. (t = AST_VERB) +. (t = AST_ADV) +. (t = AST_CONJ) do.
    p =. > astPayload y
    tagName , ' ' , p
  elseif. t = AST_TRAIN do.
    p =. astPayload y
    tagName , ' [ ' , ([: ; (', ' ,~ formatNode) "0 p) , ' ]'
  elseif. t = AST_EXPR do.
    p =. astPayload y
    tagName , ' [ ' , ([: ; (', ' ,~ formatNode) "0 p) , ' ]'
  elseif. t = AST_ASSIGN do.
    p =. astPayload y
    n =. > 0 { p
    e =. > 1 { p
    tagName , ' ' , formatNode n , ' =: ' , formatNode e
  elseif. t = AST_SENT do.
    p =. astPayload y
    formatNode > p
  else.
    tagName
  end.
)
