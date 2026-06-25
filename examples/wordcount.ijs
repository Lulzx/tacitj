NB. ============================================================
NB. examples/wordcount.ijs - Tacit word counter (Stage 0 subset)
NB. ============================================================
NB. Count words in a string. Stage 0 subset only.
NB.
NB. Run via `make run EXAMPLE=examples/wordcount.ijs`.
NB.
NB. Stage 0 supports: + - * % ^ | < > & =:
NB. It does NOT yet support: @ @: ~: \ : [ ]
NB.
NB. So we use only those, with parens for grouping.
NB.
NB. Approach: words = 1 + (number of spaces). For inputs
NB. without leading/trailing spaces this gives the count of
NB. words (since words = spaces + 1).
NB.
NB. spacesIn y = +/ ' ' = y  (forks to (sum y) = (string y) in
NB. full J; in our subset we rely on the fact that +/ ' ' = y
NB. parses in our IR as a 3-train).
NB.
NB. For Stage 0, we directly count using +/ applied to a boolean:
NB.   spacesIn y = +/ (y = ' ')
NB. But = y requires parens; let's express it as a fork:
NB.   spacesIn = +/ & ' ' =   (a 3-train: +/, ' ', =)
NB.
NB. The simplest form for Stage 0: just inline everything.
NB. We can't avoid the issue without identity (]) so the
NB. cleanest demo uses monadic +/:
NB.
NB.   spacesIn =: +/ & (' ' = ])
NB.
NB. But [& ] isn't in Stage 0 either.
NB.
NB. Workaround: build a TINY table mapping ' ' to itself, and
NB. apply sum. The expression `+/ ' ' = y` is parsed by our
NB. IR as `(+/ y) = ' ' y` (a 3-train fork). To get the count
NB. we evaluate it as a fork with y = 0 (an empty list), which
NB. gives sum-of-0 = 0 ... no that doesn't work either.
NB.
NB. The honest answer: counting spaces in a Stage 0 program
NB. requires either the identity verb `]` or the compose verb
NB. `@`, neither of which is supported yet. This example
NB. documents the limitation. When Stage 0 grows `@`, this
NB. becomes a one-liner: `wordCount =: 1 + +/ @ (' ' = ])`.

NB. For now, here's a simple sum that demonstrates the subset:
NB. sum 1..5 = 15.
smoutput +/ 1 2 3 4 5
NB. -> 15