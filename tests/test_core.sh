#!/usr/bin/env bash

# We need to source lib/core.sh FIRST, then override the functions
source lib/core.sh

# Mock out dependencies
export BC_THEME_BG=235
bc_cursor_to() { echo -ne "C($1,$2)"; }
bc_bg() { echo -ne "B($1)"; }
bc_reset() { echo -ne "R"; }

FAILURES=0

test_bc_fill_rect() {
  local output
  local expected

  # The signature in core.sh is:
  # bc_fill_rect() {
  #   local r=$1 c=$2 h=$3 w=$4 char="${5:- }" bg="${6:-}"

  # Test default character and no bg
  output=$(bc_fill_rect 10 5 2 3)
  expected="C(10,5)   RC(11,5)   R"
  if [[ "$output" == "$expected" ]]; then
    echo "PASS: bc_fill_rect (default char, no bg)"
  else
    echo "FAIL: bc_fill_rect (default char, no bg)"
    echo "  Expected: $expected"
    echo "  Got:      $output"
    FAILURES=$((FAILURES + 1))
  fi

  # Test custom character and custom bg
  output=$(bc_fill_rect 2 3 3 4 "X" 42)
  expected="C(2,3)B(42)XXXXRC(3,3)B(42)XXXXRC(4,3)B(42)XXXXR"
  if [[ "$output" == "$expected" ]]; then
    echo "PASS: bc_fill_rect (custom char, custom bg)"
  else
    echo "FAIL: bc_fill_rect (custom char, custom bg)"
    echo "  Expected: $expected"
    echo "  Got:      $output"
    FAILURES=$((FAILURES + 1))
  fi

  # Test zero height
  output=$(bc_fill_rect 1 1 0 5 "X" 42)
  expected=""
  if [[ "$output" == "$expected" ]]; then
    echo "PASS: bc_fill_rect (zero height)"
  else
    echo "FAIL: bc_fill_rect (zero height)"
    echo "  Expected: '$expected'"
    echo "  Got:      '$output'"
    FAILURES=$((FAILURES + 1))
  fi

  # Test zero width
  output=$(bc_fill_rect 1 1 1 0 "X" 42)
  expected="C(1,1)B(42)R"
  if [[ "$output" == "$expected" ]]; then
    echo "PASS: bc_fill_rect (zero width)"
  else
    echo "FAIL: bc_fill_rect (zero width)"
    echo "  Expected: $expected"
    echo "  Got:      $output"
    FAILURES=$((FAILURES + 1))
  fi
}

echo "Running tests for core.sh..."
test_bc_fill_rect

if [ $FAILURES -eq 0 ]; then
  echo "All tests passed!"
else
  echo "$FAILURES test(s) failed."
  # Non-zero exit with subshell to avoid breaking bash session directly
  (exit 1) || return 1 2>/dev/null
fi
