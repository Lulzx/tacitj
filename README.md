# TacitJ

> A self-hosting compiler for a tacit-leaning subset of **J**,
> written in J.

[![J version](https://img.shields.io/badge/J-9.7-blue.svg)](https://www.jsoftware.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Stage](https://img.shields.io/badge/stage-0-yellow.svg)]()

**TacitJ** is a compiler for a well-defined subset of [J](https://www.jsoftware.com/) that emphasises
*tacit programming* — trains, hooks, forks, gerunds, and compositions — while supporting
just enough explicit constructs for bootstrapping.

The compiler source (in TacitJ) is designed to compile itself to produce a working bytecode image.
The optimizer is intended to integrate MDL-inspired compression / grammar induction for the
parser/optimizer pipeline.

---

## Why

J's tacit style is what makes it a point-free array-language powerhouse. This project builds a
compiler whose *own source* is written in the same tacit style, then proves self-hosting through
staged bootstrapping.

The long-term goals (see [`SPEC.md`](SPEC.md)):

- **5-stage bootstrap**, target < 2000 LOC core
- MDL-inspired compression/grammar induction in the optimizer (Solon-style)
- Output: J bytecode (or C/LLVM via FFI), executable via J interpreter or standalone VM

---

## Quick start

Requires **J 9.7+** (Dyalog-compatible subset).

```sh
# macOS: install J
brew install --cask j

# Run the test suite
make test

# Run an example program
make run EXAMPLE=examples/hello.ijs

# Read the test output
JC=jconsole make test
```

If `jconsole` isn't on `$PATH`, override `JC`:

```sh
JC=/full/path/to/jconsole make test
```

---

## What's in the box

```
src/
  lex.ijs        Stage-0 tokenizer (verbs, adverbs, conjunctions, names, numbers, strings, comments)
  parse.ijs      Recursive-descent parser (boxed AST, train grouping)
  sem.ijs        Semantic pass (Phase-1: identity / pass-through)
  eval.ijs       Stage-0 evaluator (shells out to J's `."` and `0!:101`)
  tacitj.ijs     Top-level pipeline + `runFile` + REPL

tests/
  runtests.ijs   Test runner
  test_lex.ijs   Lexer regression tests
  test_pipeline.ijs  End-to-end pipeline tests

examples/
  hello.ijs      Minimal smoke program (bare expression)
  train.ijs      2- and 3-trains (hooks and forks)
  mean.ijs       Mean via 3-train (`+/ % #`)
  pipeline.ijs   Tacit composition with `@`

SPEC.md           Full technical specification
AGENTS.md         Operating manual for AI agents working in this repo
Makefile          Build / test / smoke targets
```

---

## Stage 0 capability (current)

`src/tacitj.ijs` wires lexer → parser → semantic → evaluator. The Stage-0 evaluator unparses the
AST back to J source and executes it via `".` or `0!:101` inside a per-program namespace. This
gives us a working end-to-end pipeline today; real compilation comes in later stages.

```
Source ──lex──▶ Token stream ──parse──▶ AST ──sem──▶ Typed AST ──eval──▶ Result
```

The canonical pipeline is a tacit composition:

```j
compile =: codegen @ opt @ semAnalyze @ parseProgram @ lex
```

### Example

```sh
$ make run EXAMPLE=examples/mean.ijs
   mean =: +/ % #
   
   mean 1 2 3 4 5
3
   mean 10 20 30
20
```

---

## Roadmap

See [`SPEC.md`](SPEC.md) §6 for the full 4-week MVP plan:

| Week | Milestone |
|------|-----------|
| 1 | Lexer + Parser + self-compile of tiny "hello train" program |
| 2 | IR + Optimizer + tacit rewrite engine + Solon integration stub |
| 3 | Codegen + Stage 1–3 bootstrap scripts + full test suite |
| 4 | Polish, benchmarks (vs explicit), documentation, GitHub release |

Stages:

| Stage | Description | Status |
|-------|-------------|--------|
| **0** | Hand-written C/J bootstrap (tiny explicit interpreter) | **done** |
| **1** | TacitJ compiler written in explicit J, compiled by Stage 0 | planned |
| **2** | Same source, increasing tacit %, compiled by Stage 1 | planned |
| **3** | Full tacit version; self-hosting | planned |
| **4+** | Performance VM + LLVM backend | planned |

Verification at Stage 3: `diff` on binary output between Stage 2 and Stage 3 must be empty.

---

## Contributing

This repo is in **early bootstrapping**. For AI agents working in this repo, see
[`AGENTS.md`](AGENTS.md) for the operating manual (toolchain, code style, verification rules).

For humans: the codebase is J 9.7 only, no extra dependencies. Edit freely, run `make test`
before sending a patch.

---

## License

[MIT](LICENSE) © 2026 TacitJ contributors

J is a trademark of JSoftware. This project is an independent compiler project and is not
affiliated with JSoftware.
