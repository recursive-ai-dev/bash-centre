#!/usr/bin/env bash

set -e

# Mock commands for testing
uname() {
  case "$1" in
    -r) echo "mock-kernel-version" ;;
    -n) echo "mock-host" ;;
    -s) echo "mock-os" ;;
    -m) echo "mock-arch" ;;
  esac
}

find() {
  echo "file1.sh"
  echo "file2.sh"
  echo "file3.sh"
}

read() {
  return 0
}

# We need a predictable shell
export SHELL="/bin/mock-shell"
export TERM="xterm-mock"
export BC_DIR="."

# Load code
source ./lib/core.sh
source ./lib/dashboard.sh

echo "Running test_dashboard.sh..."

test_with_uptime() {
  command() {
    if [[ "$1" == "-v" && "$2" == "uptime" ]]; then
      return 0
    fi
    builtin command "$@"
  }
  uptime() {
    echo "up 2 hours, 5 minutes"
  }

  local output
  output=$(bc_dashboard_system_info)

  echo "$output" | grep -q "mock-kernel-version" || { echo "Failed: Kernel version"; return 1; }
  echo "$output" | grep -q "mock-host" || { echo "Failed: Host"; return 1; }
  echo "$output" | grep -q "mock-os" || { echo "Failed: OS"; return 1; }
  echo "$output" | grep -q "mock-arch" || { echo "Failed: Arch"; return 1; }
  echo "$output" | grep -q "2 hours, 5 minutes" || { echo "Failed: uptime (with command)"; return 1; }
  echo "$output" | grep -q "mock-shell" || { echo "Failed: Shell"; return 1; }
  echo "$output" | grep -q "xterm-mock" || { echo "Failed: Term"; return 1; }
  echo "$output" | grep -q "3 available" || { echo "Failed: Scripts count"; return 1; }

  echo "test_with_uptime passed"
}

test_without_uptime() {
  command() {
    if [[ "$1" == "-v" && "$2" == "uptime" ]]; then
      return 1
    fi
    builtin command "$@"
  }

  awk() {
    # 86400 * 1 + 3600 * 2 + 60 * 3 = 86400 + 7200 + 180 = 93780
    echo "93780"
  }

  local output
  output=$(bc_dashboard_system_info)

  echo "$output" | grep -q "1d 2h 3m" || { echo "Failed: uptime (fallback)"; return 1; }

  echo "test_without_uptime passed"
}

# Run tests
test_with_uptime
test_without_uptime

echo "All tests passed!"
