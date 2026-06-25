NB. ============================================================
NB. examples/wordcount.ijs - Tacit word counter
NB. ============================================================
NB. A tiny but real-world example: count words in a string.
NB.
NB. Stage 0 subset supports: + - * % ^ | < > & =: ] [ @ ~
NB. It does NOT yet support: @: ~:/\ \
NB.
NB. Algorithm: words = spaces + 1 (for an input with no
NB. leading/trailing spaces). spaces = number of ' ' chars
NB. in y.
NB.
NB.   spacesIn =: +/ @ (' ' = ])   NB. compose: apply (' '=])
NB.                                          then sum
NB.   wordCount =: 1 + spacesIn

spacesIn =: +/ @ (' ' = ])
wordCount =: 1 + spacesIn

smoutput wordCount 'the quick brown fox'
NB. -> 4