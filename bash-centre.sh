#!/usr/bin/env bash
#
# bash-centre — Terminal UI Command Centre
# A professional TUI library for running, creating, and editing bash scripts.
#
# Usage:
#   ./bash-centre.sh            Launch the TUI dashboard
#   ./bash-centre.sh run <file> Run a script directly
#   ./bash-centre.sh edit <file> Open a script in the editor
#

set -euo pipefail

# Allow BC_DIR override via env (used by system-wide install wrapper)
export BC_DIR="${BC_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"}"

# If lib wasn't found next to script, probe standard install paths
if [[ ! -f "$BC_DIR/lib/core.sh" ]]; then
  for d in "${BC_DIR%/bin}/share/bash-centre" \
           "/usr/local/share/bash-centre" \
           "/usr/share/bash-centre" \
           "$HOME/.local/share/bash-centre" \
           "/opt/bash-centre"; do
    if [[ -f "$d/lib/core.sh" ]]; then
      BC_DIR="$d"
      break
    fi
  done
  # Last resort: follow symlink (e.g. stow-based installs)
  if [[ ! -f "$BC_DIR/lib/core.sh" && -L "${BASH_SOURCE[0]}" ]]; then
    BC_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
  fi
fi

# Ensure uploads/ exists
mkdir -p "$BC_DIR/uploads"

# Source all modules
source "$BC_DIR/lib/core.sh"
source "$BC_DIR/lib/dashboard.sh"
source "$BC_DIR/lib/filebrowser.sh"
source "$BC_DIR/lib/runner.sh"
source "$BC_DIR/lib/editor.sh"
source "$BC_DIR/lib/splash.sh"

# Load user config
bc_config_load

# Terminal resize handler
trap 'BC_RESIZE=1' SIGWINCH

# ── CLI dispatch ──────────────────────────────────────────────────────
bc_main() {
  local cmd="${1:-dashboard}"

  case "$cmd" in
    dashboard)
      bc_splash_show
      bc_dashboard_loop
      ;;
    run)
      local file="${2:-}"
      if [[ -z $file ]]; then
        echo "Usage: $0 run <script.sh>"
        exit 1
      fi
      [[ ! -f $file ]] && file="$BC_DIR/uploads/$file"
      bc_runner_run "$file"
      ;;
    edit)
      local file="${2:-}"
      if [[ -z $file ]]; then
        bc_editor_new
      else
        [[ ! -f $file ]] && file="$BC_DIR/uploads/$file"
        bc_editor_open "$file"
      fi
      ;;
    uploads)
      bc_filebrowser_loop
      ;;
    --help|-h)
      echo "bash-centre — Terminal UI Command Centre"
      echo
      echo "Usage:"
      echo "  $0                  Launch interactive dashboard"
      echo "  $0 run <file>       Run a script"
      echo "  $0 edit <file>      Edit a script"
      echo "  $0 uploads          Open file browser"
      echo "  $0 --help           Show this help"
      ;;
    *)
      echo "Unknown command: $cmd"
      echo "Try '$0 --help' for usage."
      exit 1
      ;;
  esac
}

# Trap for clean exit
trap 'bc_cursor_show; bc_clear; echo; echo "Goodbye!"; exit 0' INT TERM

# Go!
bc_main "$@"
