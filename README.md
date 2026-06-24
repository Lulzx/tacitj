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

> **Status: Stage 0 complete.** The lexer, parser, semantic pass, and a tree-walking
> evaluator that shells out to J are wired up and tested. The next stages replace the
> evaluator with a real bytecode / C backend.

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
compile =: codegen @ opt @ semAnalyze @ parseProgram @ lex

NB. Read source, produce a value:
runTacitJ =: 3 : 0
  src =. y
  toks =. lex src
  ast  =. parseProgram toks
  ast  =. semAnalyze ast
  evalProgram ast
)
```

### 3. Run the test suite

```sh
$ make test
=== TacitJ test suite ===

-- Lexer tests --
  PASS  integer literal
  PASS  float literal
  PASS  identifier foo
  PASS  multi-char identifier
  PASS  verb +, *, -
  PASS  adverb /
  PASS  conjunction @
  PASS  lparen, rparen
  PASS  assign =:
  PASS  string 'hello'
  PASS  NB. comment line is stripped
  PASS  inline comment after code
  PASS  6 tokens in x =: 1 + 2
  PASS  3-train +/ % # tokens
  PASS  third # of +/ % # tokens

-- Pipeline tests --
  PASS  runTacitJ 'hello world'
  PASS  runTacitJ 2 + 3
  PASS  runTacitJ 3 * 4 + 5  (J right-to-left)
  PASS  runTacitJ pi =: 3.14159 ; pi
  PASS  runTacitJ mean =: +/ % # ; mean 1 2 3 4 5

=== Summary ===
24 passed, 0 failed.
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
              │ (J-byte  │  │          │  │  / VM    │           │
              │  / C-FFI)│  │          │  │          │           │
              └──────────┘  └──────────┘  └──────────┘
```

**Key invariant**: every pass is a verb that consumes / produces a boxed array
representation. Tacit composition is the norm:

```j
compile =: codegen @ opt @ semAnalyze @ parseProgram @ lex
```

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

# Run the test suite (26 tests, ~3 s)
make test

# Run an example
make run EXAMPLE=examples/mean.ijs

# Start the REPL
make repl
```

If `jconsole` isn't on `$PATH`:

```sh
JC=/full/path/to/jconsole make test
```

---

## Project layout

```
tacitj/
├── src/
│   ├── lex.ijs         tokenizer (verbs, advs, conjs, names, nums, strings, comments)
│   ├── parse.ijs       recursive-descent → boxed AST; train grouping for 2-/3-trains
│   ├── sem.ijs         semantic pass (Stage-0: identity)
│   ├── eval.ijs        Stage-0 evaluator (shells out to J's ". or 0!:101)
│   └── tacitj.ijs      top-level pipeline + runFile + REPL
│
├── tests/
│   ├── runtests.ijs    test runner with pass/fail counters
│   ├── test_lex.ijs    lexer regression tests
│   └── test_pipeline.ijs   end-to-end pipeline tests
│
├── examples/
│   ├── hello.ijs       minimal smoke program
│   ├── mean.ijs        3-train (mean)
│   ├── train.ijs       2-/3-trains (hooks and forks)
│   └── pipeline.ijs    tacit composition with @
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
| 2 | IR + Optimizer + tacit rewrite engine + Solon stub | planned |
| 3 | Codegen + Stage 1–3 bootstrap scripts + full test suite | planned |
| 4 | Polish, benchmarks (vs explicit), docs, GitHub release | planned |

### Bootstrap stages

| Stage | Description | Status |
|-------|-------------|--------|
| **0** | Hand-written C/J bootstrap (tiny explicit interpreter) | **done** |
| **1** | TacitJ compiler in explicit J, compiled by Stage 0 | planned |
| **2** | Same source, increasing tacit %, compiled by Stage 1 | planned |
| **3** | Full tacit version; self-hosting (`diff` Stage 2 == Stage 3) | planned |
| **4+** | Performance VM + LLVM backend | planned |

Full plan with success criteria, risks, and Solon/MDL chapter: see [`SPEC.md`](SPEC.md).

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
