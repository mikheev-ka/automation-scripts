#!/bin/bash
# ==============================================================================
# backup_dir.sh — резервное копирование каталога в tar.gz с ротацией
# Использование:
#   ./backup_dir.sh <что_копировать> [куда_складывать] [срок_хранения_дней]
# Пример:
#   sudo ./backup_dir.sh /var/www/html/nextcloud /opt/backups 14
# ==============================================================================

set -euo pipefail

# --- Параметры ---
SOURCE_DIR="${1:-}"
BACKUP_DIR="${2:-/opt/backups}"
RETENTION_DAYS="${3:-14}"

if [ -z "$SOURCE_DIR" ]; then
  echo "Использование: $0 <что_копировать> [куда_складывать] [срок_хранения_дней]"
  exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Ошибка: каталог '$SOURCE_DIR' не существует."
  exit 1
fi

mkdir -p "$BACKUP_DIR"

# Имя архива: <имя_каталога>_YYYY-MM-DD_HH-MM.tar.gz
ARCHIVE_NAME="$(basename "$SOURCE_DIR")_$(date +%Y-%m-%d_%H-%M).tar.gz"
ARCHIVE_PATH="${BACKUP_DIR}/${ARCHIVE_NAME}"

echo "=== Создание архива: $ARCHIVE_PATH ==="
tar -czf "$ARCHIVE_PATH" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")"

echo "=== Ротация: удаление архивов старше ${RETENTION_DAYS} дней ==="
find "$BACKUP_DIR" -name "$(basename "$SOURCE_DIR")_*.tar.gz" -mtime "+${RETENTION_DAYS}" -delete

echo "=== Готово! ==="
echo "Архив: $ARCHIVE_PATH ($(du -h "$ARCHIVE_PATH" | cut -f1))"
