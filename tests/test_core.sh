#!/usr/bin/env bash

# Exit script if any command fails
set -e

# Setup test environment
export BC_CACHE_DIR=$(mktemp -d)
export BC_RECENT_FILE="$BC_CACHE_DIR/recent"

# Source the file to test
source lib/core.sh

# Mock the max recent configuration for testing purposes
export BC_MAX_RECENT=3

# Helper for assertions
assert_equal() {
  local expected="$1"
  local actual="$2"
  local msg="$3"
  if [[ "$expected" != "$actual" ]]; then
    echo "FAIL: $msg"
    echo "  Expected: '$expected'"
    echo "  Actual:   '$actual'"
    return 1
  fi
}

echo "Running tests for bc_recent_add..."

FAIL=0

# Test 1: File creation and single addition
bc_recent_add "file1.txt"
if ! assert_equal "file1.txt" "$(cat "$BC_RECENT_FILE")" "Single addition failed"; then FAIL=1; fi

# Test 2: Ordering of multiple additions
bc_recent_add "file2.txt"
expected=$(printf "file2.txt\nfile1.txt")
if ! assert_equal "$expected" "$(cat "$BC_RECENT_FILE")" "Multiple additions failed"; then FAIL=1; fi

# Test 3: Deduplication (moving an existing entry to the top)
bc_recent_add "file1.txt"
expected=$(printf "file1.txt\nfile2.txt")
if ! assert_equal "$expected" "$(cat "$BC_RECENT_FILE")" "Deduplication failed"; then FAIL=1; fi

# Test 4: Truncation (respecting BC_MAX_RECENT)
bc_recent_add "file3.txt"
bc_recent_add "file4.txt"
expected=$(printf "file4.txt\nfile3.txt\nfile1.txt")
if ! assert_equal "$expected" "$(cat "$BC_RECENT_FILE")" "Truncation failed"; then FAIL=1; fi

# Cleanup
rm -rf "$BC_CACHE_DIR"

if [[ $FAIL -eq 1 ]]; then
    echo "Tests failed!"
    exit 1
fi

echo "All tests passed!"
