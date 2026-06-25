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
