NB. ============================================================
NB. test_codegen.ijs - Codegen tests
NB. ============================================================
NB. Verifies the codegen module (emitIr, emitFile, compileFile)
NB. on representative TacitJ inputs.

NB. --- emitIr tests -----------------------------------------

NB. emitIr: simple arithmetic -> J source
resetOptEnv ''
ir =. lowerIr semAnalyze parseProgram lex '2 + 3'
assert (emitIr ir) ; '( 2 + 3 )' ; <'emitIr: 2 + 3'

NB. emitIr: assignment
resetOptEnv ''
ir2 =. lowerIr semAnalyze parseProgram lex 'x =: 5'
assert (emitIr ir2) ; 'x =: 5' ; <'emitIr: x =: 5'

NB. emitIr: 3-train mean
resetOptEnv ''
ir3 =. lowerIr semAnalyze parseProgram lex 'mean =: +/ % #'
assert (emitIr ir3) ; 'mean =: ( + / % # )' ; <'emitIr: mean =: +/ % #'

NB. emitIr: parentheses
resetOptEnv ''
ir4 =. lowerIr semAnalyze parseProgram lex '( 1 + 2 )'
assert (emitIr ir4) ; '( 1 + 2 )' ; <'emitIr: ( 1 + 2 )'

NB. --- compile + emit pipeline tests --------------------------

NB. compile emits J source and executes to the correct result
resetOptEnv ''
assert (compile '3 * 4') ; 12 ; <'compile: 3 * 4 = 12'

NB. runCompile: compiles and executes via temp file
resetOptEnv ''
assert (runCompile '10 - 3') ; 7 ; <'runCompile: 10 - 3 = 7'

NB. --- emitFile tests -----------------------------------------

NB. emitFile writes a file and returns 0 on success
resetOptEnv ''
ir5 =. lowerIr semAnalyze parseProgram lex 'y =: 99'
rc =. emitFile ir5 ; '/tmp/tacitj_emit_test.ijs'
assert rc ; 0 ; <'emitFile: returns 0 on success'

NB. The file contains the correct source
assert (1!:1 < '/tmp/tacitj_emit_test.ijs') ; 'y =: 99' ; <'emitFile: correct content'

NB. emitFile on empty IR returns 1 (failure)
rc2 =. emitFile (<a:) ; '/tmp/should_not_write.ijs'
assert rc2 ; 1 ; <'emitFile: returns 1 for empty IR'

NB. --- compileFile tests -------------------------------------

NB. compileFile: source -> IR -> emit -> file
NB. Write a test source first
testSrc =. 'z =: 42' , LF , 'z + 1'
testSrc 1!:2 < '/tmp/tacitj_src_test.ijs'
rc3 =. compileFile '/tmp/tacitj_src_test.ijs' ; '/tmp/tacitj_out_test.ijs'
assert rc3 ; 0 ; <'compileFile: returns 0 on success'

NB. Output file contains the compiled J source
outContent =. 1!:1 < '/tmp/tacitj_out_test.ijs'
assert (0 < # outContent) ; 1 ; <'compileFile: output not empty'
