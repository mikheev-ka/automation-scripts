#!/bin/bash
# ==============================================================================
# ssl_cert_expiry.sh — проверка срока действия SSL-сертификатов
# Использование:
#   ./ssl_cert_expiry.sh <host:port> [host:port ...]
#   ./ssl_cert_expiry.sh 192.168.200.31:443 example.com:443
# По умолчанию проверяет Nextcloud лаборатории (192.168.200.31:443).
# Код возврата: 0 — всё в порядке, 1 — есть истекающие/истёкшие сертификаты.
# ==============================================================================

set -uo pipefail

WARNING_DAYS=30

if [ "$#" -gt 0 ]; then
  TARGETS=("$@")
else
  TARGETS=("192.168.200.31:443")
fi

FAILED=0

for target in "${TARGETS[@]}"; do
  host="${target%%:*}"
  port="${target##*:}"

  expiry_date=$(echo | openssl s_client -connect "${host}:${port}" -servername "$host" 2>/dev/null \
    | openssl x509 -noout -enddate 2>/dev/null \
    | cut -d= -f2)

  if [ -z "$expiry_date" ]; then
    echo "[ FAIL ]  $target — не удалось получить сертификат"
    FAILED=1
    continue
  fi

  expiry_epoch=$(date -d "$expiry_date" +%s)
  now_epoch=$(date +%s)
  days_left=$(( (expiry_epoch - now_epoch) / 86400 ))

  if [ "$days_left" -lt 0 ]; then
    echo "[ FAIL ]  $target — сертификат ИСТЁК $((-days_left)) дн. назад ($expiry_date)"
    FAILED=1
  elif [ "$days_left" -le "$WARNING_DAYS" ]; then
    echo "[ WARN ]  $target — истекает через $days_left дн. ($expiry_date)"
    FAILED=1
  else
    echo "[ OK ]    $target — действителен ещё $days_left дн. (до $expiry_date)"
  fi
done

exit "$FAILED"
