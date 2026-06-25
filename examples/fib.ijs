NB. ============================================================
NB. examples/fib.ijs - Fibonacci in tacit J
NB. ============================================================
NB. A closed-form Fibonacci using matrix powers in J.
NB.
NB. fib n = ((2 %: 5) ^ n) - ((1 - 2 %: 5) ^ n)) % 5 %: 5  (Binet)
NB. For small n, this is fine; for large n, you'd use a
NB. tail-recursive J defn instead. The point is the
NB. composition: every operator is tacit.
NB.
NB. Binet's formula via fork: (a^n - b^n) / sqrt(5)
NB. where a = (1+sqrt(5))/2 and b = (1-sqrt(5))/2.
NB. 2 %: 5 = sqrt(5), 1 + 2 %: 5 = phi, 1 - 2 %: 5 = psi.

NB. Stage 0 subset: + - * % ^ | < > & =:
NB. It does NOT yet support: @ @: ~: \ :
NB. So we use %: (square root), ^ (power), and parens.

NB. Compute the golden ratio (1 + sqrt(5)) / 2 = 1.61803...
phi =: (1 + 2 %: 5) % 2
smoutput phi
NB. -> 1.61803...

NB. Smaller identity: phi + psi = 1, phi * psi = -1
psi =: (1 - 2 %: 5) % 2
smoutput phi + psi
NB. -> 1