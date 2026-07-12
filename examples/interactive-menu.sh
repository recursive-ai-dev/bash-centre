#!/usr/bin/env bash
# Interactive Menu Demo
# Shows a simple TUI menu using pure bash

echo "╔══════════════════════════╗"
echo "║    DEMO MENU             ║"
echo "╠══════════════════════════╣"
echo "║  1) Show Date            ║"
echo "║  2) List Files           ║"
echo "║  3) Disk Usage           ║"
echo "║  4) Weather (dummy)      ║"
echo "║  5) Exit                 ║"
echo "╚══════════════════════════╝"
echo ""
read -r -p "  Select [1-5]: " choice

case $choice in
  1) date "+  Date: %A, %d %B %Y" ;;
  2) echo "  Files:"; find . -maxdepth 1 -ls | head -10 ;;
  3) df -h / ;;
  4) echo "  Weather: Sunny, 22°C (demo)" ;;
  5) echo "  Goodbye!" ;;
  *) echo "  Invalid option" ;;
esac
