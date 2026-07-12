#!/usr/bin/env bash
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
