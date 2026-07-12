#!/usr/bin/env bash

# Set up test environment
BC_DIR=$(pwd); export BC_DIR

# Stub out UI functions that interact with the terminal or wait for input
bc_notify() { echo "NOTIFY: $1 ($2)"; }
bc_term_width() { echo 80; }
bc_term_height() { echo 24; }
bc_cursor_to() { :; }
bc_fg() { :; }
bc_reset() { :; }
bc_dim() { :; }

# Source the target file
source "${BC_DIR}/lib/runner.sh"

failed=0

test_syntax_check_valid_script() {
  local valid_script; valid_script=$(mktemp)
  echo "echo 'Hello'" > "$valid_script"

  if bc_runner_check_syntax "$valid_script" < /dev/null; then
    echo "PASS: valid script"
  else
    echo "FAIL: valid script"
    failed=1
  fi
  rm -f "$valid_script"
}

test_syntax_check_invalid_script() {
  local invalid_script; invalid_script=$(mktemp)
  echo "if [ true ]; then" > "$invalid_script"
  echo "  echo 'missing fi'" >> "$invalid_script"

  if ! bc_runner_check_syntax "$invalid_script" < /dev/null; then
    echo "PASS: invalid script"
  else
    echo "FAIL: invalid script"
    failed=1
  fi
  rm -f "$invalid_script"
}

echo "Running bc_runner_check_syntax tests..."
test_syntax_check_valid_script
test_syntax_check_invalid_script

if [ $failed -ne 0 ]; then
  echo "Tests failed!"
else
  echo "All tests passed!"
fi
exit $failed
