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


