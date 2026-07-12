#!/usr/bin/env bash

set -e

export LC_ALL=C

# Mock the environment needed for lib/filebrowser.sh
export BC_DIR="$(pwd)"
source lib/filebrowser.sh

TEST_DIR=$(mktemp -d)

# Setup dummy files
touch "$TEST_DIR/foo.sh"
touch "$TEST_DIR/bar.sh"
touch "$TEST_DIR/FooBar.sh"
touch "$TEST_DIR/baz.txt" # Should be ignored since it's not .sh
mkdir "$TEST_DIR/subdir"
touch "$TEST_DIR/subdir/nested.sh" # Should be ignored due to -maxdepth 1

fails=0

assert_output() {
  local name="$1"
  local expected="$2"
  local actual="$3"

  if [[ "$expected" == "$actual" ]]; then
    echo "PASS: $name"
  else
    echo "FAIL: $name"
    echo "  Expected:"
    echo "$expected" | sed 's/^/    /'
    echo "  Actual:"
    echo "$actual" | sed 's/^/    /'
    fails=$((fails + 1))
  fi
}

echo "Running tests for bc_filebrowser_filter_files..."

# Test 1: Empty filter (should return all .sh files sorted)
expected=$(printf "%s\n%s\n%s" "$TEST_DIR/FooBar.sh" "$TEST_DIR/bar.sh" "$TEST_DIR/foo.sh")
actual=$(bc_filebrowser_filter_files "$TEST_DIR" "")
assert_output "Empty filter" "$expected" "$actual"

# Test 2: Case insensitive filter ('foo')
expected=$(printf "%s\n%s" "$TEST_DIR/FooBar.sh" "$TEST_DIR/foo.sh")
actual=$(bc_filebrowser_filter_files "$TEST_DIR" "foo")
assert_output "Filter 'foo' (case insensitive)" "$expected" "$actual"

# Test 3: Filter 'bar'
expected=$(printf "%s\n%s" "$TEST_DIR/FooBar.sh" "$TEST_DIR/bar.sh")
actual=$(bc_filebrowser_filter_files "$TEST_DIR" "bar")
assert_output "Filter 'bar'" "$expected" "$actual"

# Test 4: Exact match ('foobar')
expected=$(printf "%s" "$TEST_DIR/FooBar.sh")
actual=$(bc_filebrowser_filter_files "$TEST_DIR" "foobar")
assert_output "Exact match 'foobar'" "$expected" "$actual"

# Test 5: No match ('missing')
expected=""
actual=$(bc_filebrowser_filter_files "$TEST_DIR" "missing")
assert_output "No match 'missing'" "$expected" "$actual"

# Cleanup
rm -rf "$TEST_DIR"

if (( fails > 0 )); then
  echo "Tests failed: $fails"
  exit 1
else
  echo "All tests passed!"
  exit 0
fi
