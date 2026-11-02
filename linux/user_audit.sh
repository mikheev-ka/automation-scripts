#!/bin/bash
# ==============================================================================
# user_audit.sh — аудит локальных учётных записей сервера
# Показывает: кто может входить в систему, кто в sudo, у кого пустой пароль.
# Требует прав root (sudo) для проверки /etc/shadow.
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Пожалуйста, запустите с sudo: sudo $0"
  exit 1
fi

echo "=== Пользователи с доступом к оболочке (login shell) ==="
awk -F: '$7 !~ /(nologin|false)$/ {print $1 "  (" $7 ")"}' /etc/passwd
echo ""

echo "=== Члены группы sudo ==="
getent group sudo | cut -d: -f4 | tr ',' '\n' | sed '/^$/d'
echo ""

echo "=== Учётные записи с ПУСТЫМ паролем (должно быть пусто!) ==="
EMPTY_PASS=$(awk -F: '($2 == "") {print $1}' /etc/shadow)
if [ -n "$EMPTY_PASS" ]; then
  echo "ВНИМАНИЕ, найдены:"
  echo "$EMPTY_PASS"
else
  echo "Нет — всё в порядке."
fi
echo ""

echo "=== Учётные записи с заблокированным паролем ==="
awk -F: '($2 ~ /^!/) {print $1}' /etc/shadow | paste -sd ', ' -
echo ""

echo "=== Готово! ==="
