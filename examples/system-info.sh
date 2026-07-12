#!/usr/bin/env bash
# System Information Script
# Displays hardware and OS details in a formatted report

echo "=========================================="
echo "   SYSTEM INFORMATION REPORT"
echo "=========================================="
echo ""
echo "Hostname  : $(uname -n)"
echo "OS        : $(uname -s)"
echo "Kernel    : $(uname -r)"
echo "Arch      : $(uname -m)"
echo "Uptime    : $(uptime -p 2>/dev/null || uptime)"
echo "CPU       : $(grep -c processor /proc/cpuinfo 2>/dev/null) cores"
echo ""
echo "Memory    : $(free -h | awk '/Mem:/{print $3 "/" $2}')"
echo "Disk      : $(df -h / | awk 'NR==2{print $3 "/" $2 " (" $5 ")"}')"
echo ""
echo "Shell     : $SHELL"
echo "Terminal  : ${TERM:-unknown}"
echo "User      : $(whoami)"
echo "Date      : $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "=========================================="
