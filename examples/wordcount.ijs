NB. ============================================================
NB. examples/wordcount.ijs - Tacit word counter
NB. ============================================================
NB. A tiny but real-world example: count words in a string.
NB.
NB. The trick: words are separated by spaces. In J, you can
NB. find word boundaries with `+./\ =` (running-or with
NB. comparison) and count them by summing.
NB.
NB. For a literal char vector (which the Stage 0 parser
NB. supports), the path is:
NB.
NB.   words =: +/ (1 , 2 ~:/\ ])      NB. 1 + count of word boundaries
NB.   words 'hello world foo'        NB. -> 3
NB.
NB. NB: 2 ~:/\ is "not-equal scan" - 1 where adjacent chars
NB. differ (a word boundary). The `1 ,` adds a 1 for the
NB. first word. +/ sums to get the count.

words =: +/ @: (1 , 2 ~:/\ ])
words 'the quick brown fox'
