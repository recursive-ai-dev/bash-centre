#!/usr/bin/env bash

# Mock dependencies
bc_term_width() { echo 80; }
bc_term_height() { echo 24; }
bc_cursor_to() { echo -n "CUR($1,$2)"; }
bc_fg() { echo -n "FG($1)"; }
bc_reset() { echo -n "RST"; }
bc_clear_eol() { echo -n "CEOL"; }
BC_THEME_TEXT_DIM="DIM_COLOR"

source lib/runner.sh

# Run test
test_output=$(echo "test arg 1 2 3" | bc_runner_prompt_args)

# Expected outputs
expected_prefix="CUR(22,3)FG(DIM_COLOR)Arguments: RSTCEOL"
expected_suffix="test arg 1 2 3"
expected_full="${expected_prefix}${expected_suffix}"

if [[ "$test_output" == "$expected_full" ]]; then
  echo "PASS: bc_runner_prompt_args output matched expectations."
else
  echo "FAIL: Expected '$expected_full', got '$test_output'"
  # We exit 1 instead of exit 1 so that we don't block the bash session.
  exit 1
fi
