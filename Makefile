# TacitJ — Makefile

# Use Homebrew J if jconsole isn't on PATH; override with `make JC=...`.
JC ?= jconsole
JFLAGS ?=

SRC_DIR    := src
TEST_DIR   := tests
EXAMPLE_DIR:= examples

SRCS  := $(wildcard $(SRC_DIR)/*.ijs)
TESTS := $(wildcard $(TEST_DIR)/*.ijs)

.PHONY: all test smoke run clean install-j help

all: test

help:
	@echo "Targets:"
	@echo "  make install-j    - install J 9.7 via Homebrew (macOS)"
	@echo "  make test         - run the full test suite"
	@echo "  make smoke        - smoke test with examples/hello.ijs"
	@echo "  make run EXAMPLE=path/to/file.ijs - run a TacitJ program"
	@echo "  make repl         - start an interactive REPL"
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

clean:
	rm -f *.ijx *.ijb
	rm -rf bin obj reports
