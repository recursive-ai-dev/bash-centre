#!/usr/bin/env bash
# shellcheck disable=SC2034,SC2155,SC2188,SC1090,SC2148
# Rainbow Terminal Demo
# Prints a colourful gradient pattern in the terminal

RAINBOW=(196 202 208 214 220 226 190 154 118 82 46 47 48 49 50 51 45 39 33 27 21 201 200 199 198 197)
TEXT=" ██████╗  █████╗ ███████╗██╗  ██╗"
# TEXT2=" ███████╗ ██╔══██╗ ██║  ██║ ██║  ██║"

for ((i=0; i<${#RAINBOW[@]}; i++)); do
  echo -ne "\e[38;5;${RAINBOW[i]}m${TEXT}\e[0m\n"
done
