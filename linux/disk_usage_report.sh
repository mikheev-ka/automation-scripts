#!/bin/bash
# ==============================================================================
# disk_usage_report.sh — отчёт об использовании дискового пространства
# Показывает: разделы, inodes, самые большие каталоги в /var и /home.
# Прав root не требует (но с sudo отчёт полнее).
# ==============================================================================

set -euo pipefail

TOP_DIRS_COUNT=10

echo "=== Разделы и файловые системы ==="
df -h --output=source,fstype,size,used,avail,pcent,target | grep -v tmpfs

echo ""
echo "=== Использование inodes ==="
df -i --output=source,iused,ifree,ipcent,target | grep -v tmpfs

echo ""
echo "=== Топ-${TOP_DIRS_COUNT} каталогов в /var ==="
du -xh /var 2>/dev/null | sort -rh | head -n "$TOP_DIRS_COUNT" || echo "Нет доступа к /var"

echo ""
echo "=== Топ-${TOP_DIRS_COUNT} каталогов в /home ==="
du -xh /home 2>/dev/null | sort -rh | head -n "$TOP_DIRS_COUNT" || echo "Нет доступа к /home"

echo ""
echo "=== Готово! ==="
