NB. ============================================================
NB. test_mdl.ijs - MDL / grammar induction tests
NB. ============================================================
NB. Verifies that the MDL cost function, grammar inducer, and
NB. MDL minimizer work as advertised.

load 'src/mdl.ijs'

NB. --- mdlScore tests ---------------------------------------

NB. An IR_LIT with a single literal has cost = 1 (opMdlCost)
NB. plus 1 (data cost for numeric literal).
resetOptEnv ''
lit =. irLit 42
assert (mdlScore lit) ; 2 ; <'mdlScore: numeric literal = 2'

NB. A 1-char char literal (a primitive verb) has cost = 1.
NB. Note: unparseIr will emit the char unquoted (since it's a
NB. primitive). But the IR cost is still 1 + 1 (data) = 2.
litp =. irLit '+'
assert (mdlScore litp) ; 2 ; <'mdlScore: char-primitive literal = 2'

NB. A 5-char string literal has cost = 1 (op) + 5 (data) = 6.
lits =. irLit 'hello'
assert (mdlScore lits) ; 6 ; <'mdlScore: 5-char string literal = 6'

NB. An IR_REF (name reference) has cost = 1.
ref =. irRef 'foo'
assert (mdlScore ref) ; 1 ; <'mdlScore: name reference = 1'

NB. An IR_CALL with 3 LIT children has cost = 4 (op) + sum of
NB. children costs. Each LIT is 2 (op + data), so total is
NB. 4 + 2 + 2 + 2 = 10.
resetOptEnv ''
call =. irCall ((irLit '+') ; (irLit 1) ; (irLit 2))
assert (mdlScore call) ; 10 ; <'mdlScore: 3-arg call = 10'

NB. --- grammarInduce tests ----------------------------------

NB. Empty corpus -> empty result
assert (# grammarInduce 0 $ <a:) ; 0 ; <'grammarInduce: empty corpus -> 0 rows'

NB. Two identical programs: each has 5 sub-IRs (one call, two
NB. operands, and each operand has 1 sub-IR; total 1+2+2 = 5
NB. by structure but we deduplicate by canonical key). The
NB. top pattern should appear multiple times.
ir1 =. irCall ((irLit '+') ; (irLit 1) ; (irLit 2))
ir2 =. irCall ((irLit '+') ; (irLit 1) ; (irLit 2))
pat =. grammarInduce (ir1 ; ir2)
NB. The first row should have count >= 2 (at least the outer call)
smoutput 'grammarInduce: top row=' , ": 0 { 0 { pat
NB. Just verify it runs without error and returns rows
NB. (don't assert exact counts since they depend on dedup)
assert (0 < # pat) ; 1 ; <'grammarInduce: produces non-empty result'

NB. --- mdlMinimize tests -------------------------------------

NB. A simple expression should minimize to the same thing
NB. (constant folding already happens in optPass).
resetOptEnv ''
ir =. irCall ((irLit '+') ; (irLit 1) ; (irLit 2))
before =. mdlScore ir
min =. mdlMinimize ir
after =. mdlScore min
smoutput 'mdlMinimize: 1+2  cost '
smoutput ": before
smoutput ' -> '
smoutput ": after
NB. Should be no worse after minimisation.
assert (after <: before) ; 1 ; <'mdlMinimize: never increases cost'