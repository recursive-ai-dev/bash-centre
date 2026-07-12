# shellcheck disable=all
# shellcheck disable=all
# shellcheck disable=all

[[ -n ${__BC_CORE:-} ]] && return; __BC_CORE=1

export TERM=${TERM:-xterm-256color}

# ── Config paths ──────────────────────────────────────────────────────
BC_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/bash-centre"
BC_CONFIG_FILE="$BC_CONFIG_DIR/config"
BC_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/bash-centre"
BC_RECENT_FILE="$BC_CACHE_DIR/recent"
BC_SESSION_FILE="$BC_CACHE_DIR/session"
BC_MAX_RECENT=10

# ── Detect terminal features ──────────────────────────────────────────
bc_term_width()  { tput cols 2>/dev/null || echo 80; }
bc_term_height() { tput lines 2>/dev/null || echo 24; }

# ── 256-color palette ────────────────────────────────────────────────
BC_C_RESET='\e[0m'
BC_C_BOLD='\e[1m'
BC_C_DIM='\e[2m'

BC_C_BLACK=0
BC_C_RED=1
BC_C_GREEN=2
BC_C_YELLOW=3
BC_C_BLUE=4
BC_C_MAGENTA=5
BC_C_CYAN=6
BC_C_WHITE=7

BC_C_DEFAULT=255

# Theme palette — change these to re-theme the entire app
BC_THEME_PRIMARY=75
BC_THEME_SECONDARY=141
BC_THEME_ACCENT=213
BC_THEME_SUCCESS=42
BC_THEME_WARNING=214
BC_THEME_ERROR=196
BC_THEME_INFO=81
BC_THEME_BG=235
BC_THEME_BG_ALT=236
BC_THEME_BORDER=240
BC_THEME_TEXT=255
BC_THEME_TEXT_DIM=244
BC_THEME_HIGHLIGHT=237

bc_fg()   { echo -ne "\e[38;5;${1}m"; }
bc_bg()   { echo -ne "\e[48;5;${1}m"; }
bc_bold() { echo -ne "\e[1m"; }
bc_dim()  { echo -ne "\e[2m"; }
bc_reset(){ echo -ne "\e[0m"; }

# ── Box-drawing characters ────────────────────────────────────────────
BC_CH_HORIZ='─'
BC_CH_VERT='│'
BC_CH_TL='┌'
BC_CH_TR='┐'
BC_CH_BL='└'
BC_CH_BR='┘'
BC_CH_TEE_DOWN='┬'
BC_CH_TEE_UP='┴'
BC_CH_TEE_RIGHT='├'
BC_CH_TEE_LEFT='┤'
BC_CH_CROSS='┼'
BC_CH_BLOCK='█'
BC_CH_LIGHT_BLOCK='▓'
BC_CH_DOT='·'
BC_CH_ARROW_R='→'
BC_CH_ARROW_L='←'
BC_CH_ARROW_U='↑'
BC_CH_ARROW_D='↓'
BC_CH_SELECT='►'
BC_CH_RADIO_OFF='○'
BC_CH_RADIO_ON='●'
BC_CH_CHECK_OFF='☐'
BC_CH_CHECK_ON='☑'
BC_CH_STAR='★'
BC_CH_STAR_EMPTY='☆'

# ── Drawing helpers ───────────────────────────────────────────────────
bc_repeat()  { local c="${2:- }"; printf "%${1}s" '' | tr ' ' "$c"; }
bc_clear()   { echo -ne "\e[2J\e[H"; }
bc_clear_eol(){ echo -ne "\e[0K"; }
bc_clear_bol(){ echo -ne "\e[1K"; }
bc_clear_line(){ echo -ne "\e[2K"; }
bc_cursor_to() { echo -ne "\e[${1};${2}H"; }
bc_cursor_save(){ echo -ne "\e7"; }
bc_cursor_restore(){ echo -ne "\e8"; }
bc_cursor_hide(){ echo -ne "\e[?25l"; }
bc_cursor_show(){ echo -ne "\e[?25h"; }
bc_scroll_up(){ echo -ne "\e[${1}S"; }
bc_scroll_down(){ echo -ne "\e[${1}T"; }

bc_print_at() {
  local row=$1 col=$2; shift 2
  bc_cursor_to "$row" "$col"
  echo -ne "$*"
}

bc_fill_rect() {
  local r=$1 c=$2 h=$3 w=$4 color="${5:-$BC_THEME_BG}"
  for ((i=0; i<h; i++)); do
    bc_cursor_to $((r+i)) "$c"
    echo -ne "$(bc_bg "$color")$(bc_repeat "$w" " ")$(bc_reset)"
  done
}

# ── Box drawing ───────────────────────────────────────────────────────
bc_draw_box() {
  local r=$1 c=$2 h=$3 w=$4
  local style="${5:-single}"
  local fg_color="${6:-$BC_THEME_BORDER}"
  local bg_color="${7:-}"
  local tl tr bl br hz vr
  case "$style" in
    double)
      tl='╔' tr='╗' bl='╚' br='╝' hz='═' vr='║' ;;
    rounded)
      tl='╭' tr='╮' bl='╰' br='╯' hz='─' vr='│' ;;
    thick)
      tl='┏' tr='┓' bl='┗' br='┛' hz='━' vr='┃' ;;
    *)  tl='┌' tr='┐' bl='└' br='┘' hz='─' vr='│' ;;
  esac
  local fg="$(bc_fg "$fg_color")"
  local bg=""
  [[ -n $bg_color ]] && bg="$(bc_bg "$bg_color")"
  local rst="$(bc_reset)"

  bc_cursor_to "$r" "$c"; echo -ne "${fg}${bg}${tl}${bg}$(bc_repeat $((w-2)) "$hz")${fg}${tr}${rst}"
  for ((i=1; i<h-1; i++)); do
    bc_cursor_to $((r+i)) "$c"; echo -ne "${fg}${bg}${vr}${rst}"
    bc_cursor_to $((r+i)) $((c+w-1)); echo -ne "${fg}${bg}${vr}${rst}"
  done
  bc_cursor_to $((r+h-1)) "$c"; echo -ne "${fg}${bg}${bl}${bg}$(bc_repeat $((w-2)) "$hz")${fg}${br}${rst}"
}

# ── Horizontal rule ───────────────────────────────────────────────────
bc_hr() {
  local r=$1 c=$2 w=$3 color="${4:-$BC_THEME_BORDER}"
  local left="${5:-├}" right="${6:-┤}"
  bc_cursor_to "$r" "$c"
  echo -ne "$(bc_fg "$color")${left}$(bc_repeat $((w-2)) "─")${right}$(bc_reset)"
}

# ── Colored text helpers ──────────────────────────────────────────────
bc_title()   { echo -ne "$(bc_fg "$BC_THEME_PRIMARY")$(bc_bold)$*$(bc_reset)"; }
bc_subtitle(){ echo -ne "$(bc_fg "$BC_THEME_SECONDARY")$*$(bc_reset)"; }
bc_success() { echo -ne "$(bc_fg "$BC_THEME_SUCCESS")$*$(bc_reset)"; }
bc_warning() { echo -ne "$(bc_fg "$BC_THEME_WARNING")$*$(bc_reset)"; }
bc_error()   { echo -ne "$(bc_fg "$BC_THEME_ERROR")$*$(bc_reset)"; }
bc_info()    { echo -ne "$(bc_fg "$BC_THEME_INFO")$*$(bc_reset)"; }
bc_dim_text(){ echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")$*$(bc_reset)"; }
bc_text()    { echo -ne "$(bc_fg "$BC_THEME_TEXT")$*$(bc_reset)"; }
bc_primary() { echo -ne "$(bc_fg "$BC_THEME_PRIMARY")$*$(bc_reset)"; }

# ── Gradient text ─────────────────────────────────────────────────────
bc_gradient_text() {
  local text=$1 start_color=$2 end_color=$3
  local len=${#text} r g b sr sg sb er eg eb
  local s=$start_color e=$end_color
  for ((i=0; i<len; i++)); do
    local ratio=$(( len == 1 ? 0 : i * 100 / (len - 1) ))
    local mixed=$(( s + (e - s) * ratio / 100 ))
    echo -ne "\e[38;5;${mixed}m${text:$i:1}"
  done
  echo -ne "$(bc_reset)"
}

# ── Progress bar ──────────────────────────────────────────────────────
bc_progress_bar() {
  local pct=$1 w=${2:-40} color="${3:-$BC_THEME_PRIMARY}"
  local filled=$((pct * w / 100))
  local empty=$((w - filled))
  echo -ne "$(bc_fg "$color")$(bc_repeat $filled "$BC_CH_BLOCK")$(bc_dim)$(bc_repeat $empty "░")$(bc_reset)"
}

# ── Menu / selector ───────────────────────────────────────────────────
bc_menu() {
  local r=$1 c=$2; shift 2
  local items=("$@")
  local sel=0 len=${#items[@]} key
  local width=0
  for item in "${items[@]}"; do
    local stripped=$(echo -e "$item" | sed 's/\x1b\[[0-9;]*m//g')
    (( ${#stripped} > width )) && width=${#stripped}
  done
  ((width+=4))

  bc_cursor_hide
  local saved_row saved_col
  IFS=';' read -rsdR -p $'\e[6n' _ _ saved_row saved_col

  while true; do
    for ((i=0; i<len; i++)); do
      bc_cursor_to $((r+i)) "$c"
      if ((i==sel)); then
        echo -ne "$(bc_bg "$BC_THEME_PRIMARY")$(bc_fg "$BC_THEME_BG") ${BC_CH_SELECT} ${items[i]}$(bc_repeat $((width - ${#items[i]} - 4)) " ") $(bc_reset)"
      else
        echo -ne " $(bc_fg "$BC_THEME_TEXT_DIM")  ${items[i]}$(bc_repeat $((width - ${#items[i]} - 4)) " ") $(bc_reset)"
      fi
    done

    read -rsn1 key
    case "$key" in
      $'\e') read -rsn2 -t 0.3 key 2>/dev/null || true
        case "$key" in '[A') ((sel=(sel-1+len)%len)) ;; '[B') ((sel=(sel+1)%len)) ;; esac ;;
      '') return $sel ;;
      q|Q) return 255 ;;
    esac
  done
  bc_cursor_show
}

# ── Confirmation dialog ───────────────────────────────────────────────
bc_confirm() {
  local r=$1 c=$2 msg=$3
  local w=${#msg} h=3
  local bw=$((w+6))
  bc_draw_box "$r" "$c" "$h" "$bw" "rounded" "$BC_THEME_BORDER" "$BC_THEME_BG"
  bc_cursor_to $((r+1)) $((c+3)); echo -ne "$(bc_fg "$BC_THEME_TEXT")$msg$(bc_reset)"
  bc_cursor_to $((r+1)) $((c+bw-5)); echo -ne "$(bc_bg "$BC_THEME_SUCCESS") $(bc_fg "$BC_THEME_BG") Y $(bc_reset) "
  bc_cursor_to $((r+1)) $((c+bw-2)); echo -ne "$(bc_bg "$BC_THEME_ERROR") $(bc_fg "$BC_THEME_BG") N $(bc_reset) "
  while true; do
    read -rsn1 key
    case "${key,,}" in
      y|Y|'') return 0 ;;
      n|N) return 1 ;;
    esac
  done
}

# ── Input field ───────────────────────────────────────────────────────
bc_input() {
  local r=$1 c=$2 label=$3; shift 3
  local value="$*" key
  local prompt_len=${#label}
  local input_col=$((c+prompt_len+1))

  bc_cursor_to "$r" "$c"
  echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")${label}:$(bc_reset) "
  bc_cursor_to "$r" "$input_col"
  echo -ne "$(bc_fg "$BC_THEME_TEXT")${value}$(bc_reset)"

  local pos=${#value}
  bc_cursor_hide
  while true; do
    bc_cursor_to "$r" $((input_col+pos))
    echo -ne "$(bc_fg "$BC_THEME_PRIMARY")$(bc_bold)▎$(bc_reset)"
    IFS= read -rsn1 key
    case "$key" in
      $'\e') read -rsn2 -t 0.3 key 2>/dev/null || true
        case "$key" in
          '[C') ((pos<${#value})) && ((pos++)) ;;
          '[D') ((pos>0)) && ((pos--)) ;;
        esac ;;
      $'\x7f') [[ -n $value ]] && { value="${value:0:$((pos-1))}${value:$pos}"; ((pos--)); }
        bc_cursor_to "$r" "$input_col"; echo -ne "$(bc_fg "$BC_THEME_TEXT")${value}$(bc_reset)$(bc_repeat 2 " ")" ;;
      '') break ;;
      *) value="${value:0:$pos}${key}${value:$pos}"; ((pos++))
        bc_cursor_to "$r" "$input_col"; echo -ne "$(bc_fg "$BC_THEME_TEXT")${value}$(bc_reset)" ;;
    esac
  done
  echo -ne "\r$(bc_repeat $((input_col+pos+2)) " ")\r"
  echo "$value"
  bc_cursor_show
}

# ── Notification toast ────────────────────────────────────────────────
bc_notify() {
  local msg=$1 type="${2:-info}"
  local color
  case "$type" in
    success) color=$BC_THEME_SUCCESS ;;
    warning) color=$BC_THEME_WARNING ;;
    error)   color=$BC_THEME_ERROR ;;
    *)       color=$BC_THEME_INFO ;;
  esac
  local w=$(bc_term_width)
  local ml=${#msg}
  local x=$(( (w - ml - 4) / 2 ))
  local y=1

  bc_cursor_to "$y" "$x"
  echo -ne "$(bc_bg "$color")$(bc_fg 16)  $msg  $(bc_reset)"
  sleep 2
  bc_cursor_to "$y" "$x"
  echo -ne "$(bc_repeat $((ml+4)) " ")"
}

# ── Table renderer ────────────────────────────────────────────────────
bc_table() {
  local r=$1 c=$2; shift 2
  local headers=("$@")
  local ncols=${#headers[@]}
  local col_widths=()
  for ((i=0; i<ncols; i++)); do col_widths[i]=${#headers[i]}; done

  local rows=()
  local reading_data=0 data_rows=0
  for arg; do
    if ((reading_data)); then
      rows+=("$arg")
      ((data_rows++))
      IFS='|' read -ra fields <<< "$arg"
      for ((j=0; j<${#fields[@]}; j++)); do
        (( ${#fields[j]} > col_widths[j] )) && col_widths[j]=${#fields[j]}
      done
    fi
    [[ $arg == __DATA__ ]] && reading_data=1
  done

  local total_w=1
  for ((i=0; i<ncols; i++)); do ((total_w+=col_widths[i]+3)); done

  bc_draw_box "$r" "$c" $((data_rows+3)) "$total_w" "single" "$BC_THEME_BORDER"

  bc_cursor_to $((r+1)) $((c+2))
  for ((i=0; i<ncols; i++)); do
    echo -ne "$(bc_bg "$BC_THEME_PRIMARY")$(bc_fg 16) $(printf "%-${col_widths[i]}s" "${headers[i]}") $(bc_reset)"
    ((i<ncols-1)) && echo -ne "$(bc_bg "$BC_THEME_PRIMARY") $(bc_reset)"
  done

  bc_hr $((r+2)) "$c" "$total_w"

  for ((ri=0; ri<data_rows; ri++)); do
    IFS='|' read -ra fields <<< "${rows[ri]}"
    bc_cursor_to $((r+3+ri)) $((c+2))
    for ((j=0; j<ncols; j++)); do
      local val="${fields[j]:-}"
      local fg=${fields[ncols+j]:-$BC_THEME_TEXT}
      echo -ne "$(bc_fg "$fg") $(printf "%-${col_widths[j]}s" "$val") $(bc_reset)"
      ((j<ncols-1)) && echo -ne " "
    done
  done
}

# ── Page / tab header ─────────────────────────────────────────────────
bc_tab_header() {
  local r=$1 c=$2 active=$3; shift 3
  local tabs=("$@")
  local x=$c
  for ((i=0; i<${#tabs[@]}; i++)); do
    if ((i==active)); then
      echo -ne "$(bc_bg "$BC_THEME_PRIMARY")$(bc_fg 16) ${tabs[i]} $(bc_reset) "
    else
      echo -ne "$(bc_bg "$BC_THEME_BG_ALT")$(bc_fg "$BC_THEME_TEXT_DIM") ${tabs[i]} $(bc_reset) $(bc_fg "$BC_THEME_BORDER")│$(bc_reset)"
    fi
  done
  echo
}

# ── Centered text ─────────────────────────────────────────────────────
bc_center() {
  local row=$1; shift
  local text="$*"
  local w=$(bc_term_width)
  local stripped=$(echo -e "$text" | sed 's/\x1b\[[0-9;]*m//g')
  local x=$(( (w - ${#stripped}) / 2 ))
  bc_cursor_to "$row" "$((x+1))"
  echo -ne "$text"
}

# ── Key/value display ─────────────────────────────────────────────────
bc_kv() {
  local r=$1 c=$2 k=$3 v=$4 vc="${5:-$BC_THEME_TEXT}"
  bc_cursor_to "$r" "$c"
  echo -ne "$(bc_fg "$BC_THEME_TEXT_DIM")${k}:$(bc_reset) $(bc_fg "$vc")${v}$(bc_reset)"
}

# ── Strip ANSI codes ───────────────────────────────────────────────────
bc_strip_ansi() {
  sed 's/\x1b\[[0-9;]*m//g'
}

# ── Title banner ──────────────────────────────────────────────────────
bc_banner() {
  local text=$1
  local w=$(bc_term_width)
  local len=${#text}
  local x=$(( (w - len) / 2 ))
  local y=1

  bc_cursor_to "$y" $((x-2))
  echo -ne "$(bc_fg "$BC_THEME_BORDER")${BC_CH_TEE_RIGHT}$(bc_repeat $((len+2)) "$BC_CH_HORIZ")${BC_CH_TEE_LEFT}$(bc_reset)"
  bc_cursor_to $((y+1)) $((x-2))
  echo -ne "$(bc_fg "$BC_THEME_BORDER")${BC_CH_VERT}$(bc_reset) $(bc_fg "$BC_THEME_PRIMARY")$(bc_bold)${text}$(bc_reset) $(bc_fg "$BC_THEME_BORDER")${BC_CH_VERT}$(bc_reset)"
  bc_cursor_to $((y+2)) $((x-2))
  echo -ne "$(bc_fg "$BC_THEME_BORDER")${BC_CH_TEE_RIGHT}$(bc_repeat $((len+2)) "$BC_CH_HORIZ")${BC_CH_TEE_LEFT}$(bc_reset)"
}

# ── Config loading ────────────────────────────────────────────────────
bc_config_load() {
  mkdir -p "$BC_CONFIG_DIR" "$BC_CACHE_DIR"
  [[ -f $BC_CONFIG_FILE ]] && source "$BC_CONFIG_FILE"
}

# ── Resize handling ───────────────────────────────────────────────────
BC_RESIZE=0

bc_handle_resize() {
  if ((BC_RESIZE)); then
    BC_RESIZE=0
    return 0
  fi
  return 1
}

# ── Recent files ──────────────────────────────────────────────────────
bc_recent_add() {
  local file="$1"
  mkdir -p "$BC_CACHE_DIR"
  local tmp="${BC_RECENT_FILE}.tmp"
  { echo "$file"; grep -Fvx "$file" "$BC_RECENT_FILE" 2>/dev/null || true; } > "$tmp"
  head -n "$BC_MAX_RECENT" "$tmp" > "$BC_RECENT_FILE"
  rm -f "$tmp"
}

bc_recent_list() {
  [[ -f $BC_RECENT_FILE ]] && cat "$BC_RECENT_FILE" 2>/dev/null || true
}

bc_recent_remove() {
  local file="$1"
  [[ -f $BC_RECENT_FILE ]] || return
  local tmp="${BC_RECENT_FILE}.tmp"
  grep -Fvx "$file" "$BC_RECENT_FILE" > "$tmp" 2>/dev/null || true
  mv "$tmp" "$BC_RECENT_FILE"
}