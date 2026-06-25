# TacitJ Design Notes

> Architecture, decisions, and trade-offs in the Stage 0
> compiler. Companion to `SPEC.md` (the language spec) and
> `README.md` (the user-facing guide).

## 1. The pipeline at a glance

```
       char vector
            │
            ▼
          lex ────────────── boxed token list
            │
            ▼
        parseProgram ───────── AST (boxed triples)
            │
            ▼
        semAnalyze ─────── (identity pass in Stage 0)
            │
            ▼
        lowerAst ──────────── IR (boxed triples, lower-level)
            │
            ▼
       optWithEnv ──────────── IR (rewrites applied until fixpoint)
            │
            ▼
         execIr ──────────── runs the emitted J source
```

The composition is one tacit line in `src/tacitj.ijs`:

```j
compile =: codegen @ optWithEnv @ lowerIr @ semAnalyze @ parseProgram @ lex
```

`codegen` is `execIr` (run the emitted source). The IR pipeline
is fixed-point iterated to a safety bound of 8 passes.

## 2. Why is the IR a boxed triple?

Every IR node is `(<op ; <args ; <meta)`:

- **op**: an integer opcode (`IR_LIT`, `IR_CALL`, `IR_TRAIN2`, ...)
- **args**: the children (or the literal value, for `IR_LIT`/`IR_REF`)
- **meta**: source-loc marker, type tag, etc. (usually `a:`)

The triple wrapping defeats J's `,` unrolling of 2-element boxed
lists. J will aggressively unroll `(a ; b)` into the literal `a b`
in many contexts, which would corrupt our structure. Each link is
wrapped in `<(...)` to keep it a 1-box-of-1-box.

Accessing an IR node:
```j
irOp   y  NB. unboxes the 1-box, takes 0-th, unboxes the value
irArgs y  NB. unboxes the 1-box, takes 1-st, unboxes the value
irMeta y  NB. unboxes the 1-box, takes 2-nd, unboxes the value
```

## 3. Why emit J source, not bytecode?

`SPEC §10 item 5` calls for "real bytecode / C codegen". For Stage 0
we chose to emit J source and execute via `".` / `0!:1`:

- **Speed of iteration**: the entire Stage 0 compiler is ~1000 LOC
  of J. Writing a bytecode emitter + interpreter is at least
  another 1000 LOC and a debugging cycle we couldn't afford.
- **Free execution**: emitting valid J source means we get a
  working runtime for free via J itself. No new VM.
- **Self-hosting foundation**: once the Stage 0 compiler can produce
  J source that calls itself, Stage 3 self-hosting is "just" a
  file-write away.

The trade-off: we depend on J's runner semantics. When the runner
hits a foreign like `0!:1` that returns `VOID`, the result is
a `0 0$0` empty array, which we have to special-case in the demo
display (`(empty)`).

## 4. Why is the lexer so careful with depth?

J uses `(` ... `)` for grouping and there's no syntactic marker for
"end of sentence". In J, sentences are separated by line-feed at
parens depth 0. The Stage 0 lexer now emits `T_SENT_END` at depth-0
LF so the parser can correctly split a multi-line program into
multiple sentences.

Without this, `x =: 5\nx + 1` would be parsed as one giant sentence
`x =: 5 x + 1`, which J would then try to parse as a single
expression with bizarre results.

## 5. Why use `>` for unboxing, and when does it bite?

J's `>` is the "open" / "unbox" verb. Our `irOp`, `irArgs`, `irMeta`
use `>` internally. The wrapper is:

```j
unboxIr =: 3 : 0
  ir =. y
  cnt =. 0
  while. (32 = 3!:0 ir) *. (cnt < 8) do.
    if. 3 = # ir do. ir return. end.
    ir =. > ir
    cnt =. >: cnt
  end.
end.
```

This peels boxes until either the structure is 3-element (the
canonical IR shape) or we've peeled 8 levels (safety bound). The
bound exists because deeply nested unboxes are almost always a bug
somewhere upstream.

The bite: when a recursive verb returns an IR `r`, `> r` is the
inner. If we then do `mdlScore r` inside a child loop, `mdlScore`
unboxes again. So the unboxing inside `mdlScore` is a no-op — fine
for performance, but it means `mdlScore` must be defensive about
the box level of its input. (It is; see the `if. 32 = 3!:0 ir do.
...` guard at the top of `mdlScore`.)

## 6. MDL cost: a Solon-style minimizer

`SPEC §8` sketches a Solon-style MDL cost function. We
implemented a concrete version in `src/mdl.ijs`:

```
mdl(IR) = sum_over_nodes (op_cost[op] + data_cost[lit])
```

- **op_cost**: 1 for literals/refs, 2-3 for trains/conjs, 4 for
  generic calls. The grammar cost; the cost of the rule.
- **data_cost**: 1 per character of literal value. The data cost;
  the cost of the data the rule produces.

The minimizer `mdlMinimize` runs `optPass` (the rule-based
optimizer) up to 8 times and picks the lowest-MDL-cost variant.
This isn't full Bayesian grammar induction, but it surfaces
the same pattern signal: smaller-MDL IRs are "more compressed"
and presumably "more idiomatic J".

The `grammarInduce` demo (see `bench/mdl_demo.ijs`) shows the
frequency of common sub-IRs across a corpus. In the demo's
4-IR corpus (`1+2`, `1*2`, `1+3`, `2*3`), the literals `1` and
`2` each appear 3 times and the operators `+` and `*` each appear
2 times — the corpus is using a small grammar.

## 7. The `0!:1` VOID-return workaround

In J 9.7, `0!:1 <file>` and `0!:101 <file>` execute a script but
**return `VOID`**. The side-effect is that names defined in the
script become visible in the caller's namespace.

For `runCompile` in `src/codegen.ijs`, we wrap the emitted source
as `r =: <jsrc>` / `r` and read `r` after execution. The wrapping
relies on J's `0!:1` not eating global-name side effects.

For interactive use (`make run EXAMPLE=...`), the example files
must use `smoutput` to display their results, because the script
runner's result isn't surfaced by `0!:1`.

## 8. What's deliberately not in Stage 0

- **Foreigns**: `9!:` family, `13!:` family, etc. We emit plain J
  source, so anything J can do via `0!:0` is on the table.
- **`~:/\`**: "not-equal prefix scan" is a 3-token sequence in
  the current lexer (`~:`, `/`, `\`). The parser doesn't compose
  adverbs correctly, so it would have to be added as a single
  3-char token.
- **Real codegen / C backend**: SPEC §10 item 5. Out of scope for
  Stage 0 (see §3 above).
- **Self-hosting**: SPEC §10 item 7. The src/*.ijs files use
  J-specific syntax (`3 : 0`, `=:` as part of defns, etc.) that the
  Stage 0 parser doesn't understand. Stage 3 needs either a
  rewrite of src/*.ijs in the TacitJ subset or an expansion of
  the Stage 0 parser.

## 9. Trade-offs the design accepts

- **Per-parse overhead**: every `>` is a J verb call. For deep IR
  trees the unboxing adds up. We accept this for code clarity.
- **Boxed-everything**: every IR element is a 1-box. This costs
  ~30% memory vs. flat arrays. Acceptable for correctness.
- **No N-trains for N>3**: `IR_TRAIN` is generic but the parser
  only produces 2- and 3-trains. Larger trains are rare in J.
- **Fixed point at 8 passes**: the optimizer can run forever on
  certain pathological inputs (constant folding producing new
  constants). 8 is empirically safe.

## 10. See also

- `SPEC.md` — the language spec, MDL sketch, bootstrap plan.
- `README.md` — user-facing guide, quick start, roadmap.
- `CHANGELOG.md` — release notes.
- `AGENTS.md` — operating manual for AI agents.
- `bootstrap/stage3_attempt.ijs` — current Stage 3 self-host
  baseline (5/5 examples compiled via Stage 0).