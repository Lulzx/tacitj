# TacitJ language reference

A small reference for the language subset, with examples you can
copy into a `.ijs` file and run with `make run EXAMPLE=...`.

#### Verbs

| verb  | name           | example            | result      |
|-------|----------------|--------------------|-------------|
| `+`   | plus           | `2 + 3`            | `5`         |
| `-`   | minus          | `10 - 4`           | `6`         |
| `*`   | times          | `3 * 4`            | `12`        |
| `%`   | divide         | `10 % 3`           | `3.33333`   |
| `^`   | power          | `2 ^ 10`           | `1024`      |
| `=`   | equal          | `3 = 3`            | `1`         |
| `<`   | less than      | `2 < 3`            | `1`         |
| `>`   | greater than   | `3 > 2`            | `1`         |
| `<.`  | floor          | `<. 3.7`           | `3`         |
| `>.`  | ceiling        | `>. 3.2`           | `4`         |
| `+:`  | double         | `+: 5`             | `10`        |
| `-:`  | halve          | `-: 10`            | `5`         |
| `*:`  | square         | `*: 4`             | `16`        |
| `%:`  | square root    | `%: 16`            | `4`         |
| `\|:` | transpose      | `|: 2 3 $ 1 2 3 4 5 6` | `1 4 / 2 5 / 3 6` |
| `~:`  | not-equal      | `3 ~: 4`           | `1`         |
| `\|`  | modulo / resid | `10 \| 3`          | `1`         |
| `!`   | factorial      | `! 5`              | `120`       |
| `?`   | roll / deal    | `? 6`              | random int  |
| `$`   | reshape        | `2 3 $ 1 2 3 4 5 6` | `1 2 3 / 4 5 6` |
| `,`   | concatenate    | `1 2 , 3 4`        | `1 2 3 4`   |
| `;`   | ravel boxes    | `(1 2) ; (3 4)`    | `1 2 3 4`   |
| `#`   | count / tally  | `# 1 2 3`          | `3`         |
| `[`   | left identity  | `5 [` (identity)   | `5`         |
| `]`   | right identity | `5 ]` (identity)   | `5`         |

#### Adverbs

| adverb | name     | example            | result         |
|--------|----------|--------------------|----------------|
| `/`    | insert   | `+/ 1 2 3 4`       | `10`           |
| `\`    | prefix   | `+\ 1 2 3 4`       | `1 3 6 10`     |
| `~.`   | nub      | `~. 1 2 2 3 1`     | `1 2 3`        |
| `~:`   | nub-sieve| `~: 1 2 2 3 1`     | `1 1 0 1 0`    |
| `/:`   | grade up | `/: 3 1 4 1 5`     | `1 3 0 2 4`    |
| `\:`   | grade dn | `\: 3 1 4 1 5`     | `4 2 0 3 1`    |
| `/:~`  | sort up  | `/:~ 3 1 4 1 5`    | `1 1 3 4 5`    |
| `\:~`  | sort dn  | `\:~ 3 1 4 1 5`    | `5 4 3 1 1`    |

#### Conjunctions

| conj  | name           | example            | notes                  |
|-------|----------------|--------------------|------------------------|
| `@`   | atop           | `*: @: ]`          | squaring its argument  |
| `@:`  | atop w/ rank   | `+: @: *:`         | composition with rank  |
| `&`   | bond           | `5 & \|`           | `residue mod 5`        |
| `&:`  | bond w/ rank   | `5 & \|`           | bond with rank         |
| `^:`  | power w/ rank  | `*: ^: 2`          | apply twice            |

#### Forks and hooks

Three verbs in a row form a **fork** `(f g h) x = (f x) g (h x)`:

```j
NB. Mean: sum-of-y / count-of-y
mean =. +/ % #
mean 1 2 3 4 5
NB. -> 3
```

Two verbs in a row form a **hook** `(g h) x = x g (h x)`:

```j
NB. The composition `(f g h) x = x g (h x)` is a hook.
NB. TacitJ lexer requires explicit parens: `(g h)`.
NB. See examples/stats.ijs for the "hook caveat" workaround.
```

#### Reading list

- [`hello.ijs`](../examples/hello.ijs) — minimal smoke program
- [`mean.ijs`](../examples/mean.ijs) — mean as a fork
- [`rank.ijs`](../examples/rank.ijs) — 2-char conjunctions
- [`matrix.ijs`](../examples/matrix.ijs) — 2D arrays, transpose
- [`stats.ijs`](../examples/stats.ijs) — variance / stddev
- [`poly.ijs`](../examples/poly.ijs) — polynomial evaluation
- [`sort.ijs`](../examples/sort.ijs) — sorting and dedup
- [`fib.ijs`](../examples/fib.ijs) — golden ratio via Binet

---

