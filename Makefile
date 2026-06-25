# TacitJ — Makefile

# J interpreter (JSoftware's jconsole, NOT the JDK's /usr/bin/jconsole
# which is the Java JMX console and would hang). Prefer the Homebrew
# cask install if present; fall back to whatever `jconsole` is on
# $PATH. Override with `make JC=/full/path/to/jconsole`.
JCBIN := $(shell ls /opt/homebrew/Caskroom/j/*/j*/bin/jconsole 2>/dev/null | head -1)
JCBIN := $(or $(JCBIN),$(shell ls /usr/local/Caskroom/j/*/j*/bin/jconsole 2>/dev/null | head -1))
JC ?= $(or $(JCBIN),jconsole)
JFLAGS ?=

SRC_DIR    := src
TEST_DIR   := tests
EXAMPLE_DIR:= examples

SRCS  := $(wildcard $(SRC_DIR)/*.ijs)
TESTS := $(wildcard $(TEST_DIR)/*.ijs)

.PHONY: all test smoke run clean install-j help stage0 stage1 stage2 stage3 stage3-attempt bootstrap selfhost bench mdl-demo

all: test

help:
	@echo "Targets:"
	@echo "  make install-j    - install J 9.7 via Homebrew (macOS)"
	@echo "  make test         - run the full test suite"
	@echo "  make smoke        - smoke test with examples/hello.ijs"
	@echo "  make run EXAMPLE=path/to/file.ijs - run a TacitJ program"
	@echo "  make repl         - start an interactive REPL"
	@echo "  make stage0       - load Stage 0 + run selfhost check"
	@echo "  make stage1 INFILE=... OUTFILE=...  - compile a TacitJ file"
	@echo "  make stage3-attempt - run the stage-3 self-host baseline"
	@echo "  make bootstrap    - run all bootstrap stages"
	@echo "  make selfhost     - smoke-test self-compilation"
	@echo "  make bench        - run compile/exec benchmark suite"
	@echo "  make mdl-demo     - run the MDL / grammar-induction demo"
	@echo "  make clean        - remove build artifacts"

install-j:
	@command -v $(JC) >/dev/null 2>&1 || brew install --cask j

test: install-j
	@command -v $(JC) >/dev/null 2>&1 || { \
		echo "error: $(JC) not found. Run 'make install-j' or set JC."; exit 1; }
	$(JC) $(JFLAGS) $(TEST_DIR)/runtests.ijs

smoke: install-j
	$(JC) $(JFLAGS) $(SRC_DIR)/tacitj.ijs $(EXAMPLE_DIR)/hello.ijs

run: install-j
	@test -n "$(EXAMPLE)" || { echo "usage: make run EXAMPLE=path.ijs"; exit 1; }
	$(JC) $(JFLAGS) $(SRC_DIR)/tacitj.ijs $(EXAMPLE)

repl: install-j
	$(JC) $(JFLAGS) $(SRC_DIR)/tacitj.ijs

stage0: install-j
	$(JC) $(JFLAGS) bootstrap/stage0_run.ijs

stage1: install-j
	@test -n "$(INFILE)" || { echo "usage: make stage1 INFILE=path.ijs OUTFILE=path.ijs"; exit 1; }
	@test -n "$(OUTFILE)" || { echo "usage: make stage1 INFILE=path.ijs OUTFILE=path.ijs"; exit 1; }
	$(JC) $(JFLAGS) bootstrap/stage1.ijs INFILE=$(INFILE) OUTFILE=$(OUTFILE)

stage3-attempt: install-j
	$(JC) $(JFLAGS) bootstrap/stage3_attempt.ijs

bootstrap: stage0
	@mkdir -p bin
	$(JC) $(JFLAGS) bootstrap/stage1.ijs INFILE=examples/hello.ijs OUTFILE=bin/stage1_hello.ijs
	@echo "stage1: produced bin/stage1_hello.ijs"
	@$(JC) $(JFLAGS) bin/stage1_hello.ijs > /dev/null && echo "stage1: round-trip OK"

selfhost: install-j
	@echo "selfhost: stage 0 must match stage 0 canary fingerprint"
	$(JC) $(JFLAGS) bootstrap/stage0_run.ijs
	@echo "selfhost: stage 1 round-trip on examples/hello.ijs"
	@mkdir -p bin
	$(JC) $(JFLAGS) bootstrap/stage1.ijs INFILE=examples/hello.ijs OUTFILE=bin/stage1_hello.ijs > /dev/null
	@echo "selfhost: stage 1 output file:"
	@cat bin/stage1_hello.ijs
	@echo "selfhost: OK"

bench: install-j
	$(JC) $(JFLAGS) bench/bench.ijs

mdl-demo: install-j
	$(JC) $(JFLAGS) bench/mdl_demo.ijs

clean:
	rm -f *.ijx *.ijb
	rm -rf bin obj reports
