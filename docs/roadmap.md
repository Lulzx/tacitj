# Roadmap & release history

| Week | Milestone | Status |
|------|-----------|--------|
| 1 | Lexer + Parser + self-compile "hello train" | ✅ Stage 0 |
| 2 | IR + Optimizer + tacit rewrite engine + Solon stub | ✅ done |
| 3 | Codegen + Stage 1–3 bootstrap scripts + full test suite | ✅ done |
| 4 | Polish, benchmarks, docs, v0.1 release | ✅ done |
| 5 | Multi-line programs (LF = sentence boundary) + 2-char verbs (`*:`, `%:`, `^:`, `\|:`, `<:`, `>:`) | ✅ done |
| 6 | Identity functions (`]`, `[`), `~:`, and 2-char `~:`; works with `@` composition | ✅ done |
| 7 | MDL cost + Solon-style grammar induction (SPEC §8) | ✅ done |
| 8 | 2-char conjunctions (`@:`, `&:`, `^:`) — rank-preserving composition | ✅ done |
| 9 | More 2-char verbs: `<.`, `>.` (floor, ceiling) and `+:`, `-:` (increment, decrement) | ✅ done |
| 10 | Design doc + `examples/rank.ijs` polish | ✅ done |
| 11 | Pipeline trace demo + bench tests | ✅ done |
| 12 | `examples/matrix.ijs` — 2D-array operations demo | ✅ done |
| 13 | Bootstrap determinism / env-bleed verification (`bench/verify.ijs`) | ✅ done |
| 14 | `examples/stats.ijs` — statistical functions library | ✅ done |
| 15 | Lexer: recognise `=.` as T_ASSIGN (was tokenising as `=` + `.`) | ✅ done |
| 16 | `examples/poly.ijs` — polynomial evaluation | ✅ done |
| 17 | `examples/sort.ijs` — sorting and deduplication | ✅ done |
| 18 | README tutorial: "Writing TacitJ programs" reference | ✅ done |
| 19 | `bench/smoke_all.ijs` + `make smoke-all` — run every example | ✅ done |
| 20 | `examples/moving.ijs` — prefix sums and Stieltjes prefix | ✅ done |
| 21 | `make ci` — combined test + verify + smoke-all gate | ✅ done |

### Bootstrap stages

| Stage | Description | Status |
|-------|-------------|--------|
| **0** | Hand-written C/J bootstrap (tiny explicit interpreter) | **done** |
| **1** | TacitJ compiler in explicit J, compiled by Stage 0 | ✅ done (`make stage1`) |
| **2** | Output-contract freeze + tacit-density baseline | ✅ done (`make stage2`) |
| **3** | Self-host: src/*.ijs compile through the pipeline; emitted compiler reproduces the output contract | 🟢 advanced (`make stage3`, `make selfhost-full`) |
| **4+** | Performance VM + LLVM backend | planned |

Stage 2 freezes the **output contract**: a 5-case canary
corpus where `emit(compile(src)) == emit(compile(emit(compile(src))))`
(round-trip fixed point), and records a tacit-density
baseline over `src/*.ijs` (72 tacit / 125 explicit). Stage 3
proves the canary + corpus + 6 safe examples are fixed points.
**Since v0.19 the compiler source itself is no longer a blocker**:
every `src/*.ijs` file compiles through the pipeline as a syntactic
fixed point (9/9), and the emitted modules load in a clean namespace
and reproduce the Stage 0 output contract (`make selfhost-full`).
**Since v0.21 the IR pipeline handles the larger examples too**:
`matrix`/`stats`/`poly`/`sort`/`moving` now
lex→parse→sem→lower→opt→emit and round-trip as fixed points
(SPEC §10 item 10), so every example in `examples/` is a fixed point.

### Stage 0 language subset

The Stage 0 lexer/parser recognises:

- **Verbs (single char)**: `+ - * % ^ = < > | & ~ ; , $ # ? ! ] [`
- **Verbs (two char)**: `*: %: ^: |: <: >: ~: +: -:`
  (square, root, log, reverse, increment, decrement, not-equal,
  increment, decrement) and `<. >. +. -.`
  (floor, ceiling, plus/minus on floats).
- **Adverbs**: `/ \ ~ . :`  (insert, prefix/suffix, reflexive, etc.)
- **Conjunctions (single char)**: `@ & ^ !`  (atop, bond, power, fit)
- **Conjunctions (two char)**: `@: &: ^:` (atop/bond/power with rank)
- **Gerunds / agenda**: backtick tie (`` ` ``), `@.` (agenda), and
  constant verbs `0:`–`9:`
- **Direct definitions**: `{{ }}` dfns and one-line explicit defs
  (`3 : '...'` / `4 : '...'`) captured verbatim as `T_DEF`
- **Assignment**: `=:` and `=.`
- **Literals**: numbers, single-quoted strings (with `''` escape)
- **Parens**: `( expr )` for grouping
- **Comments**: `NB.` to end of line

Known not-yet-supported: `~:/\ ` (not-equal scan) and the adverb
`\: ` (suffix). These are tracked in `bootstrap/stage3_attempt.ijs`
as future work.

`make stage3-attempt` runs `bootstrap/stage3_attempt.ijs`, which:
- re-checks the Stage 0 canary (`( 1 + 2 )|9`)
- verifies that 3 small canaries are fixed points (compile-emit-recompile == compile-emit)
- compiles all 5 examples through Stage 0.

### MDL / grammar induction

`make mdl-demo` runs `bench/mdl_demo.ijs`, which exercises the
Solon-style MDL machinery in `src/mdl.ijs`:

- **`mdlScore`** — total cost of an IR (grammar cost per opcode + data
  cost per literal).
- **`grammarInduce`** — frequency count of structurally-identical
  sub-IRs across a corpus; surfaces common patterns.
- **`mdlMinimize`** — uses MDL cost to pick between candidate rewrites;
  here it folds `1 + 2` from cost 10 to cost 2 (constant).

Example output:
```
Grammar induction (top patterns):
  24x  (the IR_PROG node, common to all sub-IRs)
  3x   1
  3x   2
  2x   +
  2x   *
  2x   3
  1x   1 + 2
  1x   1 * 2
  ...

MDL minimizer (each corpus IR):
  corpus[0]: 10 -> 2
  corpus[1]: 10 -> 2
  corpus[2]: 10 -> 2
  corpus[3]: 10 -> 2
```

### What's new in v0.3

- **Identity functions `]` and `[`** added to the lexer. Used in
  hooks like `+/ ' ' = ]` and in tacit verb definitions.
- **`~:` (not-equal)** is now a single 2-char token, matching the
  pattern of `*:`, `%:`, etc.
- **`@` (atop) confirmed working** — was already in `PRIM_CONJ` but
  not exercised. Examples now use `*: @ mean` style composition.
- **`mean.ijs`** restored to use `*: @ mean` (was using a manual
  workaround in v0.2).
- **`wordcount.ijs`** uses `+/ @ (' ' = ])` (was using `+/ 1 2 3 4 5`
  fallback in v0.2).

### What's new in v0.4

- **MDL cost + grammar induction** (`src/mdl.ijs`). Implements the
  SPEC §8 sketch: a per-opcode grammar cost plus a per-char data
  cost gives a real `mdlScore`. `grammarInduce` does a frequency
  count of structurally-identical sub-IRs (the "grammar" the
  corpus is using). `mdlMinimize` uses MDL cost to pick between
  candidate rewrites.
- **Fixed a load-order bug** in `src/ir.ijs`: now loads `src/lex.ijs`
  so the unparser's primitive-verb check (`v e. prims`) has
  `PRIM_VERB`, `PRIM_ADV`, `PRIM_CONJ` in scope.
- **`make mdl-demo`** target.

### What's new in v0.5

- **2-char conjunctions**: `@:` (atop with rank), `&:` (bond with
  rank), `^:` (power with rank). These were always in J but the
  Stage 0 lexer previously emitted them as a single-char + `:`
  (e.g. `@` then `:`), causing them to be quoted in the unparse
  output and rejected by J.
- **Unparser fix**: `unparseIrLit` now knows about all the 2-char
  primitives (verbs and conjunctions) so they round-trip cleanly
  through `compile` / `emitIr`.
- **`examples/rank.ijs`**: shows `+/ @: *:` style rank-preserving
  composition. Sums the squares of 1..5 = 55.
- **New lexer tests**: `@:`, `&:`, `^:` as T_CONJ tokens (in
  `tests/test_lex.ijs`).

### What's new in v0.6

- **More 2-char verbs**: `<.` and `>.` (floor / ceiling) plus `+:`
  and `-:` (increment / decrement). The Stage 0 lexer now
  handles `*` / `%` / `^` / `|` / `<` / `>` / `~` / `+` / `-`
  followed by either `:` or `.`.
- **Unparser fix**: `unparseIrLit` knows about the four new 2-char
  verbs, so they round-trip without quoting.
- **Updated `examples/rank.ijs`** to demonstrate `floorOfHalf`
  (using `<. @: %:&2`).
- **New lexer tests** for `<.`, `>.`.

### What's new in v0.7

- **`docs/design.md`** — new architecture / design-decisions
  document. Covers the IR boxed-triple rationale, the
  `0!:1`-VOID-return workaround, MDL cost decomposition
  (grammar vs data), depth tracking in the lexer, and what's
  deliberately **not** in Stage 0 (`~:/\`, real bytecode
  codegen, self-hosting). Linked from the README.
- **`examples/rank.ijs` polished** — uncommented the
  `floorOfHalf` definition so the example actually runs.

### What's new in v0.8

- **`bench/trace.ijs`** — pipeline-trace demo. Runs a sample
  program through every compiler stage and prints the output of
  each (lex tokens → AST → IR → optimized IR → emitted J source
  → execution result). Makes the architecture visible and is a
  debugging aid. Run via `make trace`.
- **`tests/test_bench.ijs`** — bench smoke tests. Verifies that
  the bench / MDL / trace scripts load and that the bench verbs
  (`mdlScore`, `grammarInduce`, `mdlMinimize`) can be called.
- **`make trace` target.**

### What's new in v0.9

- **`examples/matrix.ijs`** — 2D-array operations. Demonstrates
  `2 3 $ ...` reshape, row sums (`+/"1`), column sums (`+/`),
  transpose (`|: `), outer product (`*/`), max (`>./`), and
  ravel-based reduction (`+/ ,`). All round-trip through the
  compiler and run end-to-end. Output:
  ```
  matrix:
  1 2 3
  4 5 6
  sum = 21
  row sums: 6 15
  col sums: 5 7 9
  transpose:
  1 4
  2 5
  3 6
  max = 6
  mul table:
  1 2 3
  2 4 6
  3 6 9
  sum of squares = 91
  ```

### What's new in v0.10

- **`bench/verify.ijs`** — bootstrap verification script.
  Runs the compiler against a fixed corpus (5 cases covering
  arithmetic, reduction, assignment, and `smoutput`) and
  asserts two properties:
  1. **Determinism** — compiling the same source twice gives
     byte-identical emitted J source.
  2. **Env-bleed** — compiling source `S` after compiling
     another source `P` gives the same result as compiling
     `S` standalone. This proves the optimizer env doesn't
     leak state between runs.

  Both checks pass: `10 / 10`.
- **`make verify`** — runs `bench/verify.ijs`. Exits 0 on
  success, 1 on mismatch. Useful as a CI gate.

### What's new in v0.11

- **`examples/stats.ijs`** — small statistics library:
  - `mean = +/ % #` (fork)
  - `sumsq = +/ @: *:` (atop)
  - `ssqdev = +/ @: *: @: (- mean)` (atop with explicit hook grouping)
  - `var = ssqdev % #` (fork; variance = ssqdev / count)
  - `stddev = %: @: var` (atop)
  - `rng = (<./ , >./)` (2-element min/max vector)
  - All functions round-trip through the compiler and produce
    correct numerical results on a sample dataset
    `[1..12]`: mean = 6.5, sumsq = 650, ssqdev = 143,
    var = 11.9167, std = 3.45205, range = `1 12`.
- The example also demonstrates the **TacitJ hook caveat**:
  `- mean` parses as `(negate mean)` rather than as a hook
  `(x - mean x)`. The workaround is to wrap in parens
  (`(- mean)`) or use explicit compositions like
  `(/ % #) @: *: @: - mean`.

### What's new in v0.12

- **Lexer fix**: recognise `=.` (assignment) as a single
  `T_ASSIGN` token. Previously the lexer would emit `=` as
  a `T_VERB` and `.` separately, leaving the parser to
  treat them as individual tokens. This was producing invalid
  emitted J source like `( coefs = . 1 2 3 )` (which J
  parses as `(= (. 1 2 3))` instead of assignment). The fix
  extends the existing `=:` check to also accept `=.`. Both
  forms are now tokenised as a single `T_ASSIGN` token.
- **`examples/poly.ijs`** — polynomial evaluation. Evaluates
  `p(x) = 1 + 2x + 3x^2 + 4x^3` at given points using
  `+/ coefs * x ^ i. # coefs`. Output: `p(2) = 49`,
  `p(3) = 142`. The example documents the current subset
  limitation: no looping constructs, so each evaluation
  point is a separate expression.

### What's new in v0.13

- **`examples/sort.ijs`** — sorting and deduplication:
  - `/:~ y` ascending sort
  - `\:~ y` descending sort
  - `/: y` grade up (sort indices)
  - `\: y` grade down
  - `~. y` nub (unique elements, first-occurrence order)
  - `~: y` nub sieve (1 = first occurrence)
  - Pair sorting by key: `pairs /: /: 0 { pairs`
  - Output on `5 2 8 1 9 3 2 7 1 4 5 8`:
    - asc = `1 1 2 2 3 4 5 5 7 8 8 9`
    - desc = `9 8 8 7 5 5 4 3 2 2 1 1`
    - unique = `5 2 8 1 9 3 7 4`
    - n dups = 4
    - n uniq = 8

  Documents the subset limitation that inner-product
  `+/ . =` is not currently tokenised, so per-element
  counts are hand-computed.

### What's new in v0.14

- **README tutorial: "4. Writing TacitJ programs"** — a
  comprehensive quick-reference for the language subset:
  - **Verbs table** (24 entries): every supported verb with
    a runnable example (arithmetic, comparison, reshape,
    transpose, modulo, etc.).
  - **Adverbs table** (8 entries): insert, prefix, nub,
    nub-sieve, grade up/down, sort up/down.
  - **Conjunctions table** (5 entries): atop, bond, power
    (including rank variants).
  - **Forks and hooks**: explanation with the canonical
    mean example (`+/ % #`) and the hook caveat.
  - **Reading list**: links to all 8 working examples.

  Serves as both a learning aid for new users and a
  quick-reference for the language.

### What's new in v0.15

- **`bench/smoke_all.ijs`** — runs every example and reports
  pass/fail. Uses `smokeOne each EXAMPLES` to invoke each
  script via `runTacitJ` and captures whether it ran
  without error.
- **`make smoke-all`** target. Exits 0 if all 11 examples
  pass, 1 otherwise. Useful as a quick "did I break any
  examples?" check after a code change.
- Output: `summary: 11 / 11 examples passed`.

### What's new in v0.16

- **`examples/moving.ijs`** — prefix sums and reductions:
  - `+/ xs` total sum = 55
  - `+/ \ xs` cumulative prefix sums = `1 3 6 10 15 21 28 36 45 55`
  - `+\ xs` Stieltjes prefix matrix (10x10) where row i is
    the prefix of length i+1 padded with zeros
  - `*: @: ]` square-then-identity composition
  - `+/ @: *:` sum of squares
  - `(<./ , >./)` range
- Documents the **`+\` vs `+/ \` distinction**: `+\` is
  Stieltjes prefix (matrix), `+/ \` is cumulative sum
  (vector). Easy to confuse — the example shows both.
- **`bench/smoke_all.ijs`** updated to include
  `examples/moving.ijs`. `make smoke-all` now runs 12
  examples.

### What's new in v0.21

- **Gerunds and agenda (SPEC §2.1)** — the last documented
  language-subset gap. The backtick tie (`` ` ``) and `@.` (agenda)
  lex as single `T_CONJ` tokens, and constant verbs `0:`–`9:` lex as
  single `T_VERB` tokens. They unparse unquoted, so gerund / agenda
  programs round-trip as fixed points and execute.
- **IR pipeline handles the larger examples** — `matrix`, `stats`,
  `poly`, `sort`, `moving` now lex→parse→sem→lower→opt→emit and
  round-trip as fixed points (SPEC §10 item 10; previously they
  exceeded the IR subset and were skipped). Every example in
  `examples/` is now a fixed point.
- **SPEC.md appendix fix** — the gerund example now uses the valid
  boxed form `(<'hello')`]` (a char-vector tie is a domain error in J).

### What's new in v0.20

- **`{{ }}` direct definitions** — single-line and multi-line dfns
  captured as opaque `T_DEF` tokens (a `{{ }}` inside a string is
  data, not a dfn opener).
- **One-line explicit defs** — `3 : '...'` / `4 : '...'` captured
  verbatim as `T_DEF`.
- **More two-char verbs** — `":`, `,.`, `i.`, `e.`, `o.`, `j.`,
  `r.`, `{.`, `}.`, `/:`, `\:` lex as single `T_VERB` tokens and
  unparse unquoted.
- **Semantic analysis (SPEC §4.3)** — shape/type inference
  (`infer`), well-formedness (`semValidate`), constant folding
  (`semFold`), and dead-code elimination (`semDce`).
- **Exec-path fidelity** — the emitted (self-compiled) compiler's
  `execIr`/`runTacitJ` path is exercised end-to-end
  (`make selfhost-full` reports `exec-path fidelity: 1`).
- **Per-program namespaces** — `runTacitJ` executes in a fresh
  locale and restores the caller's locale, so names do not leak
  between programs.

### What's new in v0.19

- **Self-host breakthrough**: every `src/*.ijs` file now compiles
  through the Stage 0 pipeline and round-trips as a syntactic
  fixed point (9/9). The emitted (self-compiled) modules load in
  a clean namespace and reproduce the Stage 0 output contract.
  See **`make selfhost-full`**.
- **Explicit-definition blocks** — `3 : 0 ... )` / `4 : 0 ... )`
  are captured verbatim (new `T_DEF` token, `AST_DEF` node,
  `IR_DEF` opcode). The parser no longer crashes on multi-line
  defs.
- **String-aware comment stripping** — `'NB.'` inside a string is
  data, not a comment (fixes a latent bug that only fired when
  the compiler started compiling its own source).
- **`_`-literals** — `_1`, `_3.14`, `_`, `__`, `_.` lex as
  numbers.
- **Chained assignment** — `a =: b =: c` parses and round-trips.

### What's new in v0.18

- **`make stage2`** — Stage 2: freezes the output contract
  (a 5-case canary corpus verified as round-trip fixed points:
  `emit(compile(src)) == emit(compile(emit(compile(src))))`)
  and records a tacit-density baseline over `src/*.ijs`
  (72 tacit / 125 explicit definitions).
- **`make stage3`** — Stage 3: honest partial self-host
  milestone. Proves the canary + corpus + 6 safe examples
  (`hello`, `mean`, `train`, `wordcount`, `fib`, `rank`) are
  fixed points. (At the time, `pipeline` compiled but was not a
  fixed point, and `matrix`/`stats`/`poly`/`sort`/`moving`
  exceeded the IR subset — both resolved by v0.21.)
- **`make bootstrap`** — now runs `stage 0 -> 1 -> 2 -> 3`.
- **`make ci`** — now includes `bootstrap`, so the combined
  gate is `test + verify + smoke-all + bootstrap`.
- **`bootstrap/stage3_attempt.ijs`** — hardcoded absolute
  paths replaced with repo-relative paths.

### What's new in v0.17

- **`make ci`** — combined CI gate. Runs:
  1. `make test` (132 unit tests)
  2. `make verify` (10 bootstrap determinism checks)
  3. `make smoke-all` (12 examples)

  All three must pass for `make ci` to succeed. Exits
  non-zero on any failure, with the failing target's output
  preserved. Useful as a single-command CI invocation.

Quick bootstrap tour:
```sh
make stage0       # load Stage 0 + canary check (exit 0 = OK)
make stage1 INFILE=examples/hello.ijs OUTFILE=bin/hello.ijs
make bootstrap    # stage 0 + stage 1 round-trip on hello.ijs
make selfhost     # stage 0 canary + stage 1 deterministic output
make bench        # compile-ms / out-chars / exec-ms per canary
```

Full plan with success criteria, risks, and Solon/MDL chapter: see [`SPEC.md`](../SPEC.md). See [`CHANGELOG.md`](../CHANGELOG.md) for the release notes. See [`docs/design.md`](design.md) for the architecture / design decisions.

---

