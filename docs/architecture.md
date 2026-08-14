# Architecture

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
bootstrap strategy, and Solon/MDL integration sketch — see [`SPEC.md`](../SPEC.md).

---

