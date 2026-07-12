#!/usr/bin/env bash

[[ -n ${__BC_DASHBOARD:-} ]] && return; __BC_DASHBOARD=1

# ── Dashboard ──────────────────────────────────────────────────────────
BC_DASH_TITLE="bash-centre"
BC_DASH_VERSION="1.0.0"

bc_dashboard_render() {
  local w=$(bc_term_width)
  local h=$(bc_term_height)

  bc_clear

  local logo_lines=(
    "   ╔══════════════════════════════════════════════════╗"
    "   ║                                                  ║"
    "   ║     ██████╗  █████╗ ███████╗██╗  ██╗            ║"
    "   ║     ██╔══██╗██╔══██╗██╔════╝██║  ██║            ║"
    "   ║     ██████╔╝███████║███████╗███████║            ║"
    "   ║     ██╔══██╗██╔══██║╚════██║██╔══██║            ║"
    "   ║     ██████╔╝██║  ██║███████║██║  ██║            ║"
    "   ║     ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝            ║"
    "   ║                                                  ║"
    "   ║          ████████╗██╗   ██╗██╗                   ║"
    "   ║          ╚══██╔══╝██║   ██║██║                   ║"
    "   ║             ██║   ██║   ██║██║                   ║"
    "   ║             ██║   ██║   ██║██║                   ║"
    "   ║             ██║   ╚██████╔╝██║                   ║"
    "   ║             ╚═╝    ╚═════╝ ╚═╝                   ║"
    "   ║                                                  ║"
    "   ╚══════════════════════════════════════════════════╝"
  )

  local logo_start=1
  for ((i=0; i<${#logo_lines[@]}; i++)); do
    bc_center $((logo_start+i)) "$(bc_fg "$BC_THEME_PRIMARY")${logo_lines[i]}$(bc_reset)"
  done

  local version_row=$((logo_start+${#logo_lines[@]}+1))
  bc_center $version_row "$(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")v${BC_DASH_VERSION} — Terminal UI Command Centre$(bc_reset)"

  local menu_row=$((version_row+2))
  local menu_items=(
    "$(bc_fg "$BC_THEME_ACCENT")$(bc_bold)  1$(bc_reset)  $(bc_fg "$BC_THEME_TEXT")Run a Script$(bc_reset)              $(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")Execute a .sh script with live output$(bc_reset)"
    "$(bc_fg "$BC_THEME_ACCENT")$(bc_bold)  2$(bc_reset)  $(bc_fg "$BC_THEME_TEXT")Create New Script$(bc_reset)        $(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")Open the built-in script editor$(bc_reset)"
    "$(bc_fg "$BC_THEME_ACCENT")$(bc_bold)  3$(bc_reset)  $(bc_fg "$BC_THEME_TEXT")Browse Uploads$(bc_reset)           $(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")Manage scripts in uploads/$(bc_reset)"
    "$(bc_fg "$BC_THEME_ACCENT")$(bc_bold)  4$(bc_reset)  $(bc_fg "$BC_THEME_TEXT")System Info$(bc_reset)              $(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")View system & session details$(bc_reset)"
    "$(bc_fg "$BC_THEME_ACCENT")$(bc_bold)  5$(bc_reset)  $(bc_fg "$BC_THEME_TEXT")Examples Gallery$(bc_reset)         $(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")Browse example scripts$(bc_reset)"
    "$(bc_fg "$BC_THEME_ACCENT")$(bc_bold)  q$(bc_reset)  $(bc_fg "$BC_THEME_TEXT")Quit$(bc_reset)                    $(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")Exit bash-centre$(bc_reset)"
  )

  for ((i=0; i<${#menu_items[@]}; i++)); do
    bc_center $((menu_row+i)) "${menu_items[i]}"
  done

  local footer_row=$((h-2))
  bc_hr $footer_row 1 "$w" "$BC_THEME_BORDER" "╘" "╛"
  bc_cursor_to $((footer_row+1)) 3
  echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")  [↑/↓] Navigate  [Enter] Select  [q] Quit  [r] Refresh$(bc_reset)"

  local status_text="$BC_DASH_TITLE v$BC_DASH_VERSION | $(date '+%Y-%m-%d %H:%M') | $(bc_term_width)x$(bc_term_height)"
  bc_cursor_to $((footer_row+1)) $((w-${#status_text}-3))
  echo -ne "$(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")${status_text}$(bc_reset)"

  # Recent files section
  local recent_files=()
  while IFS= read -r f; do recent_files+=("$f"); done < <(bc_recent_list)
  if [[ ${#recent_files[@]} -gt 0 ]]; then
    local recent_row=$((menu_row + ${#menu_items[@]} + 2))
    bc_cursor_to $((recent_row)) 3
    echo -ne "$(bc_fg "$BC_THEME_BORDER")$(bc_repeat $((w-6)) "$BC_CH_HORIZ")$(bc_reset)"
    bc_cursor_to $((recent_row+1)) 3
    echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")$(bc_bold)  Recent:$(bc_reset)"
    for ((i=0; i<${#recent_files[@]} && i<5; i++)); do
      bc_cursor_to $((recent_row+2+i)) 6
      echo -ne "$(bc_fg "$BC_THEME_INFO")${BC_CH_DOT}$(bc_reset) $(bc_fg "$BC_THEME_TEXT_DIM")${recent_files[i]##*/}$(bc_reset)"
    done
    local input_row=$((recent_row + 8))
  else
    local input_row=$((menu_row + ${#menu_items[@]} + 2))
  fi

  bc_cursor_to "$input_row" 3
  echo -ne "$(bc_fg "$BC_THEME_PRIMARY")$(bc_bold)${BC_CH_SELECT}$(bc_reset) $(bc_fg "$BC_THEME_TEXT_DIM")Enter choice:$(bc_reset) "
}

bc_dashboard_loop() {
  bc_cursor_hide
  bc_dashboard_render
  while true; do
    local w h input_row
    w=$(bc_term_width)
    h=$(bc_term_height)

    if bc_handle_resize; then
      bc_dashboard_render
    fi

    input_row=$((h - 11))
    bc_cursor_to "$input_row" 18
    echo -ne "               "
    bc_cursor_to "$input_row" 18

    local choice
    IFS= read -rsn1 -t 0.3 choice 2>/dev/null || true
    case "$choice" in
      1) bc_runner_loop ;;
      2) bc_editor_new ;;
      3) bc_filebrowser_loop ;;
      4) bc_dashboard_system_info ;;
      5) bc_dashboard_examples ;;
      q|Q) bc_cursor_show
        bc_confirm $((h/2-1)) $((w/2-12)) "Quit bash-centre?"
        if [[ $? -eq 0 ]]; then bc_clear; exit 0; fi
        bc_cursor_hide ;;
      r|R) bc_dashboard_render ;;
    esac
    bc_dashboard_render
  done
  bc_cursor_show
}

# ── System info panel ──────────────────────────────────────────────────
bc_dashboard_system_info() {
  bc_clear

  local w=$(bc_term_width)
  local h=$(bc_term_height)
  local box_w=60
  local box_x=$(( (w - box_w) / 2 ))
  local box_h=18
  local box_y=2

  bc_draw_box "$box_y" "$box_x" "$box_h" "$box_w" "rounded" "$BC_THEME_BORDER" "$BC_THEME_BG"
  bc_center $((box_y+1)) "$(bc_fg "$BC_THEME_SECONDARY")$(bc_bold)  System Information  $(bc_reset)"

  local info_y=$((box_y+3))
  local info_x=$((box_x+3))
  local kernel=$(uname -r 2>/dev/null || echo "N/A")
  local host=$(uname -n 2>/dev/null || echo "N/A")
  local os=$(uname -s 2>/dev/null || echo "N/A")
  local arch=$(uname -m 2>/dev/null || echo "N/A")
  local uptime_sec=$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo 0)
  local uptime_str=""
  if command -v uptime &>/dev/null; then
    uptime_str=$(uptime -p 2>/dev/null | sed 's/up //')
  else
    local d=$((uptime_sec/86400)) h=$(( (uptime_sec%86400)/3600 )) m=$(( (uptime_sec%3600)/60 ))
    [[ $d -gt 0 ]] && uptime_str+="${d}d "
    [[ $h -gt 0 ]] && uptime_str+="${h}h "
    uptime_str+="${m}m"
  fi
  local shell_path="${SHELL:-bash}"; local shell_name="${shell_path##*/}"
  local bc_files=$(find "$BC_DIR/uploads" -maxdepth 1 -name '*.sh' 2>/dev/null | wc -l)

  local items=(
    "Kernel" "$kernel"
    "Host"   "$host"
    "OS"     "$os"
    "Arch"   "$arch"
    "Uptime" "$uptime_str"
    "Shell"  "$shell_name"
    "Term"   "${TERM:-unknown}"
    "Scripts" "$bc_files available"
  )

  for ((i=0; i<${#items[@]}; i+=2)); do
    local row=$((info_y + i/2))
    bc_cursor_to "$row" "$info_x"
    echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")$(printf "%-12s" "${items[i]}")$(bc_reset)"
    echo -ne "$(bc_fg "$BC_THEME_BORDER") : $(bc_reset)"
    echo -ne "$(bc_fg "$BC_THEME_TEXT")${items[i+1]}$(bc_reset)"
  done

  local prompt_y=$((box_y+box_h+2))
  bc_center $prompt_y "$(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")Press any key to return to dashboard$(bc_reset)"
  read -rsn1
}

# ── Examples gallery ──────────────────────────────────────────────────
bc_dashboard_examples() {
  bc_clear
  local w=$(bc_term_width)
  local h=$(bc_term_height)

  bc_draw_box 1 2 5 $((w-4)) "rounded" "$BC_THEME_BORDER"
  bc_center 2 "$(bc_fg "$BC_THEME_ACCENT")$(bc_bold)  ⚡ Example Scripts Gallery  $(bc_reset)"
  bc_center 3 "$(bc_fg "$BC_THEME_TEXT_DIM")These example scripts showcase what bash-centre can run and edit.$(bc_reset)"

  local files=("$BC_DIR/examples/"*.sh)
  local y=8

  for f in "${files[@]}"; do
    [[ ! -f $f ]] && continue
    local name="${f##*/}"; name="${name%.sh}"
    local firstline=$(head -1 "$f" 2>/dev/null | sed 's/^# //')
    bc_cursor_to "$y" 6
    echo -ne "$(bc_fg "$BC_THEME_PRIMARY")${BC_CH_SELECT}$(bc_reset) $(bc_fg "$BC_THEME_TEXT")$(bc_bold)${name}$(bc_reset)"
    bc_cursor_to "$y" $(( (w/2) + 2 ))
    echo -ne "$(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")${firstline:-No description}$(bc_reset)"
    ((y++))
  done

  local prompt_y=$((h-2))
  bc_center $prompt_y "$(bc_dim)$(bc_fg "$BC_THEME_TEXT_DIM")[Enter] Run  [e] Edit  [d] Copy to uploads  [any other key] Back$(bc_reset)"

  local choice
  read -rsn1 choice
  case "$choice" in
    '')
      local names=()
      for f in "${files[@]}"; do
        [[ -f $f ]] && names+=("${f##*/}")
      done
      if [[ ${#names[@]} -gt 0 ]]; then
        bc_runner_run "$BC_DIR/examples/${names[0]}"
      fi ;;
    e|E) for f in "${files[@]}"; do
      [[ -f $f ]] && { bc_editor_open "$f"; break; }
    done ;;
  esac
}
