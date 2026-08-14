# Examples

All examples live in [`examples/`](../examples/) and are valid J-Tacit-Core (runnable with `make run EXAMPLE=…`).

### [`hello.ijs`](../examples/hello.ijs) — minimal smoke program

```j
NB. A bare expression sentence; the evaluator prints the value
NB. back as the result.

'hello, world'
```

### [`mean.ijs`](../examples/mean.ijs) — the canonical 3-train

```j
NB. `+/ % #` is a fork: computes the arithmetic mean of a list.

mean =: +/ % #

mean 1 2 3 4 5        NB. -> 3
mean 10 20 30         NB. -> 20
```

### [`train.ijs`](../examples/train.ijs) — hooks, forks, and bindings

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

### [`squares.ijs`](../examples/squares.ijs) — sum of squares in one line

```j
sumSquares =: +/ @: *:
sumSquares 1 2 3 4 5        NB. -> 55
```

### [`wordcount.ijs`](../examples/wordcount.ijs) — tacit word counter

```j
words =: +/ @: (1 , 2 ~:/\ ])
words 'the quick brown fox'  NB. -> 4
```

### [`fib.ijs`](../examples/fib.ijs) — golden ratio via Binet-style expression

```j
phi =: (1 + 2 %: 5) % 2
phi                          NB. -> 1.61803...
```

### [`pipeline.ijs`](../examples/pipeline.ijs) — tacit composition with `@`

```j
NB. Function composition: (f @ g) y = f (g y)
square =: *:         NB. monadic *  is square
incr   =: >:         NB. monadic >: is increment
pipeline =: square @ incr

pipeline 3           NB. -> 16
pipeline 10          NB. -> 121
```

---

