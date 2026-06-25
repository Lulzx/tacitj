<div align="center">

# TacitJ

**A self-hosting compiler for a tacit-leaning subset of [J](https://www.jsoftware.com/), written in J.**

[![J version](https://img.shields.io/badge/J-9.7-blue.svg)](https://www.jsoftware.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Stage](https://img.shields.io/badge/Stage-0-yellow.svg)](SPEC.md)
[![GitHub stars](https://img.shields.io/github/stars/Lulzx/tacitj?style=social)](https://github.com/Lulzx/tacitj/stargazers)

[Tutorial](#-tutorial) · [Examples](#-examples) · [Architecture](#-architecture) · [SPEC.md](SPEC.md) · [Roadmap](#-roadmap)

</div>

---

## What is TacitJ?

**TacitJ** is a compiler for a curated subset of [J](https://www.jsoftware.com/) — the
array-language famous for its terse, point-free, tacit style. The compiler's *own source*
is written in that same tacit style, and the goal is for the compiler to eventually compile
itself (a *self-hosting* bootstrap).

> **Status: Stages 0–1 complete, IR pipeline + codegen + bootstrap live.** The lexer,
> parser, semantic pass, IR lowerer, optimizer (constant folding, identity
> elimination, constant propagation), tree-walking evaluator, J-source codegen
> module (IR → J source → exec via `0!:1`), and Stage 0–1 bootstrap scripts are
> wired up and tested. The full `compile` pipeline
> (`lex → parse → sem → lowerIr → opt → execIr`) runs end-to-end on
> parenthesized and multi-line programs. The next milestones are Stage 2
> (higher-tactic-density refactor), Stage 3 (self-hosting), and a benchmark
> suite.

The interesting twist: the optimiser is designed to integrate **MDL-inspired compression**
(grammar induction over J expressions), so writing *less* code actually makes the
compiler *smarter* about the source it's parsing.

---

## Table of contents

- [Why?](#-why)
- [Tutorial](#-tutorial)
- [Examples](#-examples)
- [Architecture](#-architecture)
- [Quick start](#-quick-start)
- [Project layout](#-project-layout)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [License](#-license)

---

## Why?

J's tacit style — trains, hooks, forks, gerunds, compositions — is what makes it a
*point-free array-language powerhouse*. But the language is large and idiosyncratic;
the canonical interpreter is a closed-source commercial product.

TacitJ asks: **what is the smallest subset of J you can build a real, useful compiler for,
while keeping the result fun to write?**

A few design constraints that drive the project:

| Constraint | Consequence |
|---|---|
| Compiler is **self-hosting** | Source must be a strict subset that compiles cleanly under itself |
| Tacit-first style | Top-level pipeline is one line: `compile =: codegen @ opt @ sem @ parse @ lex` |
| Optimiser uses MDL / grammar induction | Less code → lower description length → "smarter" parses |
| **J 9.7 stdlib only** | Zero external dependencies; the whole toolchain fits in your `$PATH` |
| < 2000 LOC core for Stages 0–3 | Forces aggressive reuse of J's built-ins |

---

## Tutorial

A 30-second tour of TacitJ. If you have J 9.7 installed (`brew install --cask j` on macOS):

### 1. Run an example

```sh
$ make run EXAMPLE=examples/hello.ijs
'hello, world'
hello, world
```

### 2. The canonical tacit pipeline

```j
NB. src/tacitj.ijs
NB. One-line composition of every compiler phase:
compile =: codegen @ optWithEnv @ lowerIr @ semAnalyze @ parseProgram @ lex

NB. Two execution paths:
NB.   compile    - full IR pipeline (lex->parse->sem->lowerIr->opt->execIr)
NB.   runTacitJ  - source-level execution via J's ". / 0!:1 (handles
NB.                multi-line programs that the Stage-0 parser doesn't split)
NB.   runCompile - compile TacitJ source to J source, execute, return result
NB.                (wraps emitted code as `r =: <src>` / `r` to capture the
NB.                value, since 0!:1 returns VOID in J 9.7)
NB.
NB. The codegen module (src/codegen.ijs) provides:
NB.   emitIr      - unparse IR to J source string
NB.   emitFile    - write IR as J source to a file
NB.   compileFile - read source, compile, emit to output file
NB.   execSource  - execute a raw J source string and return the result
NB.   runCompile  - compile TacitJ source and execute via the pipeline
```

### 3. Run the test suite

```sh
$ make test
=== TacitJ test suite ===

-- Lexer tests --
  PASS  integer literal
  PASS  verb +, *, -
  PASS  adverb /
  PASS  conjunction @
  PASS  string 'hello'
  PASS  6 tokens in x =: 1 + 2
  PASS  3-train +/ % # tokens
  ...

-- IR tests --
  PASS  irTrain3: opcode
  PASS  unparse: +/ % #
  PASS  lowerIr: 2 + 3 -> IR_PROG
  PASS  lowerIr: mean =: +/ % # -> IR_ASSN
  PASS  compile: 2 + 3 = 5
  PASS  compile: 3 * 4 + 5 = 27 (right-to-left)
  PASS  compile: 1 + 2 * 3 = 7 (right-to-left)
  PASS  compile: 10 - 4 = 6
  PASS  opt: fixed point on ( 2 + 3 )

-- Optimizer tests --
  PASS  fold: 1 + 2 = 3
  PASS  fold: 2 ^ 10 = 1024
  PASS  opt-train2: (] inc) -> REF inc
  PASS  opt-train3: ([ v ]) -> REF v
  PASS  prop: x + 0 = 5
  PASS  mdlCost: IR_TRAIN2 = 2

-- Pipeline tests --
  PASS  runTacitJ: 3 * 4 + 5 = 27 (J right-to-left)
  PASS  runTacitJ: mean =: +/ % # ; mean 1..5 (no crash)
  PASS  runFile: examples/mean.ijs ran without crash

-- Codegen tests --
  PASS  emitIr: 2 + 3
  PASS  emitIr: mean =: +/ % #
  PASS  runCompile: 10 - 3 = 7
  PASS  emitFile: returns 0 on success
  PASS  compileFile: returns 0 on success

=== Summary ===
95 passed, 0 failed.
```

---

## Examples

All examples live in [`examples/`](examples/) and are valid J-Tacit-Core (runnable with `make run EXAMPLE=…`).

### [`hello.ijs`](examples/hello.ijs) — minimal smoke program

```j
NB. A bare expression sentence; the evaluator prints the value
NB. back as the result.

'hello, world'
```

### [`mean.ijs`](examples/mean.ijs) — the canonical 3-train

```j
NB. `+/ % #` is a fork: computes the arithmetic mean of a list.

mean =: +/ % #

mean 1 2 3 4 5        NB. -> 3
mean 10 20 30         NB. -> 20
```

### [`train.ijs`](examples/train.ijs) — hooks, forks, and bindings

```j
NB. 3-train (fork)
mean =: +/ % #
NB. 2-trains (hooks) using & for constant binding
double =: 2&*
incr   =: 1&+

mean 1 2 3 4 5       NB. -> 3
double 7              NB. -> 14
incr 41               NB. -> 42
```

### [`squares.ijs`](examples/squares.ijs) — sum of squares in one line

```j
sumSquares =: +/ @: *:
sumSquares 1 2 3 4 5        NB. -> 55
```

### [`wordcount.ijs`](examples/wordcount.ijs) — tacit word counter

```j
words =: +/ @: (1 , 2 ~:/\ ])
words 'the quick brown fox'  NB. -> 4
```

### [`fib.ijs`](examples/fib.ijs) — golden ratio via Binet-style expression

```j
phi =: (1 + 2 %: 5) % 2
phi                          NB. -> 1.61803...
```

### [`pipeline.ijs`](examples/pipeline.ijs) — tacit composition with `@`

```j
NB. Function composition: (f @ g) y = f (g y)
square =: *:         NB. monadic *  is square
incr   =: >:         NB. monadic >: is increment
pipeline =: square @ incr

pipeline 3           NB. -> 16
pipeline 10          NB. -> 121
```

---

## Architecture

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Source  │──▶│  Lexer   │──▶│  Parser  │──▶│ Semantic │──▶│   IR /   │
│  chars   │   │  (tacit  │   │ (gerund  │   │ (shape/  │   │  MDL     │
│          │   │  cuts)   │   │  dispatch│   │  type)   │   │  nodes   │
└──────────┘   └──────────┘   └──────────┘   └──────────┘   └────┬─────┘
                                                                │
       ┌─────────────────  Optimizer  ◀──────────────────────┐  │
       │  (rewrite system + Solon MDL minimiser, tacit        │  │
       │   trains where possible)                             │  │
       └────────────┬────────────────────────────────────────┘  │
                    ▼                                           │
              ┌──────────┐  ┌──────────┐  ┌──────────┐           │
              │ Codegen  │─▶│  Linker  │─▶│  Exec    │           │
              │ (emitIr  │  │ (load    │  │  (0!:1   │           │
              │  to J)   │  │  via     │  │   or VM) │           │
              │          │  │  temp    │  │          │           │
              │          │  │  file)   │  │          │           │
              └──────────┘  └──────────┘  └──────────┘
```

**Key invariant**: every pass is a verb that consumes / produces a boxed array
representation. Tacit composition is the norm:

```j
compile =: codegen @ optWithEnv @ lowerIr @ semAnalyze @ parseProgram @ lex
```

The IR (`src/ir.ijs`) is a normalised boxed-triple form that sits between the parser
and codegen; the optimizer (`src/opt.ijs`) is a gerund-dispatched rewrite engine
(constant folding, train identity elimination, constant propagation) that reaches a
fixed point via an unparse-based equality test.

For the full technical specification — BNF grammar, component contracts, 5-stage
bootstrap strategy, and Solon/MDL integration sketch — see [`SPEC.md`](SPEC.md).

---

## Quick start

### Prerequisites

- **J 9.7+** ([Dyalog](https://www.dyalog.com/)-compatible subset)

```sh
# macOS
brew install --cask j

# Linux / Windows: see https://www.jsoftware.com/
```

### Run

```sh
git clone https://github.com/Lulzx/tacitj.git
cd tacitj

# Run the test suite (95 tests)
make test

# Run an example
make run EXAMPLE=examples/mean.ijs

# Start the REPL
make repl

# Run the bootstrap pipeline
make bootstrap          # stage 0 + stage 1 round-trip
make stage1 INFILE=examples/hello.ijs OUTFILE=bin/hello.ijs

# Run the benchmark suite
make bench              # compile-ms / out-chars / exec-ms per canary
```

The Makefile auto-detects the Homebrew J cask (`/opt/homebrew/Caskroom/j/*/j*/bin/jconsole`).
If `jconsole` isn't found there or on `$PATH`, override it:

```sh
JC=/full/path/to/jconsole make test
```

> **Note:** `/usr/bin/jconsole` on macOS is the **Java** JMX console, not JSoftware's J.
> The Makefile skips it in favour of the Homebrew cask so `make test` doesn't hang.

---

## Project layout

```
tacitj/
├── src/
│   ├── lex.ijs         tokenizer (verbs, advs, conjs, names, nums, strings, comments)
│   ├── parse.ijs       recursive-descent → boxed AST; train grouping for 2-/3-trains
│   ├── sem.ijs         semantic pass (Stage-0: identity)
│   ├── ir.ijs          IR lowerer (AST→IR_PROG) + unparser (IR→J source) + execIr
│   ├── opt.ijs         optimizer: constant fold, identity elim, const propagation (MDL stub)
│   ├── eval.ijs        Stage-0 evaluator (shells out to J's ". or 0!:1)
│   ├── codegen.ijs     Stage-0 emitter: emitIr / emitFile / compileFile / runCompile
│   └── tacitj.ijs      top-level pipeline + runFile + REPL
│
├── tests/
│   ├── runtests.ijs        test runner with pass/fail counters
│   ├── test_lex.ijs        lexer regression tests
│   ├── test_parse.ijs      parser + parentheses + multi-line tests
│   ├── test_ir.ijs         IR lowerer + end-to-end compile tests
│   ├── test_opt.ijs        optimizer rewrite-rule tests
│   ├── test_pipeline.ijs   runTacitJ / runFile smoke tests
│   └── test_codegen.ijs    emitIr / emitFile / compileFile / runCompile tests
│
├── examples/
│   ├── hello.ijs       minimal smoke program
│   ├── mean.ijs        3-train (mean)
│   ├── train.ijs       2-/3-trains (hooks and forks)
│   ├── pipeline.ijs    tacit composition with @
│   ├── squares.ijs     sum-of-squares (single-line demo)
│   ├── wordcount.ijs   tacit word counter
│   ├── rank.ijs        2-char conjunctions (@:, &:)
│   └── fib.ijs         golden ratio via Binet
│
├── bootstrap/          Stage 1-3 self-host scripts
│   ├── stage0.ijs      module: load Stage 0 + canary helpers
│   ├── stage0_run.ijs  one-shot: stage0 + selfhost + exit
│   ├── stage1.ijs      compile TacitJ source to standalone J
│   ├── stage2.ijs      stub: higher-tacit refactor
│   └── stage3.ijs      stub: full-tacit self-host
│
├── bench/
│   ├── bench.ijs       compile-time / emit-quality benchmark suite
│   └── mdl_demo.ijs    MDL cost + grammar-induction demo
│
├── doc/
│   └── design.md       architecture, decisions, trade-offs
│
├── SPEC.md             full technical specification
├── AGENTS.md           operating manual for AI agents
├── Makefile            build / test / smoke / run / repl
├── LICENSE             MIT
└── README.md           this file
```

---

## Roadmap

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

### Bootstrap stages

| Stage | Description | Status |
|-------|-------------|--------|
| **0** | Hand-written C/J bootstrap (tiny explicit interpreter) | **done** |
| **1** | TacitJ compiler in explicit J, compiled by Stage 0 | ✅ done (`make stage1`) |
| **2** | Same source, increasing tacit %, compiled by Stage 1 | 🟡 stub (planned refactor) |
| **3** | Full tacit version; self-hosting (`diff` Stage 2 == Stage 3) | 🟡 baseline (`make stage3-attempt`) |
| **4+** | Performance VM + LLVM backend | planned |

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
- **Assignment**: `=:`
- **Literals**: numbers, single-quoted strings (with `''` escape)
- **Parens**: `( expr )` for grouping
- **Comments**: `NB.` to end of line

Known not-yet-supported: `@:` (with-rank compose), `~:/\ ` (not-equal
scan), the adverb `\: ` (suffix). These are tracked in
`bootstrap/stage3_attempt.ijs` as future work.

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

- **`doc/design.md`** — new architecture / design-decisions
  document. Covers the IR boxed-triple rationale, the
  `0!:1`-VOID-return workaround, MDL cost decomposition
  (grammar vs data), depth tracking in the lexer, and what's
  deliberately **not** in Stage 0 (`~:/\`, real bytecode
  codegen, self-hosting). Linked from the README.
- **`examples/rank.ijs` polished** — uncommented the
  `floorOfHalf` definition so the example actually runs.

Quick bootstrap tour:
```sh
make stage0       # load Stage 0 + canary check (exit 0 = OK)
make stage1 INFILE=examples/hello.ijs OUTFILE=bin/hello.ijs
make bootstrap    # stage 0 + stage 1 round-trip on hello.ijs
make selfhost     # stage 0 canary + stage 1 deterministic output
make bench        # compile-ms / out-chars / exec-ms per canary
```

Full plan with success criteria, risks, and Solon/MDL chapter: see [`SPEC.md`](SPEC.md). See [`CHANGELOG.md`](CHANGELOG.md) for the release notes. See [`doc/design.md`](doc/design.md) for the architecture / design decisions.

---

## Contributing

This repo is in **early bootstrapping**. Two kinds of contributors are welcome:

### For humans

The codebase is **J 9.7 only**, no external dependencies. Edit freely, but:

1. Read [`SPEC.md`](SPEC.md) for the language subset and architecture.
2. Read [`src/tacitj.ijs`](src/tacitj.ijs) — it's the canonical composition order.
3. Run `make test` before sending a patch.
4. Match the existing code style (J banner comments per file, boxed triples for AST nodes).

### For AI agents

See [`AGENTS.md`](AGENTS.md) for the operating manual: toolchain, code style,
verification rules, what *not* to do. (TL;DR: don't add dependencies, don't change the
AST node shape without updating all consumers, don't commit until asked.)

---

## Acknowledgments

- **[JSoftware](https://www.jsoftware.com/)** for the J language and interpreter — TacitJ
  wouldn't exist without `J` and the decades of design that went into it.
- **Kenneth Iverson** for inventing APL and J.
- The broader **array-programming** community.
- The **MDL / Solomonoff induction** tradition for the compression-as-intelligence idea
  that drives the optimiser design.

---

## License

[MIT](LICENSE) © 2026 TacitJ contributors.

J is a trademark of JSoftware. This project is an independent, community compiler
project and is not affiliated with or endorsed by JSoftware.
