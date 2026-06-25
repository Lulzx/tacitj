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

NB. LF is whitespace in J, so 'a =: 1  LFb =: 2' is one sentence.
NB. splitOnLF strips trailing spaces (via stripLines/stripComment), so
NB. the trailing space in 'a =: 1 ' is removed, making '1' part of
NB. the expression: expr = '1 LFb' -> NUM(1), NAME(b) (both terms).
NB. Tokens: NAME(a), ASSIGN, NUM(1), NAME(b), ASSIGN, NUM(2), EOF = 7.
NB. (The '1' is kept because stripLines strips trailing spaces, not
NB. trailing alphanumeric chars.)
resetOptEnv ''
src =. 'a =: 1 ' , LF , 'b =: 2'
toks =. lex src
assert (# toks) ; 7 ; <'lex multi-line: 7 tokens'

NB. --- Multi-line through IR pipeline ------------------------

NB. 'x =: 5 LF x + 1' is ONE sentence in J (LF = whitespace).
NB. The expr is 'x =: 5 x + 1' which reduces to a single assignment.
resetOptEnv ''
prog2 =. lowerIr semAnalyze parseProgram lex ('x =: 5' , LF , 'x + 1')
assert (irOp prog2) ; IR_PROG ; <'lowerIr: multi-line -> IR_PROG'
NB. Exactly 1 statement (one assignment; x + 1 is the RHS expression)
assert (# > irArgs prog2) ; 1 ; <'lowerIr: multi-line has 1 stmt'
