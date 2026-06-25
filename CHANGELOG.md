# Changelog

All notable changes to TacitJ are recorded here. The format is
loosely based on [Keep a Changelog](https://keepachangelog.com/),
and the project does not yet follow SemVer.

## [0.1.0] - 2026-06-25

First public release. Stage 0 + Stage 1 + bootstrap scaffolding.

### Added

- **Bootstrap infrastructure**:
  - `bootstrap/stage0.ijs`: module form (no top-level `exit`)
    of the Stage 0 loader.
  - `bootstrap/stage0_run.ijs`: one-shot `stage0 + selfhost + exit`
    for CI / `make stage0`.
  - `bootstrap/stage1.ijs`: compile a TacitJ source file to a
    standalone J script (driven by `INFILE=` and `OUTFILE=` env
    args). Wraps the emitted code as `r =: <jsrc>` / `r` to
    capture the value, since `0!:1` returns VOID in J 9.7.
  - `bootstrap/stage2.ijs`, `bootstrap/stage3.ijs`: stubs
    documenting the planned self-host path. See
    `bootstrap/stage3_attempt.ijs` for a real attempt.
  - `bootstrap/stage3_attempt.ijs`: tries to compile Stage 0
    source through itself and reports what works and what
    doesn't. Realistic baseline for Stage 3.

- **Codegen** (`src/codegen.ijs`):
  - `emitIr` (IR → J source), `emitFile` (IR → file),
    `compileFile` (source → IR → file),
    `runCompile` (source → result via `0!:1`),
    `execSource` (raw J source → result).

- **Benchmark suite** (`bench/bench.ijs`):
  - 8 canary cases measuring compile-ms, out-chars, exec-ms.
  - `make bench`.

- **Examples**:
  - `examples/squares.ijs`: sum of squares in one line.
  - `examples/wordcount.ijs`: tacit word counter.
  - `examples/fib.ijs`: golden ratio via Binet.

- **Makefile targets**: `test`, `smoke`, `run`, `repl`,
  `stage0`, `stage1`, `bootstrap`, `selfhost`, `bench`, `clean`.

### Fixed

- `splitOnLF` off-by-one (in a prior commit; the current
  implementation is correct).
- `stripLines` was returning 1 too many elements (recursion
  base case returned the input, then `;` boxed it). Rewrote
  as a `while` loop with explicit boxing.
- `unparseIrLit` for string literals:
  - The membership check `+./ (v = {. prims) , ...` was
    matching a comma inside `'hello, world'` against a
    primitive and skipping the quotes. Now checks `1 = # v`
    first.
  - The trailing `q , quoteEscape v , q` was parsed as
    `(q , quoteEscape v) , q` and added the closing quote
    twice. Fixed with explicit `(q , quoteEscape v) , q`.
- `collapseDoubledQuotes` (new helper) for proper string body
  extraction with doubled-quote escapes.
- `parseExpr` now consumes a trailing `RPAREN` (the prior
  parser would hang on parenthesized expressions).

### Changed

- README, Makefile, AGENTS.md: updated to reflect the new
  pipeline and bootstrap story.
- `eval.ijs::runTacitJ` is clearer about `0!:1`'s VOID return
  in J 9.7 (multi-line programs don't surface a result; the
  user can call `smoutput` themselves).

### Known limitations

- LF is whitespace in J, so multi-line source where the
  second line should be a separate sentence is NOT supported
  by the Stage 0 parser. `x =: 1 + 2\nx * 3` is parsed as a
  single sentence.
- The benchmark's "result" column shows `(empty)` because
  `0!:0` on a void expression returns a 0x0 array. The
  compile-time and out-chars metrics are the real signal.
- `make run EXAMPLE=examples/wordcount.ijs` shows no output
  for multi-line files (the multi-line path returns `a:`).
  Use the REPL or `make bench` for visible execution.

[0.1.0]: https://github.com/Lulzx/tacitj/releases/tag/v0.1.0

## [0.2.0] - 2026-06-25

Multi-line programs and 2-character verbs land.

### Added

- **Multi-line programs**: the lexer now emits a `T_SENT_END` token
  at depth-0 LF, so `mean =: +/ % #\nmean 1 2 3 4 5` is parsed as
  two separate sentences (was previously absorbed into one).
  Updated `parseProgRec` and `parseTerms` to handle `T_SENT_END`.
- **2-character verbs**: `*:`, `%:`, `^:`, `|:`, `<:`, `>:` are now
  single tokens (used to be split into verb+adv pairs).
- **`make run EXAMPLE=...` actually runs the file**: tacitj.ijs now
  parses ARGV and runs any extra file paths via `runFile`. All
  examples now print results to stdout.
- **`bootstrap/stage3_attempt.ijs` actually compiles the
  examples**: now reports `5 / 5 examples compiled` (was previously
  skipped due to the multi-line parser bug).
- New tests in `tests/test_parse.ijs`:
  - `lex multi-line: 8 tokens (with SENT_END)`
  - `lowerIr: multi-line has 2 stmts`
  - `lowerIr: single-line -> 1 stmt`
  - `lex: blank-line LFs still split once`

### Changed

- README: roadmap shows Week 5 done; bootstrap stages updated;
  What's-new section added.
- AGENTS.md: still references CHANGELOG.md.
- `make stage3-attempt` now produces a real per-file output.

### Fixed

- The `0!:1`/`0!:101` VOID-return workaround in `src/eval.ijs`
  was kept (multi-line still requires explicit `smoutput` for
  visible output).
- Examples updated to use `smoutput` and the Stage 0 subset
  (no `@`, `@:`, `~:`, etc.).

[0.2.0]: https://github.com/Lulzx/tacitj/releases/tag/v0.2.0

## [0.3.0] - 2026-06-25

More Stage 0 subset — identity functions, `~:`, working `@`.

### Added

- **Identity functions `]` and `[`** added to `PRIM_VERB`. Used in
  hooks (`0 , ]`), forks (`' ' = ]`), and the identity-of-y pattern.
- **`~:` (not-equal)** is now a single 2-char token. Same pattern
  as `*:`, `%:`, `^:`, `|:`, `<:`, `>:`.
- **`@` (atop) verified working** end-to-end. Was already in
  `PRIM_CONJ` but no example exercised it.

### Changed

- **`examples/mean.ijs`** restored to use `*: @ mean` (was using
  the `mean * mean` workaround in v0.2).
- **`examples/wordcount.ijs`** uses `+/ @ (' ' = ])` for
  count-of-spaces (was using `+/ 1 2 3 4 5` fallback in v0.2).
  Result: `wordCount 'the quick brown fox'` -> `4`.
- **README** adds a "Stage 0 language subset" section listing
  exactly which verbs/adverbs/conjunctions are supported.

### Known limitations (next up)

- `@:` (compose with rank)
- `~:/\ ` (not-equal scan) and `\: ` (suffix) — these adverbs are
  not yet in `PRIM_ADV`.
- `2 ~:/\ ]` style scans (need both `~:/\` and `]` working).

[0.3.0]: https://github.com/Lulzx/tacitj/releases/tag/v0.3.0

## [0.4.0] - 2026-06-25

MDL cost + Solon-style grammar induction land.

### Added

- **`src/mdl.ijs`** — Solon-style MDL machinery:
  - `mdlScore ir` — total cost = grammar_cost(opcode) + data_cost(literal).
  - `opMdlCost op` — per-opcode grammar cost.
  - `allSubIrs ir` — collect every sub-IR (used by induction).
  - `grammarInduce corpus` — frequency count of structurally-
    identical sub-IRs across a corpus; returns sorted
    (count, key, sample) rows.
  - `mdlMinimize ir` — generate candidates from `optPass`, pick
    the lowest-MDL variant, iterate to fixed point.
  - `mdlDemo` — one-shot demo of the above on a corpus of 4 IRs.
- **`bench/mdl_demo.ijs`** + `make mdl-demo` target.
- **`tests/test_mdl.ijs`** — 8 tests covering `mdlScore` (numeric /
  char / primitive literals, refs, calls), `grammarInduce` (empty
  corpus, non-empty), and `mdlMinimize` (never increases cost).
- **Fixed load-order bug in `src/ir.ijs`**: now loads
  `src/lex.ijs` so the unparser's primitive-verb check has
  `PRIM_VERB`, `PRIM_ADV`, `PRIM_CONJ` in scope. Previously, the
  check silently failed when ir.ijs was loaded before lex.ijs
  (e.g. from `src/mdl.ijs`).

### Verified

- `make test` -> 105 passed, 0 failed (was 97).
- `make mdl-demo` -> the demo runs and shows:
  - 4 corpus IRs each at MDL cost 10.
  - Grammar induction surfaces `1`, `2`, `+`, `*`, `3`, and the
    full programs (with their counts).
  - `mdlMinimize` folds each `1+2`-style IR from cost 10 to 2.
- `make stage0`, `make stage3-attempt`, `make bench` all still pass.

[0.4.0]: https://github.com/Lulzx/tacitj/releases/tag/v0.4.0

## [0.5.0] - 2026-06-25

Two-char conjunctions land.

### Added

- **2-char conjunctions**: `@:` (atop with rank), `&:` (bond with
  rank), `^:` (power with rank). Same lexer pattern as the
  2-char verbs (added in v0.2). `src/lex.ijs` introduces
  `CONJ_TWO_CHAR` as a constant.
- **Unparser fix**: `unparseIrLit` in `src/ir.ijs` now treats the
  2-char primitives (`*:`, `%:`, `^:`, `|:`, `<:`, `>:`,
  `~:`, `@:`, `&:`, `^:`) as unquoted primitives instead of
  string literals.
- **`examples/rank.ijs`**: shows `+/ @: *:` style composition.
  Result: `sumSquares 1 2 3 4 5` = 55.
- **New tests in `tests/test_lex.ijs`** for `@:`, `&:`, `^:` as
  T_CONJ tokens.

### Notes

The `^:` check in the lexer has to run **before** the 2-char verb
check (which is checked before the single-char verb check) — `^`
is in `PRIM_VERB`, so without ordering it, `^:` would be
classified as a 2-char verb. By checking conjunctions first, the
classification is correct.

### Verified

- `make test` -> 116 passed, 0 failed (was 105).
- `make run EXAMPLE=examples/rank.ijs` -> 55.

[0.5.0]: https://github.com/Lulzx/tacitj/releases/tag/v0.5.0

## [0.6.0] - 2026-06-25

More 2-char verbs land.

### Added

- **2-char verbs**: `<.`, `>.` (floor, ceiling), `+:`, `-:`
  (increment, decrement). All four are now lexed as a single
  T_VERB token. Same pattern as the existing 2-char verbs
  (`*:`, `%:`, `^:`, etc.).
- **Unparser fix**: `unparseIrLit` knows about the four new 2-char
  verbs, so they round-trip without quoting.
- **`examples/rank.ijs`**: updated to demonstrate `floorOfHalf`
  (using `<. @: %:&2`).
- **New lexer tests** in `tests/test_lex.ijs` for `<.` and `>.`.

### Notes

There are still parser issues with 2-trains that have a monadic
verb (like `+:`) followed by a noun. The lexer is correct but the
parser eagerly builds trains that J rejects when executed.
Documented but not fixed in this release.

### Verified

- `make test` -> 122 passed, 0 failed (was 116).
- All existing examples still produce correct output.

[0.6.0]: https://github.com/Lulzx/tacitj/releases/tag/v0.6.0

## [0.7.0] - 2026-06-25

Documentation + example polish.

### Added

- **`doc/design.md`** — new architecture / design-decisions
  document. Covers:
  - Pipeline at a glance (and why the composition is one line).
  - Why the IR is a boxed triple (`(<op ; <args ; <meta)`).
  - Why we emit J source instead of bytecode (free execution,
    self-hosting foundation, etc.).
  - Why the lexer tracks depth (LF-at-depth-0 → T_SENT_END).
  - Why `>` for unboxing + when it bites.
  - MDL cost decomposition (grammar vs data).
  - The `0!:1` VOID-return workaround.
  - What's deliberately not in Stage 0 (`~:/\`, real codegen,
    self-hosting).
  - Trade-offs the design accepts.
- **`examples/rank.ijs` polished**: uncommented the
  `floorOfHalf =: <. @: %:&2` definition so the example
  actually runs end-to-end.

### Verified

- `make test` -> 122 passed, 0 failed.
- `make run EXAMPLE=examples/rank.ijs` -> prints 55.

[0.7.0]: https://github.com/Lulzx/tacitj/releases/tag/v0.7.0

## [0.8.0] - 2026-06-25

Pipeline-trace demo + bench smoke tests.

### Added

- **`bench/trace.ijs`** — pipeline-trace demo. Runs a sample
  program through every compiler stage and prints the output
  of each (lex tokens → AST → IR → optimized IR → emitted J
  source → execution result). Makes the architecture visible
  and is a debugging aid. Run via `make trace`.
- **`tests/test_bench.ijs`** — bench smoke tests. Verifies that
  the bench / MDL / trace scripts load, that the MDL verbs
  (`mdlScore`, `grammarInduce`, `mdlMinimize`) are callable,
  and that each pipeline stage produces non-empty output on
  a fixed canary.
- **`make trace`** target.

### Verified

- `make test` -> 128 passed, 0 failed (was 122).
- `make trace` -> prints lex / parse / IR / opt / emit / exec
  output for `mean =: +/ % #\nsmoutput mean 1 2 3 4 5`.

[0.8.0]: https://github.com/Lulzx/tacitj/releases/tag/v0.8.0

## [0.9.0] - 2026-06-25

2D-array operations example.

### Added

- **`examples/matrix.ijs`** — 2D-array operations. Demonstrates:
  - `2 3 $ 1 2 3 4 5 6` (reshape to 2x3)
  - `+/"1 m` (row-wise sum)
  - `+/ m` (column-wise sum)
  - `|: m` (transpose)
  - `>./ , m` (max via ravel)
  - `*/` (outer product, multiplication table)
  - `+/ , *: m` (sum of squares via ravel)

  All round-trip through the compiler and run end-to-end.

### Verified

- `make test` -> 128 passed, 0 failed.
- `make run EXAMPLE=examples/matrix.ijs` -> prints the matrix,
  sums, transpose, max, multiplication table, and sum of squares.

[0.9.0]: https://github.com/Lulzx/tacitj/releases/tag/v0.9.0
