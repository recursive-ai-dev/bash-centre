#!/usr/bin/env bash

[[ -n ${__BC_RUNNER:-} ]] && return; __BC_RUNNER=1

# ── Script Runner ─────────────────────────────────────────────────────
BC_RUNNER_PID=""
BC_RUNNER_LOG=""
BC_RUNNING=0

bc_runner_check_syntax() {
  local script_path="$1"
  local errors
  errors=$(bash -n "$script_path" 2>&1)
  if [[ $? -ne 0 ]]; then
    bc_notify "Syntax error in script" "error"
    local w=$(bc_term_width)
    local h=$(bc_term_height)
    local y=$((h/2))
    local x=4
    bc_cursor_to "$y" "$x"
    echo -ne "$(bc_fg "$BC_THEME_ERROR")Syntax errors:$(bc_reset) "
    bc_cursor_to $((y+1)) "$x"
    echo -ne "$(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")${errors}$(bc_reset)"
    bc_cursor_to $((y+3)) "$x"
    echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")Press any key to continue...$(bc_reset)"
    read -rsn1
    return 1
  fi
  return 0
}

bc_runner_prompt_args() {
  local w
  w=$(bc_term_width)
  local h=$(bc_term_height)
  local prompt_row=$((h-2))
  bc_cursor_to "$prompt_row" 3
  echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")Arguments: $(bc_reset)$(bc_clear_eol)"
  local args
  IFS= read -r args
  echo "$args"
}

bc_runner_setup_log() {
  BC_RUNNER_LOG=$(mktemp "/tmp/bash-centre-runner-XXXXXX" 2>/dev/null) || {
     BC_RUNNER_LOG="/tmp/bash-centre-runner-$$-$(date +%s).log"
     : > "$BC_RUNNER_LOG"
   }
}
bc_runner_run() {
  local script_path="$1"
  if [[ ! -f $script_path ]]; then
    bc_notify "File not found: $script_path" "error"
    return 1
  fi

  local script_name=$(basename "$script_path")
  local w
  w=$(bc_term_width)
  local h=$(bc_term_height)
  local log_h=$((h-6))

  BC_RUNNER_LOG=$(mktemp "/tmp/bash-centre-runner-XXXXXX" 2>/dev/null) || {
     bc_notify "Failed to create temporary log file" "error"
     return 1
  }

bc_runner_draw_ui() {
  local script_name="$1"
  local script_args="$2"
  local log_area_top="$3"

  local w=$(bc_term_width)
  local h=$(bc_term_height)
  local log_h=$((h-6))

  bc_cursor_hide
  bc_clear

  bc_draw_box 1 1 4 "$w" "rounded" "$BC_THEME_BORDER"
  bc_center 2 "$(bc_fg "$BC_THEME_ACCENT")$(bc_bold)  Running: $(bc_fg "$BC_THEME_TEXT")${script_name} $(bc_fg "$BC_THEME_TEXT_DIM")${script_args}$(bc_reset)"
  bc_center 3 "$(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")[Space] Pause/Resume  [q] Stop & Return  [r] Restart  [Tab] Scroll output$(bc_reset)"

  bc_draw_box "$log_area_top" 1 "$log_h" "$w" "single" "$BC_THEME_BORDER" "$BC_THEME_BG"
  bc_cursor_to $((log_area_top)) 3
  echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")$(bc_bold) Output $(bc_reset)"

  local status_row=$((log_area_top+log_h))
  bc_cursor_to "$status_row" 3
  echo -ne "$(bc_fg "$BC_THEME_SUCCESS")$(bc_reset) $(bc_fg "$BC_THEME_TEXT")Running...$(bc_reset)"
  bc_cursor_to "$status_row" $((w-20))
  echo -ne "$(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")$(date '+%H:%M:%S')$(bc_reset)"
}

bc_runner_redraw_ui() {
  local script_name="$1"
  local w="$2"
  local log_h="$3"
  local log_area_top="$4"

  bc_draw_box 1 1 4 "$w" "rounded" "$BC_THEME_BORDER"
  bc_center 2 "$(bc_fg "$BC_THEME_ACCENT")$(bc_bold)  Running: $(bc_fg "$BC_THEME_TEXT")${script_name}$(bc_reset)"
  bc_center 3 "$(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")[Space] Pause/Resume  [q] Stop & Return  [r] Restart  [Tab] Scroll output$(bc_reset)"
  bc_draw_box "$log_area_top" 1 "$log_h" "$w" "single" "$BC_THEME_BORDER" "$BC_THEME_BG"
  bc_cursor_to $((log_area_top)) 3
  echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")$(bc_bold) Output $(bc_reset)"
}

bc_runner_watch_execution() {
  local script_path="$1"
  local script_args="$2"
  local script_name="$3"
  local log_area_top="$4"

  local w=$(bc_term_width)
  local h=$(bc_term_height)
  local log_h=$((h-6))
  local status_row=$((log_area_top+log_h))
  local paused=0
  local scroll_offset=0

  while kill -0 "$BC_RUNNER_PID" 2>/dev/null; do
    if bc_handle_resize; then
      w=$(bc_term_width)
      h=$(bc_term_height)
      log_h=$((h-6))
      status_row=$((log_area_top+log_h))
      bc_runner_redraw_ui "$script_name" "$w" "$log_h" "$log_area_top"
    fi

    if ((!paused)); then
      bc_runner_render_log "$log_area_top" "$log_h" "$w" "$scroll_offset"
    fi

    IFS= read -rsn1 -t 0.1 key 2>/dev/null || true
    case "$key" in
      ' ') paused=$((1-paused))
        if ((paused)); then
          bc_cursor_to "$status_row" 3
          echo -ne "$(bc_fg "$BC_THEME_WARNING")/$(bc_reset) $(bc_fg "$BC_THEME_WARNING")Paused$(bc_reset)   "
        else
          bc_cursor_to "$status_row" 3
          echo -ne "$(bc_fg "$BC_THEME_SUCCESS")$(bc_reset) $(bc_fg "$BC_THEME_TEXT")Running...$(bc_reset)"
        fi ;;
      q|Q) kill "$BC_RUNNER_PID" 2>/dev/null; wait "$BC_RUNNER_PID" 2>/dev/null; BC_RUNNING=0; break ;;
      r|R) kill "$BC_RUNNER_PID" 2>/dev/null; wait "$BC_RUNNER_PID" 2>/dev/null
        > "$BC_RUNNER_LOG"
        bash "$script_path" "$script_args" > "$BC_RUNNER_LOG" 2>&1 &
        BC_RUNNER_PID=$! ;;
      $'\e') read -rsn2 -t 0.3 key 2>/dev/null || true
        case "$key" in
          '[5') scroll_offset=$((scroll_offset-5)) ;;
          '[6') scroll_offset=$((scroll_offset+5)) ;;
        esac ;;
    esac
  done

  bc_runner_render_log "$log_area_top" "$log_h" "$w" 0

  local exit_code=0
  wait "$BC_RUNNER_PID" 2>/dev/null; exit_code=$?
  BC_RUNNING=0
  return "$exit_code"
}

bc_runner_show_status() {
  local exit_code="$1"
  local log_area_top="$2"

  local w=$(bc_term_width)
  local h=$(bc_term_height)
  local log_h=$((h-6))
  local status_row=$((log_area_top+log_h))

  bc_cursor_to "$status_row" 3
  if ((exit_code==0)); then
    echo -ne "$(bc_fg "$BC_THEME_SUCCESS")$(bc_reset) $(bc_fg "$BC_THEME_SUCCESS")Completed (exit: ${exit_code})$(bc_reset)          "
  else
    echo -ne "$(bc_fg "$BC_THEME_ERROR")$(bc_reset) $(bc_fg "$BC_THEME_ERROR")Failed (exit: ${exit_code})$(bc_reset)           "
  fi
}

bc_runner_post_run_loop() {
  local script_path="$1"
  local script_args="$2"
  local log_area_top="$3"

  local w=$(bc_term_width)
  local h=$(bc_term_height)
  local log_h=$((h-6))

  bc_center $((h-1)) "$(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")[Enter] Back to menu  [r] Run again$(bc_reset)"
  while true; do
    read -rsn1 key
    case "$key" in
      ''|q|Q) break ;;
      r|R)
        > "$BC_RUNNER_LOG"
        bash "$script_path" "$script_args" > "$BC_RUNNER_LOG" 2>&1 &
        BC_RUNNER_PID=$!
        BC_RUNNING=1
        local scroll_offset=0
        while kill -0 "$BC_RUNNER_PID" 2>/dev/null; do
          bc_runner_render_log "$log_area_top" "$log_h" "$w" "$scroll_offset"
          IFS= read -rsn1 -t 0.1 key 2>/dev/null || true
          [[ $key == q ]] && { kill "$BC_RUNNER_PID" 2>/dev/null; break; }
        done
        wait "$BC_RUNNER_PID" 2>/dev/null
        BC_RUNNING=0
        bc_runner_render_log "$log_area_top" "$log_h" "$w" 0
        bc_center $((h-1)) "$(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")[Enter] Back to menu  [r] Run again$(bc_reset)"
        ;;
    esac
  done
}

bc_runner_run() {
  local script_path="$1"
  if [[ ! -f $script_path ]]; then
    bc_notify "File not found: $script_path" "error"
    return 1
  fi

  local script_name=$(basename "$script_path")
  local log_area_top=5

  bc_runner_setup_log
  bc_recent_add "$script_path"

  if ! bc_runner_check_syntax "$script_path"; then
    return 1
  fi

  local script_args
  script_args=$(bc_runner_prompt_args)

  bc_runner_draw_ui "$script_name" "$script_args" "$log_area_top"

  > "$BC_RUNNER_LOG"
  bash "$script_path" "$script_args" > "$BC_RUNNER_LOG" 2>&1 &
  BC_RUNNER_PID=$!
  BC_RUNNING=1

  bc_runner_watch_execution "$script_path" "$script_args" "$script_name" "$log_area_top"
  local exit_code=$?

  bc_runner_show_status "$exit_code" "$log_area_top"

  bc_runner_post_run_loop "$script_path" "$script_args" "$log_area_top"

  rm -f "$BC_RUNNER_LOG"
  bc_cursor_show
}

# ── Quick-run picker ──────────────────────────────────────────────────
bc_runner_loop() {
  local files=()
  IFS=$'\n' read -rd '' -a files < <(find "$BC_DIR/uploads" -maxdepth 1 -type f -name '*.sh' 2>/dev/null | sort)
  if [[ ${#files[@]} -eq 0 ]]; then
    bc_notify "No scripts yet — create one with the editor (menu option 2)" "warning"
    return
  fi
  local names=()
  for f in "${files[@]}"; do names+=("${f##*/}"); done
  bc_menu 10 10 "${names[@]}"
  local sel=$?
  [[ $sel -ge ${#files[@]} || $sel -eq 255 ]] && return
  bc_runner_run "${files[sel]}"
}

bc_runner_render_log() {
  local log_area_top=$1 log_h=$2 w=$3 scroll_offset=$4
  local content
  content=$(tail -"$((log_h-2+scroll_offset))" "$BC_RUNNER_LOG" 2>/dev/null | head -"$((log_h-2))")
  local line_num=0
  while IFS= read -r line; do
    ((line_num >= log_h-2)) && break
    local display_row=$((log_area_top+1+line_num))
    bc_cursor_to "$display_row" 3
    echo -ne "$(bc_fg "$BC_THEME_TEXT")${line:0:$((w-6))}$(bc_reset)$(bc_clear_eol)"
    ((line_num++))
  done <<< "$content"
  while ((line_num<log_h-2)); do
    bc_cursor_to $((log_area_top+1+line_num)) 3
    echo -ne "$(bc_clear_line)"
    ((line_num++))
  done
}
