#!/usr/bin/env bash

# Source the core library
source lib/core.sh

# Simple assertion framework
fails=0

assert_output() {
  local expected="$1"
  local actual="$2"
  local message="$3"

  if [[ "$expected" == "$actual" ]]; then
    echo "✅ PASS: $message"
  else
    echo "❌ FAIL: $message"
    echo "   Expected: '$expected'"
    echo "   Actual:   '$actual'"
    fails=$((fails + 1))
  fi
}

echo "Testing bc_recent_list..."

# Setup: Use a temporary file for testing
export BC_RECENT_FILE=$(mktemp)

# Test 1: File doesn't exist
rm -f "$BC_RECENT_FILE"
output=$(bc_recent_list)
assert_output "" "$output" "Handles missing file correctly"

# Test 2: File exists but is empty
touch "$BC_RECENT_FILE"
output=$(bc_recent_list)
assert_output "" "$output" "Handles empty file correctly"

# Test 3: File exists and contains items
echo "item1.sh" > "$BC_RECENT_FILE"
echo "item2.sh" >> "$BC_RECENT_FILE"
expected_output=$(printf "item1.sh\nitem2.sh")
output=$(bc_recent_list)
assert_output "$expected_output" "$output" "Returns file contents correctly"

# Cleanup
rm -f "$BC_RECENT_FILE"

# Finish
if [[ $fails -gt 0 ]]; then
  echo "Tests failed ($fails)"
else
  echo "All tests passed!"
fi
[[ $fails -eq 0 ]]
