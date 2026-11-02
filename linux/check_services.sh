#!/bin/bash
# ==============================================================================
# check_services.sh — проверка статуса ключевых systemd-сервисов
# Список сервисов задаётся в переменной SERVICES ниже или аргументами:
#   ./check_services.sh nginx mariadb prometheus
# Код возврата: 0 — все активны, 1 — есть неактивные.
# ==============================================================================

set -uo pipefail

# Сервисы по умолчанию (измените под свой сервер)
DEFAULT_SERVICES=(ssh ufw cron)

if [ "$#" -gt 0 ]; then
  SERVICES=("$@")
else
  SERVICES=("${DEFAULT_SERVICES[@]}")
fi

FAILED=0

for service in "${SERVICES[@]}"; do
  if systemctl is-active --quiet "$service"; then
    echo "[ OK ]    $service — активен"
  else
    echo "[ FAIL ]  $service — НЕ АКТИВЕН (статус: $(systemctl is-active "$service" 2>/dev/null || echo 'не найден'))"
    FAILED=1
  fi
done

exit "$FAILED"
