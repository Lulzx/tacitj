NB. ============================================================
NB. test_lex.ijs - Lexer tests
NB. ============================================================
NB. Tests the lexer on representative TacitJ inputs.
NB. We use a small helper to avoid J's right-to-left parsing ambiguity
NB. with the `assert` macro.

NB. --- Test helper ------------------------------------------

NB. check: monadic. y = 3-element list (actual, expected, desc)
NB. Due to J's right-to-left parsing of `;`, the call
NB.   check act ; exp ; desc
NB. may unroll to a 3-element list [act, exp, desc] (or a 2-box
NB. of 2-boxes depending on element types). We handle both.

check =: 3 : 0
  arg =. y
  if. 3 = # arg do.
    'act exp desc' =. arg
  elseif. 2 = # arg do.
    NB. 2-box where second is itself a 2-box of (exp ; desc)
    act =. > 0 { arg
    rest =. > 1 { arg
    'exp desc' =. rest
  else.
    smoutput 'check: bad arg count ' , ": # arg
    EMPTY return.
  end.
  if. act -: exp do.
    tpass =: < (1 + > tpass)
    smoutput '  PASS  ' , desc
  else.
    tfail =: < (1 + > tfail)
    smoutput '  FAIL  ' , desc
    smoutput '        expected: ' , ": exp
    smoutput '        actual  : ' , ": act
  end.
  EMPTY
)

NB. --- Tests: numeric and name literals --------------------

NB. Integer literal
toks =. lex '123'
check (tokType 0 { toks) ; T_NUM ; <'integer literal'

NB. Float literal
toks =. lex '3.14'
check (tokType 0 { toks) ; T_NUM ; <'float literal'

NB. Identifier
toks =. lex 'foo'
check (tokType 0 { toks) ; T_NAME ; <'identifier foo'

NB. Multi-char identifier
toks =. lex 'my_var'
check (tokType 0 { toks) ; T_NAME ; <'multi-char id'

NB. --- Tests: primitives ----------------------------------

NB. Single-char verbs
check (tokType 0 { lex '+') ; T_VERB ; <'verb +'
check (tokType 0 { lex '*') ; T_VERB ; <'verb *'
check (tokType 0 { lex '-') ; T_VERB ; <'verb -'

NB. Adverbs
check (tokType 0 { lex '/') ; T_ADV ; <'adverb /'

NB. Conjunctions
check (tokType 0 { lex '@') ; T_CONJ ; <'conjunction @'

NB. --- Tests: parens, assign, string ----------------------

NB. Parens
check (tokType 0 { lex '(') ; T_LPAREN ; <'lparen'
check (tokType 0 { lex ')') ; T_RPAREN ; <'rparen'

NB. Assignment
check (tokType 0 { lex '=:') ; T_ASSIGN ; <'assign =:'
check (tokType 0 { lex '=.') ; T_ASSIGN ; <'assign =.'
NB. The token's value should preserve the original form.
check (tokValue 0 { lex '=.') ; '=.' ; <'assign =. preserves the form'
check (tokValue 0 { lex '=:') ; '=:' ; <'assign =: preserves the form'

NB. String literal
toks =. lex '''hello'''
check (tokType 0 { toks) ; T_STR ; <'string hello'

NB. --- Tests: comments --------------------------------------

NB. NB. comment yields only EOF
toks =. lex 'NB. just a comment'
check (# toks) ; 1 ; <'NB comment yields only EOF'

NB. Inline comment
toks =. lex 'x =: 1  NB. inline'
check (# toks) ; 4 ; <'inline comment: 4 tokens'

NB. --- Tests: multi-token sequences -------------------------

NB. x =: 1 + 2 -> 6 tokens (incl EOF)
toks =. lex 'x =: 1 + 2'
check (# toks) ; 6 ; <'6 tokens in x =: 1 + 2'

NB. 3-train tokens
toks =. lex '+/ % #'
check (tokType 0 { toks) ; T_VERB ; <'first + in +/ % #'
check (tokType 2 { toks) ; T_VERB ; <'third # in +/ % #'

NB. --- 2-char verbs -----------------------------------------

NB. *: is a single 2-char verb token (not * then :)
toks2 =. lex '*: 1 2 3'
check (# toks2) ; 5 ; <'lex *:: 5 tokens'

NB. ~: is a single 2-char verb token
toks3 =. lex '~: 1 2 3'
check (# toks3) ; 5 ; <'lex ~:: 5 tokens'

NB. --- 2-char conjunctions (added in v0.5) -----------------

NB. @: is a single 2-char conjunction token (not @ then :)
toks4 =. lex '+/ @: *: 1 2 3'
NB. Expected tokens: +, /, @:, *:, 1, 2, 3, EOF = 8
check (# toks4) ; 8 ; <'lex @:: 8 tokens'
check (tokType 2 { toks4) ; T_CONJ ; <'lex @:: T_CONJ at index 2'
check (tokValue 2 { toks4) ; '@:'; <'lex @:: value is @:'

NB. &: is a single 2-char conjunction token
toks5 =. lex '+/ &: *: 1 2 3'
check (# toks5) ; 8 ; <'lex &:: 8 tokens'
check (tokType 2 { toks5) ; T_CONJ ; <'lex &:: T_CONJ at index 2'
check (tokValue 2 { toks5) ; '&:'; <'lex &:: value is &:'

NB. ^: is a single 2-char conjunction token
toks6 =. lex '2 ^: 3'
NB. Expected tokens: 2, ^:, 3, EOF = 4
check (# toks6) ; 4 ; <'lex ^:: 4 tokens'
check (tokType 1 { toks6) ; T_CONJ ; <'lex ^:: T_CONJ at index 1'
check (tokValue 1 { toks6) ; '^:'; <'lex ^:: value is ^:'

NB. --- 2-char verbs with . suffix (added in v0.6) -----------

NB. <. is a single 2-char verb token (floor)
toks7 =. lex '<. 3.5'
NB. Expected tokens: <., 3.5, EOF = 3
check (# toks7) ; 3 ; <'lex <.: 3 tokens'
check (tokType 0 { toks7) ; T_VERB ; <'lex <.: T_VERB at index 0'
check (tokValue 0 { toks7) ; '<.' ; <'lex <.: value is <.'

NB. >. is a single 2-char verb token (ceiling)
toks8 =. lex '>. 3.5'
NB. Expected tokens: >., 3.5, EOF = 3
check (# toks8) ; 3 ; <'lex >.: 3 tokens'
check (tokType 0 { toks8) ; T_VERB ; <'lex >.: T_VERB at index 0'
check (tokValue 0 { toks8) ; '>.' ; <'lex >.: value is >.'

NB. --- Negative numbers and infinities (added in v0.19) -----

NB. _1 is a single T_NUM token (not BAD _ then NUM 1)
toks9 =. lex '_1'
check (# toks9) ; 2 ; <'lex _1: 2 tokens (NUM + EOF)'
check (tokType 0 { toks9) ; T_NUM ; <'lex _1: T_NUM'
check (tokValue 0 { toks9) ; '_1' ; <'lex _1: value _1'

NB. _3.14 is a single T_NUM token
toks10 =. lex '_3.14'
check (tokType 0 { toks10) ; T_NUM ; <'lex _3.14: T_NUM'
check (tokValue 0 { toks10) ; '_3.14' ; <'lex _3.14: value _3.14'

NB. __ (negative infinity) and _. (NaN) are single T_NUM tokens
check (tokType 0 { lex '__') ; T_NUM ; <'lex __: T_NUM (neg infinity)'
check (tokType 0 { lex '_.') ; T_NUM ; <'lex _.: T_NUM (NaN)'

NB. --- Explicit-definition blocks (added in v0.19) -----------

NB. foo =: 3 : 0 ... ) lexes as NAME ASSIGN DEF EOF
defSrc =. 'foo =: 3 : 0', LF, '  y + 1', LF, ')'
toksD =. lex defSrc
check (# toksD) ; 4 ; <'lex def block: 4 tokens (NAME ASSIGN DEF EOF)'
check (tokType 2 { toksD) ; T_DEF ; <'lex def block: T_DEF at index 2'
check (tokValue 2 { toksD) ; ('3 : 0', LF, '  y + 1', LF, ')') ; <'lex def block: value is the verbatim block'

NB. Dyadic def (4 : 0)
defSrc2 =. 'f =: 4 : 0', LF, '  x + y', LF, ')'
toksD2 =. lex defSrc2
check (tokType 2 { toksD2) ; T_DEF ; <'lex dyadic def block: T_DEF'

NB. A def block captures exactly through the closing ')' line,
NB. and the following sentence starts a new token run (with a
NB. SENT_END separator, matching the non-def path).
defSrc3 =. 'foo =: 3 : 0', LF, '  y', LF, ')', LF, 'bar =: 1'
toksD3 =. lex defSrc3
check (# toksD3) ; 8 ; <'lex def + next sentence: 8 tokens (with SENT_END)'
check (tokType 4 { toksD3) ; T_NAME ; <'lex def + next: NAME bar at 4'
check (tokValue 4 { toksD3) ; 'bar' ; <'lex def + next: value bar'

NB. A 3 : 0 inside a comment is NOT a def opener.
toksD4 =. lex 'NB. see (3 : 0) in the docs'
check (# toksD4) ; 1 ; <'lex: 3 : 0 in comment is not a def'

NB. --- String-aware comment stripping (added in v0.19) -------

NB. NB. inside a string literal is data, not a comment.
stripped =. stripComment 'x =. ''NB. in string'' NB. real'
check stripped ; 'x =. ''NB. in string'' ' ; <'stripComment: NB. inside string preserved'

NB. A string with an escaped (doubled) quote still ends correctly.
stripped2 =. stripComment 'y =. ''it''''s'' NB. tail'
check stripped2 ; 'y =. ''it''''s'' ' ; <'stripComment: escaped quote handling'

NB. Comments inside a def body are preserved (verbatim block).
defWithComment =. 'f =: 3 : 0', LF, '  NB. keep me', LF, '  y', LF, ')'
stripped3 =. stripComments defWithComment
check stripped3 ; defWithComment ; <'stripComments: def body comments preserved'



NB. --- Direct definitions {{ }} (added in v0.20) ------------

NB. A single-line {{ }} dfn lexes as NAME ASSIGN DEF EOF.
dfnSrc =. 'double =: {{ y * 2 }}'
toksDfn =. lex dfnSrc
check (# toksDfn) ; 4 ; <'lex {{ }} dfn: 4 tokens (NAME ASSIGN DEF EOF)'
check (tokType 2 { toksDfn) ; T_DEF ; <'lex {{ }} dfn: T_DEF at index 2'
check (tokValue 2 { toksDfn) ; '{{ y * 2 }}' ; <'lex {{ }} dfn: value is the verbatim block'

NB. A multi-line {{ }} dfn captures through the closing }}.
dfnSrc2 =. 'f =: {{', LF, '  y + 1', LF, '}}'
toksDfn2 =. lex dfnSrc2
check (# toksDfn2) ; 4 ; <'lex multi-line {{ }} dfn: 4 tokens'
check (tokType 2 { toksDfn2) ; T_DEF ; <'lex multi-line {{ }} dfn: T_DEF'
check (tokValue 2 { toksDfn2) ; ('{{', LF, '  y + 1', LF, '}}') ; <'lex multi-line {{ }} dfn: verbatim block'

NB. A {{ }} inside a string is data, not a dfn opener.
dfnSrc3 =. 's =. ''{{ not a dfn }}'''
toksDfn3 =. lex dfnSrc3
check (tokType 2 { toksDfn3) ; T_STR ; <'lex: {{ }} inside string is data'

NB. --- One-line explicit defs (added in v0.20) --------------

NB. 3 : '...' lexes as NAME ASSIGN DEF EOF (verbatim, no parens).
oneSrc =. 'f =: 3 : ''y + 1'''
toksOne =. lex oneSrc
check (# toksOne) ; 4 ; <'lex one-line def: 4 tokens (NAME ASSIGN DEF EOF)'
check (tokType 2 { toksOne) ; T_DEF ; <'lex one-line def: T_DEF at index 2'
check (tokValue 2 { toksOne) ; ('3 : ''y + 1''') ; <'lex one-line def: value is the verbatim def'

NB. 4 : '...' (dyadic one-line def)
oneSrc2 =. 'g =: 4 : ''x + y'''
toksOne2 =. lex oneSrc2
check (tokType 2 { toksOne2) ; T_DEF ; <'lex dyadic one-line def: T_DEF'

NB. --- 2-char verbs: ": , ,. , i. (added in v0.20) ----------

NB. ": (format) is a single T_VERB token.
toksFmt =. lex '": 42'
check (# toksFmt) ; 3 ; <'lex ":: 3 tokens'
check (tokType 0 { toksFmt) ; T_VERB ; <'lex ":: T_VERB at index 0'
check (tokValue 0 { toksFmt) ; '":' ; <'lex ":: value is ":"'

NB. ,. (stitch) is a single T_VERB token.
toksStitch =. lex 'a ,. b'
check (tokType 1 { toksStitch) ; T_VERB ; <'lex ,.: T_VERB at index 1'
check (tokValue 1 { toksStitch) ; ',.' ; <'lex ,.: value is ,.'

NB. i. (integers) is a single T_VERB token.
toksInt =. lex 'i. 5'
check (tokType 0 { toksInt) ; T_VERB ; <'lex i.: T_VERB at index 0'
check (tokValue 0 { toksInt) ; 'i.' ; <'lex i.: value is i.'


NB. --- Gerund tie ` and agenda @. (added for SPEC 2.1) ------

NB. Backtick ` (Tie) lexes as a single T_CONJ token.
toksTie =. lex '''hello''`]'
check (tokType 1 { toksTie) ; T_CONJ ; <'lex ` (tie): T_CONJ at index 1'

NB. Agenda @. lexes as a single T_CONJ token (not @ + .).
toksAg =. lex 'f @. c'
check (tokType 1 { toksAg) ; T_CONJ ; <'lex @. (agenda): T_CONJ at index 1'
check (tokValue 1 { toksAg) ; '@.' ; <'lex @. (agenda): value is @.'

NB. Constant verbs n: lex as single T_VERB tokens.
toksCv =. lex '0:`1:`2:'
check (tokType 0 { toksCv) ; T_VERB ; <'lex 0:: T_VERB at index 0'
check (tokValue 0 { toksCv) ; '0:' ; <'lex 0:: value is 0:'
check (tokType 2 { toksCv) ; T_VERB ; <'lex 1:: T_VERB at index 2'
check (tokValue 2 { toksCv) ; '1:' ; <'lex 1:: value is 1:'
check (tokType 1 { toksCv) ; T_CONJ ; <'lex ` between constant verbs: T_CONJ at index 1'

NB. A plain number is still a number (not a constant verb).
toksN =. lex '42'
check (tokType 0 { toksN) ; T_NUM ; <'lex 42: still T_NUM'
