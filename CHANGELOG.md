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
