# AGENTS.md — Operating manual for AI agents working in this repo

## Required reading before editing

1. `SPEC.md` — full technical specification, language subset, architecture.
2. `src/tacitj.ijs` — top-level pipeline; the composition order is canonical.
3. `tests/runtests.ijs` — test runner conventions and assertion macros.
4. `CHANGELOG.md` — record notable changes when you commit a new feature.

## Toolchain

- **J interpreter**: 9.7+ (Dyalog-compatible subset). Install with
  `brew install --cask j` on macOS. Set `JC=jconsole` (or full path) in the
  Makefile environment if not on `$PATH`.
- **Tests are pure J**: no Python, no JS, no shell parsing. Just `jconsole`.
- Use `make test` to run the full suite. Use `make run EXAMPLE=examples/X.ijs`
  for one-shot smoke runs.

## Code style

- Every `.ijs` file starts with a banner `NB. ===...` block describing its role.
- Public verbs are named in camelCase or J-style lowercase (`lex`, `parse`,
  `evalAst`, `compilePipeline`).
- Internal helpers are prefixed `_` or kept private via `NB.` comments.
- Tacit pipelines (`f @ g @ h`) are preferred at the composition level.
  Recursive-descent passes necessarily use explicit control.
- Token / AST nodes are **boxed triples**: `(kind ; value ; meta)`.

## Verification rules

- After editing any `src/*.ijs`, run `make test`.
- After adding a new verb, add at least one assertion in the corresponding
  `tests/test_<module>.ijs`.
- Never commit secrets or absolute paths from the developer's machine into
   tests or examples.
- Don't add a self-host check that requires the parser to handle J-specific
  syntax (3 : 0, =:, etc.) — the Stage 0 parser is a strict subset of J.
  See `bootstrap/stage3_attempt.ijs` for the realistic baseline.

## What *not* to do

- Don't add dependencies. J 9.7 stdlib only.
- Don't change the token / AST node shape without updating all consumers and
  the spec.
- Don't introduce ad-hoc parser hacks; defer to the gerund-dispatch table in
  `parse.ijs`.
- Don't commit until the user asks.

## Commit message style

`<scope>: <imperative summary>`

Examples: `lex: handle doubled-quote escape`, `parser: add fork dispatch`,
`tests: cover negative numbers`.