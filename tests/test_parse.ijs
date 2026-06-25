NB. ============================================================
NB. test_parse.ijs - Parser tests (parentheses + multi-line)
NB. ============================================================
NB. Tests the parser fixes:
NB.   1. parseExpr consumes trailing RPAREN (paren groups)
NB.   2. splitOnLF: correct line splitting (ends formula fix)
NB.   3. IR pipeline handles parenthesized expressions

NB. --- Token tests -------------------------------------------

NB. LPAREN/RPAREN tokens are recognized
assert (tokType 0 { lex '(') ; T_LPAREN ; <'LPAREN token'
assert (tokType 0 { lex ')') ; T_RPAREN ; <'RPAREN token'

NB. Parenthesized number
toks =. lex '( 42 )'
assert (# toks) ; 4 ; <'lex: ( 42 ) -> 4 tokens'

NB. --- Parenthesized expression through parser ---------------

NB. ( 1 + 2 ) parses without hanging and produces an AST
resetOptEnv ''
ast =. parseProgram lex '( 1 + 2 )'
assert (0 < # ast) ; 1 ; <'parse: ( 1 + 2 ) produces AST'

NB. --- Parenthesized expression through IR pipeline -----------

NB. Lowering ( 1 + 2 ) to IR
resetOptEnv ''
prog =. lowerIr semAnalyze parseProgram lex '( 1 + 2 )'
assert (irOp prog) ; IR_PROG ; <'lowerIr: ( 1 + 2 ) -> IR_PROG'

NB. Compile ( 1 + 2 ) = 3
resetOptEnv ''
assert (compile '( 1 + 2 )') ; 3 ; <'compile: ( 1 + 2 ) = 3'

NB. Compile ( ( 3 * 4 ) ) = 12
resetOptEnv ''
assert (compile '( ( 3 * 4 ) )') ; 12 ; <'compile: ( ( 3 * 4 ) ) = 12'

NB. Compile ( 10 - 5 ) = 5
resetOptEnv ''
assert (compile '( 10 - 5 )') ; 5 ; <'compile: ( 10 - 5 ) = 5'

NB. --- splitOnLF: correct line splitting ----------------------

NB. LF at depth 0 ends a sentence (a T_SENT_END is emitted).
NB. So 'a =: 1  LFb =: 2' becomes two sentences: the lexer
NB. emits NAME, ASSIGN, NUM, SENT_END, NAME, ASSIGN, NUM, EOF
NB. = 8 tokens.
resetOptEnv ''
src =. 'a =: 1 ' , LF , 'b =: 2'
toks =. lex src
assert (# toks) ; 8 ; <'lex multi-line: 8 tokens (with SENT_END)'

NB. --- Multi-line through IR pipeline ------------------------

NB. 'x =: 5 LF x + 1' is now TWO sentences: the lexer inserts
NB. a sentence-end marker between them, so the parser produces
NB. two top-level stmts (one assignment + one bare expression).
resetOptEnv ''
prog2 =. lowerIr semAnalyze parseProgram lex ('x =: 5' , LF , 'x + 1')
assert (irOp prog2) ; IR_PROG ; <'lowerIr: multi-line -> IR_PROG'
NB. Exactly 2 statements (one assignment + one expression)
assert (# > irArgs prog2) ; 2 ; <'lowerIr: multi-line has 2 stmts'

NB. Single-line programs are still one sentence (no SENT_END).
resetOptEnv ''
prog3 =. lowerIr semAnalyze parseProgram lex '2 + 3'
assert (# > irArgs prog3) ; 1 ; <'lowerIr: single-line -> 1 stmt'

NB. A bare LF at depth 0 (blank line) does NOT emit SENT_END.
NB. Tabs/spaces between tokens are still just whitespace.
resetOptEnv ''
src4 =. '2 + 3' , LF , LF , '4 * 5'
toks4 =. lex src4
NB. 6 tokens: NUM, VERB, NUM, SENT_END, NUM, VERB, NUM, EOF = 8
NB. Actually only one SENT_END between the non-blank lines.
assert (# toks4) ; 8 ; <'lex: blank-line LFs still split once'
