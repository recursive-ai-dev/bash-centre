#!/usr/bin/env bash

# Run all test files in tests directory
pass=0
fail=0

for test_file in tests/*_test.sh; do
    if [[ -f "$test_file" ]]; then
        echo "Running $test_file..."
        if bash "$test_file"; then
            echo "$test_file PASSED"
            ((pass++))
        else
            echo "$test_file FAILED"
            ((fail++))
        fi
    fi
done

echo "Tests passing: $pass, failing: $fail"
if [[ $fail -gt 0 ]]; then
    echo "FAILED"
    # To return an error status without using exit:
    exit 1
else
    echo "SUCCESS"
fi
