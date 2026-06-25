NB. ============================================================
NB. lex.ijs - TacitJ Lexer
NB. ============================================================
NB. Tokenises a TacitJ source string into a boxed vector of tokens.
NB. Each token is a 2-box: (type ; value) where each element is a
NB. boxed scalar. Type is a number (T_* constant), value is a
NB. char vector or number.
NB.
NB. The token list is a boxed vector of 1-boxes; each 1-box wraps
NB. a 2-box token. This wrapping prevents J from unrolling the
NB. 2-box during catenation.
NB.
NB. The top-level `lex` returns a boxed vector whose last element is
NB. the T_EOF sentinel.

NB. --- Token type constants --------------------------------
T_NAME   =: 0
T_VERB   =: 1
T_ADV    =: 2
T_CONJ   =: 3
T_NUM    =: 4
T_STR     =: 5
T_LPAREN  =: 6
T_RPAREN  =: 7
T_ASSIGN  =: 8
T_EOF     =: 9
T_SENT_END=: 10
T_BAD     =: _1

NB. --- Character sets --------------------------------------
ALPHA     =: 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
NAME_CONT =: ALPHA , '0123456789_'
DIGITS    =: '0123456789'
PRIM_VERB =: '+-*%^=<>|&~;,$#?![]'
PRIM_ADV  =: '/\~.:'
PRIM_CONJ =: '@&^!'
WS_CHARS  =: ' ' , TAB , CR , LF
QUOTE     =: ''''

NB. Token-type labels (for diagnostics)
T_LABELS =: 'NAME';'VERB';'ADV';'CONJ';'NUM';'STR';'LPAREN';'RPAREN';'ASSIGN';'EOF';'SENT';'BAD'

NB. Sentinels for sentence-end and end-of-input.
SENT_END =: T_SENT_END
EOF_CODE =: T_EOF

NB. --- Comment stripping -----------------------------------

NB. hasNB: does char vector y contain the substring 'NB.'?
NB. Returns 0 or 1.
hasNB =: 3 : 0
  if. 3 <: # y do.
    0 < +/ 'NB.' E. y
  else.
    0
  end.
)

NB. noNB: complement of hasNB. 1 if y does NOT contain 'NB.'.
noNB =: 3 : '-. hasNB y'

NB. trimLeft: remove leading spaces from a char vector
NB. y is a char vector. Result is char vector with leading spaces removed.
trimLeft =: 3 : '(-. (y = '' '')) # y'

NB. isCommentLine: 1 if y (a char vector) is a comment line.
NB. A line is a comment if its first 3 chars are 'NB.' after trimLeft.
isCommentLine =: 3 : 0
  t =. trimLeft y
  if. 3 <: # t do.
    (3 {. t) -: 'NB.'
  else.
    0
  end.
)

NB. stripComment: remove 'NB. ...' from a single line.
NB. y is a char vector. Result is the line with comment removed
NB. (or unchanged if no comment).
stripComment =: 3 : 0
  line =. y
  NB. Use {. to take the first match (i. may return multiple for short y).
  pos =. {. line i. 'NB.'
  if. pos < # line do.
    pos {. line
  else.
    line
  end.
)

NB. splitOnLF: split a char vector on LF, returning a boxed list
NB. of lines (without the LF separators).
NB. y is a char vector. Result is boxed list of char vectors.
splitOnLF =: 3 : 0
  src =. y
  positions =. (src = LF) # i. # src
  if. 0 = # positions do.
    <src
  else.
    NB. Build segments using a loop (avoids self-cut issues)
    starts =. 0 , 1 + positions
    ends =. positions , # src
    n =. # starts
    segs =. 0 $ <''
    for_i. i. n do.
      s =. i { starts
      e =. i { ends
      seg =. (e - s) {. s }. src
      segs =. segs , <seg
    end.
    segs
  end.
)






NB. joinLines: join a boxed list of char vectors with LF separators.
NB. y is a boxed list of char vectors. Result is a single char vector.
joinLines =: 3 : 0
  lines =. y
  n =. # lines
  if. n = 0 do.
    ''
  elseif. n = 1 do.
    > 0 { lines
  else.
    first =. > 0 { lines
    rest =. }. lines
    first , LF , joinLines rest
  end.
)


NB. stripComments: remove comments from source.
NB. y is a char vector. Result is char vector with comments removed.
stripComments =: 3 : 0
  src =. y
  lines =. splitOnLF src
  cleaned =. stripLines lines
  joinLines cleaned
)

NB. stripLines: strip comments from a boxed list of lines.
NB. y is a boxed list of char vectors. Result is a boxed list of
NB. stripped char vectors (same length as y).
stripLines =: 3 : 0
  lines =. y
  n =. # lines
  out =. ''
  i =. 0
  while. i < n do.
    out =. out , < stripComment > i { lines
    i =. >: i
  end.
  out
)






NB. --- Reader helpers (return end position) ---------------

NB. readName: arg = (pos ; src) -> endPos
NB. Reads [a-zA-Z][a-zA-Z0-9_]*
readName =: 3 : 0
  'p src' =. y
  lim =. # src
  if. (p < lim) *. (p { src) e. ALPHA do.
    q =. >: p
    while. (q < lim) *. (q { src) e. NAME_CONT do.
      q =. >: q
    end.
    q
  else.
    p
  end.
)

NB. readNumber: arg = (pos ; src) -> endPos
NB. Reads [0-9]+ ('.' [0-9]+)?
readNumber =: 3 : 0
  'p src' =. y
  lim =. # src
  q =. p
  while. (q < lim) *. (q { src) e. DIGITS do.
    q =. >: q
  end.
  if. (q < lim) *. (q { src) = '.' do.
    q =. >: q
    while. (q < lim) *. (q { src) e. DIGITS do.
      q =. >: q
    end.
  end.
  q
)

NB. readString: arg = (pos ; src) -> endPos (position after closing quote)
NB. Supports doubled-quote ('') as an escape for one quote.
readString =: 3 : 0
  'p src' =. y
  lim =. # src
  q =. >: p                    NB. skip opening quote
  while. q < lim do.
    if. (q { src) = QUOTE do.
      if. ((q + 1) < lim) *. ((q + 1) { src) = QUOTE do.
        q =. >: q              NB. skip first of doubled quote
      else.
        q =. >: q              NB. skip closing quote
        break.
      end.
    end.
    q =. >: q
  end.
  q
)

NB. collapseDoubledQuotes: turn every occurrence of QUOTE,QUOTE
NB. in y into a single QUOTE, and drop the rest of the QUOTEs.
NB. E.g. "it''s" -> "it's", "hello" -> "hello".
collapseDoubledQuotes =: 3 : 0
  s =. y
  lim =. # s
  i =. 0
  out =. ''
  while. i < lim do.
    if. (i + 1) < lim do.
      if. ((i { s) = QUOTE) *. (((>: i) { s) = QUOTE) do.
        out =. out , ,QUOTE
        i =. i + 2
      elseif. (i { s) = QUOTE do.
        NB. stray quote: skip
        i =. >: i
      else.
        out =. out , (i { s)
        i =. >: i
      end.
    elseif. (i { s) = QUOTE do.
      NB. trailing stray quote
      i =. >: i
    else.
      out =. out , (i { s)
      i =. >: i
    end.
  end.
  out
)

NB. --- Top-level lexer -------------------------------------

NB. lex: tokenise source char vector y.
NB. Returns a boxed vector of tokens. Last token is always T_EOF.
NB.
NB. Sentence boundaries: at depth 0 (paren-balanced), a line
NB. feed (LF) ends a sentence. The lexer emits a T_SENT_END
NB. token between sentences. T_SENT_END is only emitted when
NB. the line has at least one token (i.e. not for blank lines
NB. or comment-only lines), and only when followed by another
NB. token on a later line.
lex =: 3 : 0
  src =. stripComments y
  src =. src , LF              NB. sentinel newline to flush trailing token
  toks =. 0 $ a:               NB. empty boxed list (0-element)
  p   =. 0
  lim =. # src
  depth =. 0                   NB. paren depth for sentence boundaries
  lineHasTok =. 0              NB. did the current line have any token?
  while. p < lim do.
    c =. p { src
    if. c = '(' do.
      toks =. toks , <((<T_LPAREN) ; <'(')
      lineHasTok =. 1
      depth =. >: depth
      p =. >: p
    elseif. c = ')' do.
      toks =. toks , <((<T_RPAREN) ; <')')
      lineHasTok =. 1
      depth =. <: depth
      p =. >: p
    elseif. c = LF do.
      NB. End-of-sentence marker at depth 0, only if this
      NB. line had at least one token AND the line after has
      NB. one too (otherwise it's trailing whitespace / EOF).
      if. (depth = 0) *. lineHasTok do.
        NB. peek past whitespace for the next non-WS char.
        NB. Use a guarded loop (test bound first) to avoid the
        NB. `*.` short-circuit pitfall.
        q =. >: p
        while. q < lim do.
          if. (q { src) e. (TAB , ' ' , CR) do.
            q =. >: q
          else.
            break.
          end.
        end.
        NB. Only emit SENT_END if there's a non-LF token after.
        if. q < lim do.
          nc =. q { src
          if. nc -. LF do.
            toks =. toks , <((<T_SENT_END) ; <LF)
          end.
        end.
      end.
      lineHasTok =. 0
      p =. >: p
    elseif. c e. (TAB , ' ' , CR) do.
      p =. >: p
    else.
      'tok endP' =. lexOne (p ; src)
      toks =. toks , <tok
      p =. endP
      lineHasTok =. 1
      t0 =. tokType <tok
      if. t0 = T_LPAREN do. depth =. >: depth end.
      if. t0 = T_RPAREN do. depth =. <: depth end.
    end.
  end.
  toks , <((<T_EOF) ; <'')
)

NB. lexOne: arg = (pos ; src) -> (token ; endPos)
NB. Returns a 2-element list [token-2-box, endPos].
NB. token-2-box is (<type) ; <value.
lexOne =: 3 : 0
  'p src' =. y
  c =. p { src
  lim =. # src
  if. c = '(' do.
    ((<T_LPAREN) ; <'(') ; (>: p)
  elseif. c = ')' do.
    ((<T_RPAREN) ; <')') ; (>: p)
  elseif. c = QUOTE do.
    endP =. readString (p ; src)
    body =. ((>: p) }. (<: endP) {. src)
    raw  =. collapseDoubledQuotes body
    ((<T_STR) ; <raw) ; endP
  elseif. (c = '=') *. ((p + 1) < lim) *. (((p + 1) { src) -: ':') do.
    ((<T_ASSIGN) ; <,'=:'); p + 2
  elseif. (c e. ('*' , '%' , '^' , '|' , '<' , '>' , '~')) *. ((p + 1) < lim) *. ((p + 1) { src) = ':' do.
    NB. Two-char verb: *: %: ^: |: <: >: ~: (square, root, log, reverse,
    NB. increment, decrement, not-equal).
    ((<T_VERB) ; <(c , ':')) ; (>: >: p)
  elseif. c e. PRIM_VERB do.
    ((<T_VERB) ; <,c) ; (>: p)
  elseif. c e. PRIM_ADV do.
    ((<T_ADV) ; <,c) ; (>: p)
  elseif. c e. PRIM_CONJ do.
    ((<T_CONJ) ; <,c) ; (>: p)
  elseif. c e. DIGITS do.
    endP =. readNumber (p ; src)
    raw  =. (endP - p) {. p }. src
    ((<T_NUM) ; <raw) ; endP
  elseif. c e. ALPHA do.
    endP =. readName (p ; src)
    raw  =. (endP - p) {. p }. src
    ((<T_NAME) ; <raw) ; endP
  else.
    ((<T_BAD) ; <,c) ; (>: p)
  end.
)

NB. --- Token-list utilities --------------------------------

NB. tokType: type of a single boxed token
NB. y = boxed 1-box wrapping a 2-box token
NB. Result = numeric type (T_*)
NB.   > y       opens 1-box -> 2-box
NB.   0 { > y   gets first element of 2-box -> 1-box of type
NB.   > > 0 { > y double-unbox -> type number
tokType =: 3 : 0
  if. 0 = # y do. _1 return. end.
  > > 0 { > y
)

NB. tokValue: value of a single boxed token
NB. y = boxed 1-box wrapping a 2-box token
NB. Result = value (char vector or number, unboxed)
NB. For char vectors (most tokens), one unbox suffices.
NB. For boxed-array values (e.g. EOF), extra unbox is a no-op.
tokValue =: 3 : 0
  if. 0 = # y do. '' return. end.
  v =. 1 { > y
  NB. If v is itself a 1-box, unbox; else return as-is
  if. 32 = 3!:0 v do.
    > v
  else.
    v
  end.
)

NB. tokPos: approximate token position (0 for Phase 1).
NB. y = boxed 1-box wrapping a 2-box token
tokPos =: 3 : '0'

NB. formatTokens: pretty-print a token list (for diagnostics)
NB. y = boxed vector of 1-box tokens
NB. Result = char vector
formatTokens =: 3 : 0
  toks =. y
  if. 0 = # toks do. '' return. end.
  n =. # toks
  out =. ''
  for_i. i. n do.
    tok =. i { toks
    t =. tokType tok
    v =. tokValue tok
    name =. > t { T_LABELS
    out =. out , (name , '  ' , ":v) , LF
  end.
  out
)
