<div align="center">

# TacitJ

**A self-hosting compiler for a tacit-leaning subset of [J](https://www.jsoftware.com/), written in J.**

[![J version](https://img.shields.io/badge/J-9.7-blue.svg)](https://www.jsoftware.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Stage](https://img.shields.io/badge/Stage-0-yellow.svg)](SPEC.md)
[![GitHub stars](https://img.shields.io/github/stars/Lulzx/tacitj?style=social)](https://github.com/Lulzx/tacitj/stargazers)

[Quick start](#-quick-start) | [Project layout](#-project-layout) | [Documentation](#-documentation) | [Contributing](#-contributing)

</div>

---

## What is TacitJ?

**TacitJ** is a compiler for a curated subset of [J](https://www.jsoftware.com/), the
array language known for its terse, point-free, tacit style. The compiler's own source is
written in that same tacit style, and the goal is for the compiler to compile itself (a
*self-hosting* bootstrap).

The optimiser uses MDL-inspired compression (grammar induction over J expressions):
writing less code makes the compiler smarter at parsing it.

---

## Why?

J's tacit style (trains, hooks, forks, gerunds, compositions) is what makes it a
point-free array language. But the language is large and idiosyncratic; the canonical
interpreter is a closed-source commercial product.

TacitJ asks: what is the smallest subset of J you can build a real, useful compiler for,
while keeping the result fun to write?

| Constraint | Consequence |
|---|---|
| Compiler is **self-hosting** | Source must be a strict subset that compiles cleanly under itself |
| Tacit-first style | Top-level pipeline is one line: `compile =: codegen @ opt @ sem @ parse @ lex` |
| Optimiser uses MDL / grammar induction | Less code → lower description length → "smarter" parses |
| **J 9.7 stdlib only** | Zero external dependencies; the whole toolchain fits in your `$PATH` |
| < 2000 LOC core for Stages 0–3 | Forces aggressive reuse of J's built-ins |

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

# Run the test suite (225 tests)
make test

# Run an example
make run EXAMPLE=examples/mean.ijs

# Start the REPL
make repl

# Run the bootstrap pipeline
make bootstrap          # stage 0 -> 1 -> 2 -> 3
make stage2             # freeze output contract + tacit-density baseline
make stage3             # honest partial self-host milestone
make stage1 INFILE=examples/hello.ijs OUTFILE=bin/hello.ijs

# Run the benchmark suite
make bench              # compile-ms / out-chars / exec-ms per canary

# Run the MDL / grammar-induction demo
make mdl-demo           # mdlScore + grammarInduce + mdlMinimize

# Run the pipeline-trace demo (each stage's output for a sample)
make trace
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
├── src/               compiler source (lex, parse, sem, ir, opt, eval, codegen, tacitj)
├── tests/             J test suite (runtests + test_<module>.ijs)
├── examples/          runnable example programs
├── bootstrap/         Stage 1-3 self-host scripts
├── bench/             benchmark / MDL / trace demos
├── docs/              language reference, examples, architecture, roadmap, design
├── SPEC.md            full technical specification
├── AGENTS.md          operating manual for AI agents
├── Makefile           build / test / smoke / run / repl
├── LICENSE            MIT
└── README.md          this file
```

---

## Documentation

- **[`docs/language.md`](docs/language.md)**: the TacitJ language reference (verbs,
  adverbs, conjunctions, forks and hooks).
- **[`docs/examples.md`](docs/examples.md)**: walkthroughs of every example program.
- **[`docs/architecture.md`](docs/architecture.md)**: the compiler pipeline and IR.
- **[`docs/roadmap.md`](docs/roadmap.md)**: roadmap, bootstrap stages, Stage 0 subset,
  MDL / grammar induction, and the full release history.
- **[`docs/design.md`](docs/design.md)**: architecture, decisions, trade-offs.
- **[`SPEC.md`](SPEC.md)**: the full technical specification (BNF grammar, component
  contracts, 5-stage bootstrap strategy, Solon/MDL integration).
- **[`CHANGELOG.md`](CHANGELOG.md)**: release notes.

---

## Contributing

This repo is in **early bootstrapping**. Two kinds of contributors are welcome:

### For humans

The codebase is **J 9.7 only**, no external dependencies. Edit freely, but:

1. Read [`SPEC.md`](SPEC.md) for the language subset and architecture.
2. Read [`src/tacitj.ijs`](src/tacitj.ijs), the canonical composition order.
3. Run `make test` before sending a patch.
4. Match the existing code style (J banner comments per file, boxed triples for AST nodes).

### For AI agents

See [`AGENTS.md`](AGENTS.md) for the operating manual: toolchain, code style,
verification rules, what *not* to do. (TL;DR: don't add dependencies, don't change the
AST node shape without updating all consumers, don't commit until asked.)

---

## Acknowledgments

- **[JSoftware](https://www.jsoftware.com/)** for the J language and interpreter.
- **Kenneth Iverson** for inventing APL and J.
- The broader **array-programming** community.
- The **MDL / Solomonoff induction** tradition for the compression-as-intelligence idea
  that drives the optimiser design.

---

## License

[MIT](LICENSE) © 2026 TacitJ contributors.

J is a trademark of JSoftware. This project is an independent, community compiler
project and is not affiliated with or endorsed by JSoftware.
