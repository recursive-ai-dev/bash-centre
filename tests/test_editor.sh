#!/usr/bin/env bash

# Create a test file
source lib/editor.sh

# Simple assert function
assert_equal() {
  if [[ "$1" != "$2" ]]; then
    echo "ASSERT FAILED: expected '$1', got '$2'"
    exit 1
  fi
}

echo "Testing bc_editor_new"

# Test 1: Session loads
bc_editor_load_session() {
  return 0
}

bc_editor_interface() {
  echo "Interface called (should not happen in Test 1)"
  exit 1
}

# Reset state
BC_EDITOR_LINES=()
BC_EDITOR_CURSOR_LINE=-1

bc_editor_new

assert_equal "0" "${#BC_EDITOR_LINES[@]}"
assert_equal "-1" "$BC_EDITOR_CURSOR_LINE"
echo "Test 1 passed"

# Test 2: Session doesn't load, initialized correctly
bc_editor_load_session() {
  return 1
}

INTERFACE_CALLED=0
bc_editor_interface() {
  INTERFACE_CALLED=1
}

bc_editor_new

assert_equal "5" "${#BC_EDITOR_LINES[@]}"
assert_equal "#!/usr/bin/env bash" "${BC_EDITOR_LINES[0]}"
assert_equal "0" "$BC_EDITOR_CURSOR_LINE"
assert_equal "0" "$BC_EDITOR_CURSOR_COL"
assert_equal "0" "$BC_EDITOR_SCROLL"
assert_equal "1" "$BC_EDITOR_MODIFIED"
assert_equal "untitled.sh" "$BC_EDITOR_FILENAME"
assert_equal "0" "${#BC_EDITOR_UNDO_STACK[@]}"
assert_equal "0" "${#BC_EDITOR_REDO_STACK[@]}"
assert_equal "" "$BC_EDITOR_LAST_ACTION"
assert_equal "1" "$INTERFACE_CALLED"

echo "Test 2 passed"
echo "All tests passed!"
