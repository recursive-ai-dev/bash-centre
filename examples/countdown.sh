#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2155,SC2188,SC1090,SC2148
# Animated Countdown
# Shows a countdown from 10 with progress

echo "Countdown starting..."
echo ""

for i in {10..1}; do
  BAR=$(printf "%-${i}s" "" | tr ' ' '█')
  EMPTY=$(printf "%$((10-i))s" "" | tr ' ' '░')
  echo -ne "\r[${BAR}${EMPTY}] ${i}s remaining "
  sleep 1
done
echo -e "\n\nBlast off! 🚀"
