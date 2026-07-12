# shellcheck disable=all
# shellcheck disable=all
# shellcheck disable=all

[[ -n ${__BC_EDITOR:-} ]] && return; __BC_EDITOR=1

# ── Script Editor ─────────────────────────────────────────────────────
BC_EDITOR_FILE=""
BC_EDITOR_LINES=()
BC_EDITOR_CURSOR_LINE=0
BC_EDITOR_CURSOR_COL=0
BC_EDITOR_SCROLL=0
BC_EDITOR_MODIFIED=0
BC_EDITOR_FILENAME=""
BC_EDITOR_UNDO_STACK=()
BC_EDITOR_REDO_STACK=()
BC_EDITOR_LAST_ACTION=""
BC_EDITOR_CLIPBOARD=""
BC_EDITOR_SEARCH=""
BC_EDITOR_SEARCH_IDX=-1

#BC_EDITOR_KEYWORDS_PAT='\b(if|then|else|elif|fi|for|while|do|done|in|case|esac|select|until|function|return|local|export|readonly|unset|declare|typeset|printf|echo|read|set|trap|exit|continue|break|eval|exec|source|shift|getopts|let)\b'

bc_editor_new() {
  if bc_editor_load_session 2>/dev/null; then
    return 0
  fi
  BC_EDITOR_LINES=("#!/usr/bin/env bash" "" "# Script created with bash-centre" "" "")
  BC_EDITOR_CURSOR_LINE=0
  BC_EDITOR_CURSOR_COL=0
  BC_EDITOR_SCROLL=0
  BC_EDITOR_MODIFIED=1
  BC_EDITOR_FILENAME="untitled.sh"
  BC_EDITOR_UNDO_STACK=()
  BC_EDITOR_REDO_STACK=()
  BC_EDITOR_LAST_ACTION=""
  bc_editor_interface
}

bc_editor_open() {
  local filepath="$1"
  if [[ ! -f $filepath ]]; then
    bc_notify "File not found: $filepath" "error"
    return 1
  fi
  IFS=$'\n' read -rd '' -a BC_EDITOR_LINES < <(cat "$filepath"; echo)
  BC_EDITOR_CURSOR_LINE=0
  BC_EDITOR_CURSOR_COL=0
  BC_EDITOR_SCROLL=0
  BC_EDITOR_MODIFIED=0
  BC_EDITOR_FILENAME=$(basename "$filepath")
  BC_EDITOR_FILE="$filepath"
  BC_EDITOR_UNDO_STACK=()
  BC_EDITOR_REDO_STACK=()
  BC_EDITOR_LAST_ACTION=""
  bc_editor_save_session
  bc_recent_add "$filepath"
  bc_editor_interface
}

bc_editor_save() {
  if [[ -z $BC_EDITOR_FILE ]]; then
    BC_EDITOR_FILE="$BC_DIR/uploads/$BC_EDITOR_FILENAME"
  fi
  printf '%s\n' "${BC_EDITOR_LINES[@]}" > "$BC_EDITOR_FILE"
  BC_EDITOR_MODIFIED=0
  bc_editor_save_session
  bc_notify "Saved: $(basename "$BC_EDITOR_FILE")" "success"
}

bc_editor_save_as() {
  local w=$(bc_term_width)
  local h=$(bc_term_height)
  local prompt_y=$((h/2))
  local prompt_x=4

  bc_cursor_to "$prompt_y" "$prompt_x"
  echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")Save as: $(bc_reset)$(bc_clear_eol)"
  local fname
  IFS= read -r fname
  fname="${fname:-$BC_EDITOR_FILENAME}"
  BC_EDITOR_FILE="$BC_DIR/uploads/$fname"
  BC_EDITOR_FILENAME="$fname"
  bc_editor_save
}

bc_editor_save_session() {
  mkdir -p "$BC_CACHE_DIR"
  printf '%s\n' "$BC_EDITOR_FILE" "$BC_EDITOR_CURSOR_LINE" "$BC_EDITOR_CURSOR_COL" > "$BC_SESSION_FILE"
}

bc_editor_load_session() {
  [[ ! -f $BC_SESSION_FILE ]] && return 1
  local file line col
  {
    IFS= read -r file
    IFS= read -r line
    IFS= read -r col
  } < "$BC_SESSION_FILE"
  [[ -z $file || ! -f $file ]] && return 1
  bc_editor_open "$file"
  BC_EDITOR_CURSOR_LINE=${line:-0}
  BC_EDITOR_CURSOR_COL=${col:-0}
  return 0
}

# ── Undo / Redo ───────────────────────────────────────────────────────
bc_editor_save_state() {
  local state="$BC_EDITOR_CURSOR_LINE $BC_EDITOR_CURSOR_COL"$'\x02'
  state+=$(printf '%s\x02' "${BC_EDITOR_LINES[@]}")
  state="${state%$'\x02'}"
  BC_EDITOR_UNDO_STACK+=("$state")
  BC_EDITOR_REDO_STACK=()
  if [[ ${#BC_EDITOR_UNDO_STACK[@]} -gt 100 ]]; then
    BC_EDITOR_UNDO_STACK=("${BC_EDITOR_UNDO_STACK[@]: -100}")
  fi
}

bc_editor_restore_state() {
  local state="$1"
  local parts
  IFS=$'\x02' read -ra parts <<< "$state"
  local pos="${parts[0]}"
  BC_EDITOR_CURSOR_LINE="${pos%% *}"
  BC_EDITOR_CURSOR_COL="${pos##* }"
  BC_EDITOR_LINES=("${parts[@]:1}")
}

bc_editor_undo() {
  [[ ${#BC_EDITOR_UNDO_STACK[@]} -eq 0 ]] && return
  local current="$BC_EDITOR_CURSOR_LINE $BC_EDITOR_CURSOR_COL"$'\x02'
  current+=$(printf '%s\x02' "${BC_EDITOR_LINES[@]}")
  current="${current%$'\x02'}"
  BC_EDITOR_REDO_STACK+=("$current")

  bc_editor_restore_state "${BC_EDITOR_UNDO_STACK[-1]}"
  unset 'BC_EDITOR_UNDO_STACK[-1]'
  BC_EDITOR_LAST_ACTION=""
  BC_EDITOR_MODIFIED=1
}

bc_editor_redo() {
  [[ ${#BC_EDITOR_REDO_STACK[@]} -eq 0 ]] && return
  local current="$BC_EDITOR_CURSOR_LINE $BC_EDITOR_CURSOR_COL"$'\x02'
  current+=$(printf '%s\x02' "${BC_EDITOR_LINES[@]}")
  current="${current%$'\x02'}"
  BC_EDITOR_UNDO_STACK+=("$current")

  bc_editor_restore_state "${BC_EDITOR_REDO_STACK[-1]}"
  unset 'BC_EDITOR_REDO_STACK[-1]'
  BC_EDITOR_LAST_ACTION=""
  BC_EDITOR_MODIFIED=1
}

# ── Clipboard ─────────────────────────────────────────────────────────
bc_editor_copy_line() {
  local line=$(bc_editor_get_line "$BC_EDITOR_CURSOR_LINE")
  BC_EDITOR_CLIPBOARD="$line"
  bc_notify "Copied line $((BC_EDITOR_CURSOR_LINE+1))" "info"
}

bc_editor_cut_line() {
  local line=$(bc_editor_get_line "$BC_EDITOR_CURSOR_LINE")
  BC_EDITOR_CLIPBOARD="$line"
  bc_editor_save_state
  if [[ ${#BC_EDITOR_LINES[@]} -gt 1 ]]; then
    local new_lines=()
    for ((i=0; i<${#BC_EDITOR_LINES[@]}; i++)); do
      [[ $i -eq $BC_EDITOR_CURSOR_LINE ]] && continue
      new_lines+=("${BC_EDITOR_LINES[i]}")
    done
    BC_EDITOR_LINES=("${new_lines[@]}")
    ((BC_EDITOR_CURSOR_LINE >= ${#BC_EDITOR_LINES[@]})) && BC_EDITOR_CURSOR_LINE=$(( ${#BC_EDITOR_LINES[@]} - 1 ))
    ((BC_EDITOR_CURSOR_LINE < 0)) && BC_EDITOR_CURSOR_LINE=0
    BC_EDITOR_CURSOR_COL=0
  fi
  BC_EDITOR_LAST_ACTION=""
  BC_EDITOR_MODIFIED=1
  bc_notify "Cut line $((BC_EDITOR_CURSOR_LINE+1))" "warning"
}

bc_editor_paste() {
  [[ -z $BC_EDITOR_CLIPBOARD ]] && return
  bc_editor_save_state
  local new_lines=()
  for ((i=0; i<=BC_EDITOR_CURSOR_LINE; i++)); do
    new_lines+=("${BC_EDITOR_LINES[i]}")
  done
  new_lines+=("$BC_EDITOR_CLIPBOARD")
  for ((i=BC_EDITOR_CURSOR_LINE+1; i<${#BC_EDITOR_LINES[@]}; i++)); do
    new_lines+=("${BC_EDITOR_LINES[i]}")
  done
  BC_EDITOR_LINES=("${new_lines[@]}")
  BC_EDITOR_CURSOR_LINE=$((BC_EDITOR_CURSOR_LINE+1))
  BC_EDITOR_CURSOR_COL=0
  BC_EDITOR_LAST_ACTION=""
  BC_EDITOR_MODIFIED=1
}

# ── Find ──────────────────────────────────────────────────────────────
bc_editor_find_next() {
  [[ -z $BC_EDITOR_SEARCH ]] && return
  local start=$((BC_EDITOR_SEARCH_IDX + 1))
  local i
  for ((i=start; i<${#BC_EDITOR_LINES[@]}; i++)); do
    local line="${BC_EDITOR_LINES[i]}"
    if [[ $line == *"${BC_EDITOR_SEARCH}"* ]]; then
      local prefix="${line%%"${BC_EDITOR_SEARCH}"*}"
      BC_EDITOR_CURSOR_LINE=$i
      BC_EDITOR_CURSOR_COL=${#prefix}
      BC_EDITOR_SEARCH_IDX=$i
      return 0
    fi
  done
  for ((i=0; i<start-1; i++)); do
  local total=${#BC_EDITOR_LINES[@]}
  (( total == 0 )) && return 1

  local limit=$(( start == 0 ? total : total - 1 ))
  local count
  for ((count=0; count<limit; count++)); do
    i=$(( (start + count) % total ))
    local line="${BC_EDITOR_LINES[i]}"
    if [[ $line == *"${BC_EDITOR_SEARCH}"* ]]; then
      local prefix="${line%%"${BC_EDITOR_SEARCH}"*}"
      BC_EDITOR_CURSOR_LINE=$i
      BC_EDITOR_CURSOR_COL=${#prefix}
      BC_EDITOR_SEARCH_IDX=$i
      if (( i < start )); then
        bc_notify "Search wrapped to top" "info"
      fi
      return 0
    fi
  done
  bc_notify "No matches found" "warning"
  BC_EDITOR_SEARCH_IDX=-1
  return 1
}

bc_editor_find() {
  if [[ -n $BC_EDITOR_SEARCH ]]; then
    bc_editor_find_next
    return
  fi

  local w=$(bc_term_width)
  local h=$(bc_term_height)
  local prompt_row=$((h-2))

  bc_cursor_to "$prompt_row" 3
  echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")Find: $(bc_reset)$(bc_clear_eol)"

  local query="" key
  while true; do
    bc_cursor_to "$prompt_row" 10
    echo -ne "$(bc_fg "$BC_THEME_TEXT")${query}$(bc_reset) "
    bc_cursor_to "$prompt_row" $((10+${#query}))
    IFS= read -rsn1 key
    case "$key" in
      $'\x1b') read -rsn2 -t 0.3 _ 2>/dev/null || true; BC_EDITOR_SEARCH=""; return ;;
      $'\n'|$'\r'|'') break ;;
      $'\x7f') query="${query%?}" ;;
      *) query+="$key" ;;
    esac
  done

  BC_EDITOR_SEARCH="$query"
  BC_EDITOR_SEARCH_IDX=-1
  if [[ -n $query ]]; then
    bc_editor_find_next
  fi
}

# ── Auto-indent helpers ───────────────────────────────────────────────
bc_editor_get_indent() {
  local line="$1"
  local indent=""
  if [[ $line =~ ^([[:space:]]*) ]]; then
    indent="${BASH_REMATCH[1]}"
  fi
  echo "$indent"
}

bc_editor_needs_extra_indent() {
  local line="$1"
  local trimmed="${line#"${line%%[![:space:]]*}"}"
  [[ $trimmed =~ (then|do|else|elif|\{)$ ]]
}

bc_editor_needs_dedent() {
  local line="$1"
  local trimmed="${line#"${line%%[![:space:]]*}"}"
  [[ $trimmed =~ ^(fi|done|esac|elif|else|\}) ]]
}

# ── Editor interface ──────────────────────────────────────────────────
bc_editor_interface() {
  local w h editor_h key exit_editor=0

  local saved_stty
  saved_stty=$(stty -g 2>/dev/null || true)
  stty -isig -echo 2>/dev/null || true
  trap 'stty "$saved_stty" 2>/dev/null || true' RETURN

  bc_cursor_hide
  while ((exit_editor==0)); do
    if bc_handle_resize; then
      w=$(bc_term_width)
      h=$(bc_term_height)
      editor_h=$((h-5))
    else
      w=$(bc_term_width)
      h=$(bc_term_height)
      editor_h=$((h-5))
    fi

    bc_clear

    bc_draw_box 1 1 3 $w "rounded" "$BC_THEME_BORDER"
    local mod_flag=""
    ((BC_EDITOR_MODIFIED)) && mod_flag=" $(bc_fg "$BC_THEME_WARNING")$(bc_reset)"
    bc_center 2 "$(bc_fg "$BC_THEME_ACCENT")$(bc_bold)  $(bc_fg "$BC_THEME_TEXT")${BC_EDITOR_FILENAME}${mod_flag}  $(bc_reset)$(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")[${#BC_EDITOR_LINES[@]} lines]$(bc_reset)"
    bc_cursor_to 3 3
    echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")  Ln $((BC_EDITOR_CURSOR_LINE+1)), Col $((BC_EDITOR_CURSOR_COL+1))  |  [Esc] Menu  [^S] Save  [^O] SaveAs  [^Q] Quit  [^F] Find  [^Z] Undo  [^R] Redo$(bc_reset)"

    local editor_top=5
    local gutter_w=5
    local text_w=$((w - gutter_w - 4))
    local line_count=${#BC_EDITOR_LINES[@]}

    bc_draw_box "$editor_top" 1 "$editor_h" $w "single" "$BC_THEME_BORDER"
    bc_cursor_to "$editor_top" 3
    echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")$(bc_bold) Ln  | Code$(bc_reset)"

    ((BC_EDITOR_CURSOR_LINE < BC_EDITOR_SCROLL)) && BC_EDITOR_SCROLL=$BC_EDITOR_CURSOR_LINE
    ((BC_EDITOR_CURSOR_LINE >= BC_EDITOR_SCROLL+editor_h-2)) && BC_EDITOR_SCROLL=$((BC_EDITOR_CURSOR_LINE - editor_h + 3))
    ((BC_EDITOR_SCROLL < 0)) && BC_EDITOR_SCROLL=0

    for ((i=0; i<editor_h-2; i++)); do
      local line_idx=$((BC_EDITOR_SCROLL + i))
      local display_row=$((editor_top + 1 + i))

      bc_cursor_to "$display_row" 3
      if ((line_idx < line_count)); then
        local ln_str=$(printf "%4d" $((line_idx+1)))
        if ((line_idx == BC_EDITOR_CURSOR_LINE)); then
          echo -ne "$(bc_fg "$BC_THEME_PRIMARY")$(bc_bold)${ln_str}$(bc_reset)$(bc_fg "$BC_THEME_BORDER")|$(bc_reset)"
        else
          echo -ne "$(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")${ln_str}$(bc_reset)$(bc_fg "$BC_THEME_BORDER")|$(bc_reset)"
        fi
      else
        echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")$(printf "%4s" "~")$(bc_reset)$(bc_fg "$BC_THEME_BORDER")|$(bc_reset)"
      fi

      if ((line_idx < line_count)); then
        local raw_line="${BC_EDITOR_LINES[line_idx]}"
        local display_line="${raw_line:0:$text_w}"
        bc_editor_render_line "$display_row" $((gutter_w+4)) "$display_line" "$line_idx"
      fi

      bc_cursor_to "$display_row" $((w-1))
      echo -ne "$(bc_clear_eol)"
    done

    if [[ -n $BC_EDITOR_SEARCH ]]; then
      bc_cursor_to $((h-1)) 3
      echo -ne "$(bc_fg "$BC_THEME_INFO")Search: $(bc_fg "$BC_THEME_TEXT")${BC_EDITOR_SEARCH}$(bc_reset)  $(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")[^F] next  [Esc] clear$(bc_reset)$(bc_clear_eol)"
    fi

    local cursor_row=$((editor_top + 1 + BC_EDITOR_CURSOR_LINE - BC_EDITOR_SCROLL))
    local cursor_col=$((gutter_w + 4 + BC_EDITOR_CURSOR_COL))
    bc_cursor_to "$cursor_row" "$cursor_col"

    IFS= read -rsn1 key
    case "$key" in
      $'\x1b')
        read -rsn2 -t 0.3 key2 2>/dev/null || true
        case "$key2" in
          '[A') bc_editor_move_up ;;
          '[B') bc_editor_move_down ;;
          '[C') bc_editor_move_right ;;
          '[D') bc_editor_move_left ;;
          '[H') BC_EDITOR_CURSOR_LINE=0; BC_EDITOR_CURSOR_COL=0 ;;
          '[F') BC_EDITOR_CURSOR_LINE=$((line_count-1)); BC_EDITOR_CURSOR_COL=0 ;;
          '[Z') bc_editor_insert_text "  " ;;
          '[3') read -rsn1 -t 0.3 _ 2>/dev/null || true; bc_editor_delete_char ;;
          '[5') BC_EDITOR_SCROLL=$((BC_EDITOR_SCROLL-editor_h+2)); ((BC_EDITOR_SCROLL<0)) && BC_EDITOR_SCROLL=0 ;;
          '[6') BC_EDITOR_SCROLL=$((BC_EDITOR_SCROLL+editor_h-2)) ;;
          '') exit_editor=1 ;;
        esac ;;
      $'\x01') bc_editor_move_home ;;
      $'\x05') bc_editor_move_end ;;
      $'\x06') bc_editor_find ;;
      $'\x0f') bc_editor_save_as ;;
      $'\x10') bc_editor_paste ;;
      $'\x11') exit_editor=1 ;;
      $'\x12') bc_editor_redo ;;
      $'\x13') bc_editor_save ;;
      $'\x15') bc_editor_cut_line ;;
      $'\x19') bc_editor_copy_line ;;
      $'\x1a') bc_editor_undo ;;
      $'\x03') ;;
      $'\x04') ;;
      $'\x7f') bc_editor_backspace ;;
      $'\n'|$'\r') bc_editor_insert_newline ;;
      $'\t') bc_editor_insert_text "  " ;;
      '') exit_editor=1 ;;
      *) bc_editor_insert_text "$key" ;;
    esac
  done

if ((BC_EDITOR_MODIFIED)); then
     local confirm_row=$((h/2))
     bc_center $confirm_row "$(bc_fg "$BC_THEME_WARNING")Unsaved changes! Save before closing? (y/n/cancel)$(bc_reset)"
     while true; do
       read -rsn1 key
       case "${key,,}" in
         y) bc_editor_save; break ;;
         n) return ;;
         ''|q|Q) return ;;
       esac
     done
   fi

  bc_editor_save_session
  bc_cursor_show
}

bc_editor_render_line() {
  local row=$1 col=$2 line=$3 line_idx=$4
  bc_cursor_to "$row" "$col"

  local rest="$line"
  local output=""

  if [[ $rest == \#* ]]; then
    echo -ne "$(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")${rest}$(bc_reset)"
    return
  fi

  if [[ $line_idx -eq 0 && $rest == '#!'* ]]; then
    echo -ne "$(bc_fg "$BC_THEME_ACCENT")${rest}$(bc_reset)"
    return
  fi

  #local token=""
  local in_string=0 string_char=""
  local i=0
  while ((i<${#rest})); do
    local ch="${rest:$i:1}"
    local next="${rest:$((i+1)):1}"

    if ((in_string)); then
      output+="$ch"
      if [[ $ch == "$string_char" ]]; then
        in_string=0
      fi
    elif [[ $ch == '"' || $ch == "'" ]]; then
      echo -ne "$(bc_fg "$BC_THEME_SUCCESS")${output}$(bc_reset)"
      output="$ch"
      in_string=1
      string_char="$ch"
    elif [[ $ch == '$' && ($next == '{' || $next == '(' || $next =~ [a-zA-Z_]) ]]; then
      echo -ne "$(bc_fg "$BC_THEME_TEXT")${output}$(bc_reset)"
      output=""
      local var_ref="$ch"
      ((i++))
      if [[ $next == '{' ]]; then
        while ((i<${#rest})); do var_ref+="${rest:$i:1}"; [[ ${rest:$i:1} == '}' ]] && break; ((i++)); done
      elif [[ $next == '(' ]]; then
        var_ref+='('; ((i++)); local depth=1
        while ((i<${#rest} && depth>0)); do
          local c="${rest:$i:1}"
          var_ref+="$c"
          [[ $c == '(' ]] && ((depth++))
          [[ $c == ')' ]] && ((depth--))
          ((i++))
        done
      else
        while ((i<${#rest})); do
          local c="${rest:$i:1}"
          [[ $c =~ [a-zA-Z0-9_] ]] && var_ref+="$c" || { ((i--)); break; }
          ((i++))
        done
      fi
      echo -ne "$(bc_fg "$BC_THEME_INFO")${var_ref}$(bc_reset)"
    elif [[ $ch == '#' && $in_string -eq 0 ]]; then
      echo -ne "$(bc_fg "$BC_THEME_TEXT")${output}$(bc_reset)"
      echo -ne "$(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")${rest:$i}$(bc_reset)"
      output=""
      break
    else
      output+="$ch"
    fi
    ((i++))
  done
  echo -ne "$(bc_fg "$BC_THEME_TEXT")${output}$(bc_reset)"
}

bc_editor_get_line() {
  local idx=$1
  if ((idx < 0)); then
    echo ""
  elif ((idx >= ${#BC_EDITOR_LINES[@]})); then
    echo ""
  else
    echo "${BC_EDITOR_LINES[idx]}"
  fi
}

bc_editor_insert_text() {
  local text="$1"
  if [[ $BC_EDITOR_LAST_ACTION != insert ]]; then
    bc_editor_save_state
    BC_EDITOR_LAST_ACTION=insert
  fi
  local line=$(bc_editor_get_line "$BC_EDITOR_CURSOR_LINE")
  line="${line:0:$BC_EDITOR_CURSOR_COL}${text}${line:$BC_EDITOR_CURSOR_COL}"
  BC_EDITOR_LINES[BC_EDITOR_CURSOR_LINE]="$line"
  BC_EDITOR_CURSOR_COL=$((BC_EDITOR_CURSOR_COL + ${#text}))
  BC_EDITOR_MODIFIED=1
}

bc_editor_insert_newline() {
  bc_editor_save_state
  local line=$(bc_editor_get_line "$BC_EDITOR_CURSOR_LINE")
  local before="${line:0:$BC_EDITOR_CURSOR_COL}"
  local after="${line:$BC_EDITOR_CURSOR_COL}"

  local indent=$(bc_editor_get_indent "$before")
  #local trimmed_before="${before#"${before%%[![:space:]]*}"}"
  local new_indent="$indent"

  if bc_editor_needs_extra_indent "$before"; then
    new_indent+="  "
  fi

  # Handle dedent for closing keywords
  if bc_editor_needs_dedent "$after"; then
    if [[ ${#indent} -ge 2 ]]; then
      indent="${indent:2}"
    fi
    new_indent="$indent"
  fi

  BC_EDITOR_LINES[BC_EDITOR_CURSOR_LINE]="$before"

  local after_indented="${new_indent}${after}"
  BC_EDITOR_LINES=("${BC_EDITOR_LINES[@]:0:$((BC_EDITOR_CURSOR_LINE+1))}" "$after_indented" "${BC_EDITOR_LINES[@]:$((BC_EDITOR_CURSOR_LINE+1))}")
  BC_EDITOR_CURSOR_LINE=$((BC_EDITOR_CURSOR_LINE+1))
  BC_EDITOR_CURSOR_COL=${#new_indent}
  BC_EDITOR_LAST_ACTION=""
  BC_EDITOR_MODIFIED=1
}

bc_editor_backspace() {
  bc_editor_save_state
  if ((BC_EDITOR_CURSOR_COL>0)); then
    local line=$(bc_editor_get_line "$BC_EDITOR_CURSOR_LINE")
    line="${line:0:$((BC_EDITOR_CURSOR_COL-1))}${line:$BC_EDITOR_CURSOR_COL}"
    BC_EDITOR_LINES[BC_EDITOR_CURSOR_LINE]="$line"
    BC_EDITOR_CURSOR_COL=$((BC_EDITOR_CURSOR_COL-1))
    BC_EDITOR_MODIFIED=1
  elif ((BC_EDITOR_CURSOR_LINE>0)); then
    local prev_line=$(bc_editor_get_line $((BC_EDITOR_CURSOR_LINE-1)))
    local cur_line=$(bc_editor_get_line "$BC_EDITOR_CURSOR_LINE")
    BC_EDITOR_CURSOR_COL=${#prev_line}
    BC_EDITOR_LINES[$((BC_EDITOR_CURSOR_LINE-1))]="${prev_line}${cur_line}"
    unset 'BC_EDITOR_LINES[BC_EDITOR_CURSOR_LINE]'
    BC_EDITOR_LINES=("${BC_EDITOR_LINES[@]}")
    BC_EDITOR_CURSOR_LINE=$((BC_EDITOR_CURSOR_LINE-1))
    BC_EDITOR_MODIFIED=1
  fi
  BC_EDITOR_LAST_ACTION=""
}

bc_editor_delete_char() {
  bc_editor_save_state
  local line=$(bc_editor_get_line "$BC_EDITOR_CURSOR_LINE")
  if ((BC_EDITOR_CURSOR_COL<${#line})); then
    line="${line:0:$BC_EDITOR_CURSOR_COL}${line:$((BC_EDITOR_CURSOR_COL+1))}"
    BC_EDITOR_LINES[BC_EDITOR_CURSOR_LINE]="$line"
    BC_EDITOR_MODIFIED=1
  elif ((BC_EDITOR_CURSOR_LINE<${#BC_EDITOR_LINES[@]}-1)); then
    local next_line=$(bc_editor_get_line $((BC_EDITOR_CURSOR_LINE+1)))
    line="${line}${next_line}"
    BC_EDITOR_LINES[BC_EDITOR_CURSOR_LINE]="$line"
    unset 'BC_EDITOR_LINES[$((BC_EDITOR_CURSOR_LINE+1))]'
    BC_EDITOR_LINES=("${BC_EDITOR_LINES[@]}")
    BC_EDITOR_MODIFIED=1
  fi
  BC_EDITOR_LAST_ACTION=""
}

bc_editor_move_up()    { ((BC_EDITOR_CURSOR_LINE>0)) && { BC_EDITOR_CURSOR_LINE=$((BC_EDITOR_CURSOR_LINE-1)); local l=$(bc_editor_get_line "$BC_EDITOR_CURSOR_LINE"); ((BC_EDITOR_CURSOR_COL>${#l})) && BC_EDITOR_CURSOR_COL=${#l}; }; }
bc_editor_move_down()  { ((BC_EDITOR_CURSOR_LINE<${#BC_EDITOR_LINES[@]}-1)) && { BC_EDITOR_CURSOR_LINE=$((BC_EDITOR_CURSOR_LINE+1)); local l=$(bc_editor_get_line "$BC_EDITOR_CURSOR_LINE"); ((BC_EDITOR_CURSOR_COL>${#l})) && BC_EDITOR_CURSOR_COL=${#l}; }; }
bc_editor_move_left()  { ((BC_EDITOR_CURSOR_COL>0)) && BC_EDITOR_CURSOR_COL=$((BC_EDITOR_CURSOR_COL-1)); }
bc_editor_move_right() { local l=$(bc_editor_get_line "$BC_EDITOR_CURSOR_LINE"); ((BC_EDITOR_CURSOR_COL<${#l})) && BC_EDITOR_CURSOR_COL=$((BC_EDITOR_CURSOR_COL+1)); }
bc_editor_move_home()  { BC_EDITOR_CURSOR_COL=0; }
bc_editor_move_end()   { local l=$(bc_editor_get_line "$BC_EDITOR_CURSOR_LINE"); BC_EDITOR_CURSOR_COL=${#l}; }
