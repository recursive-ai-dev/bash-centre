# shellcheck disable=all
# shellcheck disable=all
# shellcheck disable=all

[[ -n ${__BC_FILEBROWSER:-} ]] && return; __BC_FILEBROWSER=1

# ── File Browser for uploads/ ─────────────────────────────────────────
BC_FB_DIR="$BC_DIR/uploads"
BC_FB_FILTER=""

bc_filebrowser_filter_files() {
  local dir="$1" filter="$2"
  if [[ -z $filter ]]; then
    find "$dir" -maxdepth 1 -type f -name '*.sh' 2>/dev/null | sort
  else
    find "$dir" -maxdepth 1 -type f -name '*.sh' 2>/dev/null | sort | while IFS= read -r f; do
      local base=$(basename "$f")
      if [[ ${base,,} == *"${filter,,}"* ]]; then
        echo "$f"
      fi
    done
  fi
}

bc_filebrowser_search_prompt() {
  local h=$(bc_term_width)
  local prompt_row=$(($(bc_term_height) - 1))
  bc_cursor_to "$prompt_row" 3
  echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")Filter: $(bc_reset)$(bc_clear_eol)"
  local query="" key
  while true; do
    bc_cursor_to "$prompt_row" 12
    echo -ne "$(bc_fg "$BC_THEME_TEXT")${query}$(bc_reset) "
    bc_cursor_to "$prompt_row" $((12+${#query}))
    IFS= read -rsn1 key 2>/dev/null
    case "$key" in
      $'\x1b') read -rsn2 -t 0.3 _ 2>/dev/null || true; break ;;
      $'\n'|$'\r'|'') break ;;
      $'\x7f') query="${query%?}" ;;
      *) query+="$key" ;;
    esac
  done
  BC_FB_FILTER="$query"
}

bc_filebrowser_rename() {
  local old_path="$1" sel=$2
  local old_name=$(basename "$old_path")
  local dir=$(dirname "$old_path")
  local w=$(bc_term_width)
  local h=$(bc_term_height)
  local prompt_y=$((h/2))
  bc_cursor_to "$prompt_y" 4
  echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")Rename '$(bc_fg "$BC_THEME_TEXT")${old_name}$(bc_reset)$(bc_fg "$BC_THEME_TEXT_DIM")' to: $(bc_reset)$(bc_clear_eol)"
  local new_name
  IFS= read -r new_name
  new_name="${new_name:-$old_name}"
  if [[ $new_name != "$old_name" && -n $new_name ]]; then
    if [[ $new_name != *.sh ]]; then new_name="${new_name}.sh"; fi
    mv "$old_path" "$dir/$new_name" 2>/dev/null
    if [[ $? -eq 0 ]]; then
      bc_notify "Renamed to $new_name" "success"
    else
      bc_notify "Rename failed" "error"
    fi
  fi
}

bc_filebrowser_loop() {
  local files=()
  local sel=0 scroll=0 key

  bc_cursor_hide
  while true; do
    bc_clear

    local w=$(bc_term_width)
    local h=$(bc_term_height)
    local list_h=$((h-8))
    local preview_w=$((w/2 - 4))
    local list_w=$((w - preview_w - 10))

    if bc_handle_resize; then
      w=$(bc_term_width)
      h=$(bc_term_height)
      list_h=$((h-8))
      preview_w=$((w/2 - 4))
      list_w=$((w - preview_w - 10))
    fi

    IFS=$'\n' read -rd '' -a files < <(bc_filebrowser_filter_files "$BC_FB_DIR" "$BC_FB_FILTER")
    local count=${#files[@]}

    bc_draw_box 1 2 4 $((w-4)) "rounded" "$BC_THEME_BORDER"
    bc_center 2 "$(bc_fg "$BC_THEME_PRIMARY")$(bc_bold)  Script Uploads  $(bc_reset)$(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")[${count} files]$(bc_reset)"
    bc_center 3 "$(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")Drop .sh scripts into $(bc_fg "$BC_THEME_ACCENT")uploads/$(bc_reset)$(bc_dim) or use the menu below$(bc_reset)"

    local list_left=4
    local list_top=6

    local preview_start=$((list_left + list_w + 4))
    preview_w=$((w - preview_start - 4))

    bc_draw_box "$list_top" "$list_left" "$list_h" "$list_w" "single" "$BC_THEME_BORDER"
    bc_cursor_to $((list_top)) $((list_left + 2))
    echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")$(bc_bold) Files $(bc_reset)"
    if [[ -n $BC_FB_FILTER ]]; then
      echo -ne "$(bc_fg "$BC_THEME_WARNING") filter:${BC_FB_FILTER}$(bc_reset)"
    fi

    if ((preview_w > 20)); then
      bc_draw_box "$list_top" "$preview_start" "$list_h" "$preview_w" "single" "$BC_THEME_BORDER"
      bc_cursor_to $((list_top)) $((preview_start + 2))
      echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")$(bc_bold) Preview $(bc_reset)"
    fi

    local max_visible=$((list_h-2))
    ((sel >= count)) && sel=$((count-1))
    ((sel < 0)) && sel=0
    ((sel >= scroll+max_visible)) && scroll=$((sel-max_visible+1))
    ((sel < scroll)) && scroll=$sel

    for ((i=0; i<max_visible && i+scroll<count; i++)); do
      local idx=$((i+scroll))
      local fname=$(basename "${files[idx]}")
      local fsize=$(stat -c%s "${files[idx]}" 2>/dev/null || echo 0)
      local fsize_str
      if ((fsize>1024)); then fsize_str="$((fsize/1024))KB"; else fsize_str="${fsize}B"; fi

      bc_cursor_to $((list_top+1+i)) $((list_left+2))
      if ((idx==sel)); then
        echo -ne "$(bc_bg "$BC_THEME_HIGHLIGHT")$(bc_fg "$BC_THEME_PRIMARY")${BC_CH_SELECT}$(bc_reset)"
        bc_cursor_to $((list_top+1+i)) $((list_left+4))
        echo -ne "$(bc_bg "$BC_THEME_HIGHLIGHT")$(bc_fg "$BC_THEME_TEXT")$(printf "%-$((list_w-6))s" "$fname")$(bc_reset)"
        bc_cursor_to $((list_top+1+i)) $((list_left+list_w-10))
        echo -ne "$(bc_bg "$BC_THEME_HIGHLIGHT")$(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")${fsize_str}$(bc_reset)"
      else
        echo -ne " $(bc_fg "$BC_THEME_TEXT_DIM") $(printf "%-$((list_w-6))s" "$fname")$(bc_reset)"
      fi
    done

    if ((preview_w > 20 && count > 0 && sel < count)); then
      local preview_lines=$((list_h-2))
      bc_cursor_to $((list_top+1)) $((preview_start+2))
      local fcontent
      fcontent=$(head -"$preview_lines" "${files[sel]}" 2>/dev/null)
      local line_num=0
      while IFS= read -r line; do
        ((line_num >= preview_lines)) && break
        bc_cursor_to $((list_top+1+line_num)) $((preview_start+2))
        local display_line="${line:0:$((preview_w-2))}"
        if [[ $line == \#* ]]; then
          echo -ne "$(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")${display_line}$(bc_reset)"
        elif [[ -z $line ]]; then
          echo -ne " "
        else
          echo -ne "$(bc_fg "$BC_THEME_TEXT")${display_line}$(bc_reset)"
        fi
        ((line_num++))
      done <<< "$fcontent"
    fi

    local footer_row=$((h-1))
    bc_hr $((footer_row-1)) 1 "$w" "$BC_THEME_BORDER" "╘" "╛"
    bc_cursor_to "$footer_row" 3
    local footer_text="[↑↓/kj] Nav  [Enter] Run  [e] Edit  [c] New  [d] Del  [/] Filter  [R] Rename  [r] Refresh  [q] Back"
    echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")${footer_text}$(bc_reset)"

    local info_text="$(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")$(date '+%H:%M') | $(bc_reset)$(bc_fg "$BC_THEME_ACCENT")$(basename "${files[sel]:-none}")$(bc_reset)"
    bc_cursor_to "$footer_row" $((w-${#info_text}-3))
    echo -ne "$info_text"

    IFS= read -rsn1 -t 0.3 key 2>/dev/null || true
    case "$key" in
      $'\e') read -rsn2 -t 0.3 key 2>/dev/null || true
        case "$key" in
          '[A'|'k') ((sel>0)) && ((sel--)) ;;
          '[B'|'j') ((sel<count-1)) && ((sel++)) ;;
          '[H'|'g') sel=0; scroll=0 ;;
          '[F'|'G') sel=$((count-1)) ;;
        esac ;;
      '') if ((count>0 && sel<count)); then
        bc_runner_run "${files[sel]}"
      fi ;;
      e|E) if ((count>0 && sel<count)); then
        bc_editor_open "${files[sel]}"
      fi ;;
      c|C) bc_editor_new ;;
      d|D) if ((count>0 && sel<count)); then
         local fname
         fname="$(basename "${files[sel]}")"
         bc_confirm 12 20 "Delete '${fname}'?"
        if [[ $? -eq 0 ]]; then
          rm -f "${files[sel]}"
          bc_recent_remove "${files[sel]}"
          bc_notify "Deleted ${fname}" "warning"
        fi
      fi ;;
      r) ;;
      '/') bc_filebrowser_search_prompt ;;
      'R') if ((count>0 && sel<count)); then
        bc_filebrowser_rename "${files[sel]}" "$sel"
      fi ;;
      q|Q) BC_FB_FILTER=""; break ;;
    esac
  done
  bc_cursor_show
}
