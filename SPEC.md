# TacitJ — Technical Specification

**Codename**: SolonJ / TacitBoot
**Version**: 0.21 (Draft, MVP-ready)
**Date**: 2026-08-14
**Status**: Actionable blueprint for MVP → full self-host

---

## 1. Project Overview & Goals

**TacitJ** is a self-hosting compiler for a well-defined subset of **J** that
emphasises **tacit programming** — trains, hooks, forks, gerunds and
compositions — while supporting just enough explicit constructs for
bootstrapping.

**Primary goals**, aligned with Solon MDL/compression and 1000× efficiency
interests:

- The compiler source (in TacitJ) must compile itself to produce a working
  binary/bytecode image.
- Maximise tacit usage in compiler passes to demonstrate point-free elegance
  for IR transformation, rewrite systems and grammar induction.
- Integrate MDL-inspired compression / grammar induction for the parser and
  optimizer (reuse Solon ideas).
- Bootstrap in **5 stages or fewer**, with a **< 2 000 LOC** core for rapid
  iteration.
- Output: J bytecode (or C/LLVM via FFI), executable via the existing J
  interpreter or a standalone VM.

**Success criteria**

| # | Criterion |
|---|-----------|
| 1 | Stage 3 self-compiles with byte-identical output to Stage 2. |
| 2 | Tacit-to-explicit converter + optimizer beats naive explicit by ≥ 2× on token count / speed. |
| 3 | Full test suite passes, including compiler-on-compiler. |

---

## 2. Scope & Language Subset ("J–Tacit Core")

### 2.1 Supported

- Nouns (literals, names).
- Verbs, adverbs, conjunctions (limited set — see `src/lex.ijs`).
- Full tacit: 2-/3-trains, hooks, forks, atop, compose, etc.
- Gerunds (`m`v`) and agenda (`u`m`v`) — implemented in v0.21
  (backtick tie `` ` `` and `@.` lex/parse/unparse; constant verbs
  `0:`–`9:` are single tokens).
- Basic control: explicit `{{ }}` dfns only for non-tacit fallbacks.
- Arrays, shapes, ranks, boxing.

### 2.2 Excluded (Phase 1)

Full OOP (heavy conjunctions), foreigns, full graphics, `".` arbitrary
execution (Phase 1 only — it re-enters in later stages).

### 2.3 Grammar (BNF, Phase-1 subset)

```bnf
program     ::= sentence* EOF
sentence    ::= ( NAME ASSIGN )? expr
expr        ::= train
train       ::= term ( verb term | adv | conj term )*
term        ::= NUM | STR | NAME | '(' expr ')'
verb        ::= '+' | '-' | '*' | '/' | '%' | '^' | '=' | '<' | '>' | '|' | '&' | '~' | ';' | ',' | '#' | '$' | '!' | '?' | '.'
adv         ::= '/' | '\' | '~' | '.' | ':'
conj        ::= '@' | '&' | '^'
```

The runtime classifies sequences of 2 or 3 terms in a `train` as a **hook**
or **fork** per J's standard rules; the AST carries them as flat token lists
so the evaluator can apply J's native semantics.

---

## 3. High-Level Architecture

### 3.1 Pipeline

```
┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│  Source  │──▶│  Lexer   │──▶│  Parser  │──▶│ Semantic │──▶│   IR /   │
│  chars   │   │  (tacit  │   │ (gerund  │   │ (shape/  │   │  MDL     │
│          │   │  cuts)   │   │  dispatch│   │  type)   │   │  nodes   │
└──────────┘   └──────────┘   └──────────┘   └──────────┘   └────┬─────┘
                                                                │
       ┌─────────────────  Optimizer  ◀──────────────────────┐  │
       │  (rewrite system + Solon MDL minimiser, tacit       │  │
       │   trains where possible)                            │  │
       └────────────┬────────────────────────────────────────┘  │
                    ▼                                           │
              ┌──────────┐  ┌──────────┐  ┌──────────┐           │
              │ Codegen  │─▶│  Linker  │─▶│  Exec    │           │
              │ (J-byte  │  │          │  │  / VM    │           │
              │  / C-FFI)│  │          │  │          │           │
              └──────────┘  └──────────┘  └──────────┘           │
```

### 3.2 Key invariant

**Every pass is a verb that consumes / produces boxed array representations.**
Tacit composition is the norm at the *composition* level:

```j
compile =: codegen @ optimize @ sem @ parse @ lex
```

Recursive-descent passes necessarily use explicit control; this is the
exception, not the rule.

### 3.3 Stage 0 today

`src/tacitj.ijs` wires lexer → parser → semantic → evaluator. The evaluator
unparses the AST back to J source and executes it via `".` inside a per-program
namespace. This is a **transpile-and-run** strategy that gives us a working
end-to-end pipeline immediately; later stages replace the `eval` step with a
real bytecode/C backend.

---

## 4. Detailed Component Specs

### 4.1 Lexer (`src/lex.ijs`)

- **Input**: character array.
- **Primitives**: J's `;:` semantics extended with custom cuts on
  `=.:'(){}`.
- **Output**: token table `(type ; value ; pos)` per token.
- **Tacit-leaning**: top-level `lex` composes `cutOnSymbols ; classify` over
  whitespace-stripped input.

```j
NB. illustrative
lex =: classify @ (cutOn ` (cutOn=: ;:) @. isText) @ stripComments
```

Token types are enumerated in `src/lex.ijs` (`T_NAME`, `T_VERB`, …).
v0.19 additions:

- `T_DEF` — a whole explicit-definition block (`3 : 0 ... )` /
  `4 : 0 ... )`) captured verbatim as one token (see §4.7).
- `_`-literals: `_1`, `_3.14`, `_` (infinity), `__` (negative
  infinity), `_.` (NaN) lex as single `T_NUM` tokens.
- Comment stripping is string-aware (`'NB.'` inside a string is
  data, not a comment) and def-aware (comment lines inside a
  def body are preserved verbatim so blocks round-trip).

### 4.2 Parser (`src/parse.ijs`)

Recursive descent over a token stream, **gerund-dispatched** by the leading
token kind. Produces a boxed AST where:

- **Leaves** are boxed pairs `(kind ; value)`.
- **Internal nodes** are boxed triples `(kind ; left ; right)`.

Tacit heavy where possible:

```j
parseTrain =: forkParser ` hookParser ` atopParser @. trainType
```

Grammar-induction hook: optional Solon-style MDL minimiser for ambiguous
cases (`parse.ijs::resolveAmbiguity`).

### 4.3 Semantic Analysis & Type System (`src/sem.ijs`)

Shape/type propagation via rank polymorphism (native J strength). Each AST
node gains a `; type ; shape` trailer.

```j
NB. illustrative
infer =: (rankMatch * typeJoin) f.
```

### 4.4 IR & Optimizer (Core Innovation, Stages 2+)

- **IR**: array of MDL nodes (production rules + probability weights).
- **Optimizer passes** as tacit trains: CSE, constant fold, sparsity.
- **Rewrite engine**: `rewrite =: agendaTable @. matchRule` (gerund table
  keyed on AST shape).

### 4.5 Codegen (Stages 1+)

- **Target 1**: J bytecode image (loadable via custom `9!:`).
- **Target 2**: C stubs for self-host VM.
- **Tacit emitter**:
  ```j
  emitFork =: ' ( ' , u , ' ' , v , ' ' , w , ' ) ' "  _  NB. illustrative
  ```

### 4.7 Explicit-Definition Blocks (v0.19)

The single biggest blocker to self-host was that the compiler
source is ~85 % `3 : 0` / `4 : 0` explicit definitions, which the
Stage 0 pipeline could not lex or parse. v0.19 treats an explicit
def as an **opaque verbatim block**:

- **Lexer**: `3 : 0` / `4 : 0` at a token position starts a block
  scan that captures every line verbatim up to the line whose
  leading non-whitespace character is `)` — J's own terminator
  rule. The block becomes one `T_DEF` token whose value is the raw
  source (comments, strings, control words — all untouched).
- **Parser**: `T_DEF` maps to an `AST_DEF` leaf and ends its
  sentence (a def cannot be fused into a train with the next
  sentence). Chained assignment `a =: b =: c` parses
  right-associatively.
- **IR**: `AST_DEF` lowers to `IR_DEF`; the unparser emits it
  verbatim. The optimizer treats it as an opaque leaf.
- **Result**: every `src/*.ijs` file compiles through the pipeline
  and round-trips as a syntactic fixed point, and the emitted
  modules re-load to a working compiler (`make selfhost-full`).

v0.20 closed the remaining gaps: top-level execution
statements (`load`, `smoutput`, `runArgv`) execute correctly
through the emitted compiler's exec path (they are no longer
unevaluated verb phrases); one-line explicit defs (`3 : '...'`)
are captured verbatim as `T_DEF` (no parenthesised-train
emission); and `{{ }}` direct definitions are captured as opaque
`T_DEF` tokens (single-line and multi-line). v0.21 adds gerund
tie (`` ` ``) and agenda (`@.`) support (SPEC §2.1).

### 4.6 Bootstrap Strategy (5 Stages)

| Stage | Description | Language of compiler | Language compiled | Status |
|-------|-------------|----------------------|-------------------|--------|
| **0** | Hand-written C/J hybrid bootstrap (tiny explicit interpreter for J–Tacit Core). | C / J stdlib | TacitJ | done |
| **1** | TacitJ compiler written in explicit J, compiled by Stage 0. | explicit J | TacitJ | done (`make stage1`) |
| **2** | Output-contract freeze + tacit-density baseline (round-trip fixed points over a canary corpus). | mixed J | TacitJ | done (`make stage2`) |
| **3** | Full tacit version; `Stage3 =: Stage2 compile Stage3Source`. | TacitJ | TacitJ | partial→advanced (`make stage3`, `make selfhost-full`) |
| **4+** | Performance VM + LLVM backend. | TacitJ | TacitJ → native | planned |

**Verification**:
- `diff` on binary output.
- `checksum(compiler_source) == checksum(compiler_on_itself)`.
- Full test-suite round-trip.

**Stage 2** freezes the output contract: a 5-case canary
corpus where `emit(compile(src)) == emit(compile(emit(compile(src))))`
(round-trip fixed point), plus a tacit-density baseline over
`src/*.ijs` (72 tacit / 125 explicit). **Stage 3** proves the
canary + corpus + safe examples are fixed points. Since v0.21
the IR pipeline also handles the larger examples
(`matrix`/`stats`/`poly`/`sort`/`moving`), which now round-trip
as fixed points (previously they exceeded the IR subset and
were skipped). Full self-host is blocked only on rewriting the
compiler source in the TacitJ subset (the Stage 0 parser does
not recognise `3 : 0`, `<`, `0!:0`, etc.); the front-end now
handles the constructs the compiler source actually uses (see
v0.19–v0.21 below).

**v0.19 (2026-08-14)**: the first hard blocker fell. The
front-end now handles the constructs the compiler source
actually uses: explicit-definition blocks (`3 : 0 ... )` /
`4 : 0 ... )` as opaque verbatim tokens — new `T_DEF` token,
`AST_DEF` node, `IR_DEF` opcode), string-aware and def-aware
comment stripping (`'NB.'` inside a string is data), J
`_`-literals (`_1`, `_3.14`, `_`, `__`, `_.`), chained
assignment (`a =: b =: c`), and a parser progress guard (no
infinite loops on zero-progress sentences). Every `src/*.ijs`
file now compiles through the pipeline and round-trips as a
syntactic fixed point (9/9), and the emitted (self-compiled)
modules load and reproduce the Stage 0 output contract
(`make selfhost-full`).

**v0.20 (2026-08-14)**: closed the remaining §4.7 gaps. `{{ }}`
direct definitions and one-line explicit defs (`3 : '...'`)
are captured verbatim as `T_DEF`; the two-char verbs `":`, `,.`,
`i.`, `e.`, `o.`, `j.`, `r.`, `{.`, `}.`, `/:` and `\:` lex as
single tokens; the semantic pass (`src/sem.ijs`) implements
SPEC §4.3 (shape/type inference, well-formedness, constant
folding, dead-code elimination); and the emitted compiler's
`execIr`/`runTacitJ` execution path is exercised end-to-end
(`make selfhost-full` reports `exec-path fidelity: 1`).

**v0.21 (2026-08-14)**: SPEC §2.1 gerunds and agenda are now
implemented. The backtick tie (`` ` ``) and `@.` (agenda) lex
as single `T_CONJ` tokens, constant verbs `0:`–`9:` lex as
single `T_VERB` tokens, and all unparse unquoted so gerund /
agenda programs round-trip as fixed points and execute. The
IR pipeline also handles the larger examples (`matrix`,
`stats`, `poly`, `sort`, `moving`) — they are fixed points
(§10 item 10).

---

## 5. Non-Functional Requirements

| Concern | Requirement |
|---------|-------------|
| **Performance** | Optimizer demonstrates ≥ 5× reduction in interpreted execution steps on Solon-like workloads. |
| **Self-host proof** | `checksum(compiler_source) == checksum(compiler_on_itself)`. |
| **Testability** | 100 % coverage via the J test suite (lexer roundtrips, self-compile assertions). |
| **Extensibility** | Plugin system via gerunds for new primitives. |
| **Environment** | J 9.x+ (Dyalog-compatible subset), Git, `make` / `jconsole`. |

---

## 6. Implementation Roadmap (4-week MVP)

| Week | Milestone |
|------|-----------|
| **1** | Lexer + Parser + self-compile of a tiny "hello train" program. |
| **2** | IR + Optimizer + tacit rewrite engine + Solon integration stub. |
| **3** | Codegen + Stage 1–3 bootstrap scripts + full test suite. |
| **4** | Polish, benchmarks (vs explicit), documentation, GitHub release. |

**Weekly deliverables**: `.ijs` files, `Makefile`, `README.md` with
`make selfhost` target, benchmark notebook.

---

## 7. Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Tacit readability | Maintain explicit ↔ tacit converter as the first tool. |
| Bootstrap loop | Golden binary checksums + multi-stage CI. |
| Performance | Profile with `ts` and `9!:11` timing; fall back to C FFI for hot paths. |
| Grammar ambiguity | MDL scoring (Solon integration) chooses the lower-description parse. |

---

## 8. Solon / MDL Integration (sketch)

The optimizer's grammar-induction pipeline treats each rewrite rule as a
production in a probabilistic grammar. The MDL cost of a candidate rewrite
is `L(data | grammar) + L(grammar)`. Lower-MDL rewrites win; this is the
"compression-as-correctness" signal Solon is built on.

```j
NB. illustrative
mdlCost =: negentropy @ grammarLength + dataFit
pick    =: <./ @: (#~ <:&mdlCost)   NB. keep the cheapest rewrite
```

This is the smallest hook into Solon; deeper integration (e.g. distributed
MDL minimisation) is a Stage-4 deliverable.

---

## 9. Appendix: Starter Code Snippets

```j
NB. example tacit compiler skeleton
lex =: classify @ cutOn @ stripComments
parse =: parseProgram :: 0
compile =: codegen @ opt @ sem @ parse @ lex

NB. top-level pipeline (loaded by src/tacitj.ijs)
runTacitJ =: 1 : '". ns bind (unparse ;.0) parse lex y'
```

### 9.1 Hello, train

```j
NB. examples/hello.ijs
NB. Define a tacit hook that returns "hello" or "world" based on x
NB. (v0.21: gerund tie ` and agenda @. are supported; a string
NB. constant in a gerund must be boxed, per J's tie semantics.)
greet =: (<'hello')`] @. (1&=) @ ,
greet 0
greet 1
```

### 9.2 Mean via fork

```j
NB. examples/mean.ijs
NB. ( +/ % # ) is a 3-train fork
mean =: +/ % #
mean 1 2 3 4 5
```

### 9.3 Tacit pipeline

```j
NB. examples/pipeline.ijs
square =: * : NB. monadic *
inc    =: >: 
pipeline =: square @ inc
pipeline 3
NB. -> 16
```

---

## 10. Next actions

1. **Repo skeleton** ✓ — `make test` target, directories, `AGENTS.md`.
2. **Stage 0 bootstrap** ✓ — `src/{lex,parse,sem,eval,tacitj}.ijs`.
3. **Test suite** ✓ — `tests/test_*.ijs`, `runtests.ijs`.
4. **Examples** ✓ — `examples/{hello,mean,pipeline}.ijs`.
5. **Stage 1** ✓ — compile a TacitJ file to a standalone J script (`make stage1`).
6. **Stage 2** ✓ — output-contract freeze + tacit-density baseline (`make stage2`).
7. **Stage 3** 🟢 self-host advanced (`make stage3`,
   `make selfhost-full`): canary + corpus + safe examples verified
   as fixed points, and **every `src/*.ijs` file round-trips**
   (9/9 fixed points); the self-compiled compiler reproduces the
   output contract and its exec path runs end-to-end
   (`exec-path fidelity: 1`). The §4.7 noun/verb emission edge
   cases (one-line defs, `{{ }}` dfns, top-level execution
   statements) are closed in v0.20.
8. (Stage 4+) Replace `eval` with real bytecode/C codegen; performance VM + LLVM backend.
9. (Stage 2 refactor) Raise the tacit-density fraction (72/125 today) while keeping the Stage 2 output contract green.
10. ✓ Fix the latent IR-pipeline hang on `matrix`/`stats`/`poly`/`sort`/`moving` (distinct from `runTacitJ`, which runs them). v0.21: all five now lex→parse→sem→lower→opt→emit and round-trip as fixed points.
