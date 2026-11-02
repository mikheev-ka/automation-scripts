#!/bin/bash
# ==============================================================================
# find_large_files.sh — поиск крупных файлов в указанном каталоге
# Использование:
#   ./find_large_files.sh [каталог] [мин_размер_МБ] [количество_результатов]
# Пример:
#   sudo ./find_large_files.sh /var 500 20
# ==============================================================================

set -euo pipefail

SEARCH_DIR="${1:-/}"
MIN_SIZE_MB="${2:-100}"
RESULT_COUNT="${3:-20}"

if [ ! -d "$SEARCH_DIR" ]; then
  echo "Ошибка: каталог '$SEARCH_DIR' не существует."
  exit 1
fi

echo "=== Файлы крупнее ${MIN_SIZE_MB} МБ в '$SEARCH_DIR' (топ-${RESULT_COUNT}) ==="
find "$SEARCH_DIR" -xdev -type f -size "+${MIN_SIZE_MB}M" -exec du -h {} + 2>/dev/null \
  | sort -rh \
  | head -n "$RESULT_COUNT"

echo ""
echo "=== Готово! ==="
