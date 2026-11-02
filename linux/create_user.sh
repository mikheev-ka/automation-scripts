#!/bin/bash
# ==============================================================================
# create_user.sh — создание пользователя с правами sudo и SSH-ключом
# Использование:
#   sudo ./create_user.sh <username> [путь_к_публичному_ключу.pub]
# Примеры:
#   sudo ./create_user.sh ivan
#   sudo ./create_user.sh ivan ~/.ssh/id_ed25519.pub
# ==============================================================================

set -euo pipefail

if [ "$EUID" -ne 0 ]; then
  echo "Пожалуйста, запустите с sudo: sudo $0 <username> [ключ.pub]"
  exit 1
fi

USERNAME="${1:-}"
PUBKEY_FILE="${2:-}"

if [ -z "$USERNAME" ]; then
  echo "Использование: sudo $0 <username> [путь_к_публичному_ключу.pub]"
  exit 1
fi

if id "$USERNAME" &>/dev/null; then
  echo "Ошибка: пользователь '$USERNAME' уже существует."
  exit 1
fi

echo "=== Создание пользователя '$USERNAME' ==="
useradd -m -s /bin/bash "$USERNAME"

echo "=== Добавление в группу sudo ==="
usermod -aG sudo "$USERNAME"

echo "=== Установка пароля ==="
passwd "$USERNAME"

if [ -n "$PUBKEY_FILE" ]; then
  if [ ! -f "$PUBKEY_FILE" ]; then
    echo "Ошибка: файл ключа '$PUBKEY_FILE' не найден."
    exit 1
  fi
  echo "=== Установка SSH-ключа ==="
  SSH_DIR="/home/${USERNAME}/.ssh"
  mkdir -p "$SSH_DIR"
  cat "$PUBKEY_FILE" >> "${SSH_DIR}/authorized_keys"
  chmod 700 "$SSH_DIR"
  chmod 600 "${SSH_DIR}/authorized_keys"
  chown -R "${USERNAME}:${USERNAME}" "$SSH_DIR"
  echo "SSH-ключ установлен."
fi

echo "=== Готово! Пользователь '$USERNAME' создан ==="
