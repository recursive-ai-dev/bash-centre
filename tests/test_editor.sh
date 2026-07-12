#!/usr/bin/env bash

# Mock functions if needed, and set up the environment
export BC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BC_DIR/lib/core.sh"
source "$BC_DIR/lib/editor.sh"

# Test variables
TEST_FAILED=0

# Mock bc_notify to capture its output instead of drawing to the terminal
bc_notify_output=""
bc_notify() {
    bc_notify_output="$1"
}

echo "Running test: bc_editor_open with a non-existent file..."

# Run the function
bc_editor_open "this_file_does_not_exist.sh" 2>/dev/null
exit_code=$?

if [[ $exit_code -ne 1 ]]; then
    echo "FAIL: Expected exit code 1, but got $exit_code"
    TEST_FAILED=1
else
    echo "PASS: Returned exit code 1 as expected."
fi

if [[ "$bc_notify_output" != "File not found: this_file_does_not_exist.sh" ]]; then
    echo "FAIL: Expected notification 'File not found: this_file_does_not_exist.sh', but got '$bc_notify_output'"
    TEST_FAILED=1
else
    echo "PASS: Correct notification sent."
fi

if [[ $TEST_FAILED -eq 1 ]]; then
    exit 1
else
    echo "All editor tests passed."
fi
exit 0
