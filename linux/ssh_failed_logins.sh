#!/bin/bash
# ==============================================================================
# ssh_failed_logins.sh — анализ неудачных попыток входа по SSH
# Показывает топ IP-адресов и имён пользователей из журнала аутентификации.
# Работает с journalctl (Ubuntu) и /var/log/auth.log.
# Требует прав root (sudo) для чтения журнала.
# ==============================================================================

set -euo pipefail

TOP_COUNT=10

if [ "$EUID" -ne 0 ]; then
  echo "Пожалуйста, запустите с sudo: sudo $0"
  exit 1
fi

# Источник журнала: journalctl, иначе auth.log
if command -v journalctl &>/dev/null && journalctl -u ssh --no-pager -q &>/dev/null; then
  LOG_SOURCE="journalctl -u ssh --no-pager -o cat"
elif [ -f /var/log/auth.log ]; then
  LOG_SOURCE="cat /var/log/auth.log"
else
  echo "Ошибка: не найден источник журнала SSH (ни journalctl, ни /var/log/auth.log)."
  exit 1
fi

FAILED_LINES=$($LOG_SOURCE | grep -i "failed password" || true)

if [ -z "$FAILED_LINES" ]; then
  echo "=== Неудачных попыток входа по SSH не зафиксировано ==="
  exit 0
fi

echo "=== Всего неудачных попыток: $(echo "$FAILED_LINES" | wc -l) ==="
echo ""

echo "=== Топ-${TOP_COUNT} IP-адресов атакующих ==="
echo "$FAILED_LINES" | grep -oE 'from [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | awk '{print $2}' \
  | sort | uniq -c | sort -rn | head -n "$TOP_COUNT"
echo ""

echo "=== Топ-${TOP_COUNT} имён пользователей, под которые подбирали пароль ==="
echo "$FAILED_LINES" | grep -oE 'for (invalid user )?[a-zA-Z0-9._-]+ from' \
  | sed -E 's/^for (invalid user )?//; s/ from$//' \
  | sort | uniq -c | sort -rn | head -n "$TOP_COUNT"
echo ""

echo "=== Рекомендация ==="
echo "Рассмотрите установку fail2ban или ограничение доступа по UFW: sudo ufw limit ssh"
