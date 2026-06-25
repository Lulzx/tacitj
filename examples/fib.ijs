NB. ============================================================
NB. examples/fib.ijs - Fibonacci in tacit J
NB. ============================================================
NB. A closed-form Fibonacci using matrix powers in J.
NB.
NB. fib n = ((2 %: 5) ^ n) - ((1 - 2 %: 5) ^ n)) % 5 %: 5  (Binet)
NB. For small n, this is fine; for large n, you'd use a
NB. tail-recursive J defn instead. The point is the
NB. composition: every operator is tacit.

NB. Binet's formula via fork: (a^n - b^n) / sqrt(5)
NB. where a = (1+sqrt(5))/2 and b = (1-sqrt(5))/2.
NB. 2 %: 5 = sqrt(5), 1 + 2 %: 5 = phi, 1 - 2 %: 5 = psi.

NB. 2 %: 5     -> sqrt(5)            (primitive)
NB. (1 + 2 %: 5) % 2     -> phi      (fork on +, /, scalar)
NB. (1 - 2 %: 5) % 2     -> psi

NB. nb: TacitJ subset doesn't have matrix powers yet, so this
NB. example shows the *style* (tacit composition) more than
NB. a useful computation. Run via `make run EXAMPLE=examples/fib.ijs`.
NB.
NB. Compute a small example by hand:
NB.   fib 5  (should be 5)
NB. We can't actually call this from the Stage 0 REPL because
NB. the parser doesn't yet handle multi-line programs where
NB. the second line is a separate sentence (LF is whitespace
NB. in J). So this file is for *reading*; the real showcase
NB. is the *style*.

NB. A simpler end-to-end demo: the value of (1 + sqrt(5)) / 2.
NB. Stage 0 should evaluate this to ~1.618.
phi =: (1 + 2 %: 5) % 2
phi
