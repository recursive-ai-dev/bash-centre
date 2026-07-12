#!/usr/bin/env bats

setup() {
  source lib/core.sh
}

@test "bc_progress_bar renders 50% correctly" {
  run bash -c "source lib/core.sh && bc_progress_bar 50 10 | sed 's/\x1b\[[0-9;]*m//g'"
  [ "$status" -eq 0 ]
  [ "$output" = "█████░░░░░" ]
}

@test "bc_progress_bar renders 0% correctly" {
  run bash -c "source lib/core.sh && bc_progress_bar 0 10 | sed 's/\x1b\[[0-9;]*m//g'"
  [ "$status" -eq 0 ]
  [ "$output" = "░░░░░░░░░░" ]
}

@test "bc_progress_bar renders 100% correctly" {
  run bash -c "source lib/core.sh && bc_progress_bar 100 10 | sed 's/\x1b\[[0-9;]*m//g'"
  [ "$status" -eq 0 ]
  [ "$output" = "██████████" ]
}

@test "bc_progress_bar handles default width" {
  run bash -c "source lib/core.sh && bc_progress_bar 25 | sed 's/\x1b\[[0-9;]*m//g'"
  [ "$status" -eq 0 ]
  # default width is 40. 25% of 40 is 10
  expected=$(printf "%0.s█" {1..10})$(printf "%0.s░" {1..30})
  [ "$output" = "$expected" ]
}

@test "bc_progress_bar uses correct color" {
  run bash -c "source lib/core.sh && bc_progress_bar 50 10 42"
  [ "$status" -eq 0 ]
  # ANSI escape for fg 42 is \e[38;5;42m
  # ANSI escape for dim is \e[2m
  # ANSI escape for reset is \e[0m
  expected="\e[38;5;42m█████\e[2m░░░░░\e[0m"
  real_expected=$(echo -ne "$expected")
  [ "$output" = "$real_expected" ]
}
