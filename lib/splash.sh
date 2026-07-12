# shellcheck disable=all
# shellcheck disable=all
# shellcheck disable=all

[[ -n ${__BC_SPLASH:-} ]] && return; __BC_SPLASH=1

# ── Splash / Boot Screen ──────────────────────────────────────────────
bc_splash_show() {
  local w=$(bc_term_width)
  local h=$(bc_term_height)
  local start_row=$((h/2 - 8))

  bc_clear
  bc_cursor_hide

  # Animated gradient bar
  for ((i=0; i<w; i++)); do
    local step=$((i * 100 / w))
    local color
    if ((step < 50)); then
      color=$(( (step * (BC_THEME_PRIMARY - 20) / 50) + 20 ))
    else
      color=$(( ((step-50) * (BC_THEME_ACCENT - BC_THEME_PRIMARY) / 50) + BC_THEME_PRIMARY ))
    fi
    bc_cursor_to $((start_row+8)) $((i+1))
    echo -ne "$(bc_bg "$color") $(bc_reset)"
  done

  # Logo
  local logo=(
    "    ██████╗  █████╗ ███████╗██╗  ██╗"
    "    ██╔══██╗██╔══██╗██╔════╝██║  ██║"
    "    ██████╔╝███████║███████╗███████║"
    "    ██╔══██╗██╔══██║╚════██║██╔══██║"
    "    ██████╔╝██║  ██║███████║██║  ██║"
    "    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝"
  )

  for ((i=0; i<${#logo[@]}; i++)); do
    bc_gradient_text "${logo[i]}" $BC_THEME_PRIMARY $BC_THEME_ACCENT
    echo
  done

  # Subtitle with typewriter effect
  local subtitle="Terminal UI Command Centre v1.0.0"
  bc_center $((start_row+10)) ""
  local x=$(( (w - ${#subtitle}) / 2 ))
  bc_cursor_to $((start_row+10)) $((x+1))
  echo -ne "$(bc_fg "$BC_THEME_SECONDARY")"
  for ((i=0; i<${#subtitle}; i++)); do
    echo -ne "${subtitle:$i:1}"
    sleep 0.015
  done
  echo -ne "$(bc_reset)"

  # Loading indicators
  local load_items=("Initialising UI engine..." "Loading modules..." "Scanning uploads..." "Ready!")
  local load_row=$((start_row+12))

  for ((i=0; i<${#load_items[@]}; i++)); do
    sleep 0.2
    bc_cursor_to "$load_row" $((w/2-15))
    echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")${load_items[i]}$(bc_reset)"
    bc_cursor_to "$load_row" $((w/2+15))
    echo -ne "$(bc_fg "$BC_THEME_PRIMARY")"
    for ((j=0; j<=i; j++)); do echo -ne "${BC_CH_BLOCK}"; done
    echo -ne "$(bc_reset)"
  done

  sleep 0.3
}
