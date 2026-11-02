# scripts_automation

Коллекция универсальных скриптов автоматизации для повседневных задач системного администратора: обслуживание Linux-серверов (Ubuntu/Debian) и администрирование Windows / Active Directory.

> Узкоспециализированные установщики лабораторных стендов (Prometheus, Grafana, Nextcloud, Zabbix, настройка DC01) хранятся в своих репозиториях — здесь собираются только **переиспользуемые** скрипты, не привязанные к конкретному стенду.

## Структура каталога

| Каталог | Содержимое |
| :--- | :--- |
| `linux/` | Bash-скрипты для Ubuntu/Debian |
| `powershell/` | PowerShell-скрипты для Windows / Windows Server |
| `powershell/examples/` | Примеры входных данных (CSV-шаблоны без реальных данных) |

## Linux (bash)

| Скрипт | Назначение | Запуск |
| :--- | :--- | :--- |
| `system_update.sh` | Полное обновление системы, чистка кэша, проверка необходимости перезагрузки | `sudo ./system_update.sh` |
| `create_user.sh` | Создание пользователя с правами sudo и установкой SSH-ключа | `sudo ./create_user.sh ivan [ключ.pub]` |
| `backup_dir.sh` | Резервное копирование каталога в tar.gz с ротацией старых архивов | `sudo ./backup_dir.sh /var/www /opt/backups 14` |
| `disk_usage_report.sh` | Отчёт: разделы, inodes, самые большие каталоги | `./disk_usage_report.sh` |
| `check_services.sh` | Проверка статуса systemd-сервисов (код возврата 1, если что-то упало) | `./check_services.sh nginx mariadb` |
| `find_large_files.sh` | Поиск файлов крупнее N МБ в каталоге | `sudo ./find_large_files.sh /var 500 20` |
| `ssh_failed_logins.sh` | Анализ неудачных SSH-входов: топ IP и имён пользователей | `sudo ./ssh_failed_logins.sh` |
| `user_audit.sh` | Аудит учётных записей: login shell, sudo, пустые пароли | `sudo ./user_audit.sh` |
| `ssl_cert_expiry.sh` | Проверка срока действия SSL-сертификатов | `./ssl_cert_expiry.sh host:443 ...` |

## PowerShell

| Скрипт | Назначение | Запуск |
| :--- | :--- | :--- |
| `Get-SystemInfo.ps1` | Сводный отчёт: ОС, CPU, RAM, диски, сеть, аптайм | `.\Get-SystemInfo.ps1` |
| `New-ADUsersFromCsv.ps1` | Массовое создание пользователей AD из CSV | `.\New-ADUsersFromCsv.ps1 -CsvPath .\users.csv -WhatIf` |
| `Clear-TempFiles.ps1` | Очистка временных файлов старше N дней | `.\Clear-TempFiles.ps1 -OlderThanDays 14` |
| `Export-ADGroupMembers.ps1` | Выгрузка членов группы AD в CSV, разделение на активные/отключённые УЗ | `.\Export-ADGroupMembers.ps1 -GroupName "Domain Admins"` |
| `Get-LockedOutUsers.ps1` | Список заблокированных УЗ, опциональная разблокировка | `.\Get-LockedOutUsers.ps1 -Unlock -WhatIf` |
| `Get-InactiveADUsers.ps1` | «Спящие» учётные записи без входа более N дней | `.\Get-InactiveADUsers.ps1 -InactiveDays 90` |
| `Get-ExpiringPasswords.ps1` | Пользователи с паролями, истекающими в ближайшие N дней | `.\Get-ExpiringPasswords.ps1 -DaysAhead 14` |

Для PowerShell-скриптов с потенциально деструктивными действиями поддерживается параметр `-WhatIf` — сначала всегда делайте пробный запуск.

## Правила каталога

1. **Никаких секретов в коде.** Пароли, токены и ключи передаются через аргументы, переменные окружения или вводятся интерактивно. Файлы с реальными данными (например, `users.csv`) в репозиторий не коммитятся — коммитятся только шаблоны `*.example`.
2. **Именование:** `linux/` — `snake_case.sh`, `powershell/` — `Verb-Noun.ps1` по соглашениям PowerShell.
3. **Каждый скрипт начинается с заголовка:** назначение, использование, примеры.
4. **Bash-скрипты** используют `set -euo pipefail` и проверяют запуск от root там, где это нужно.
5. Перед коммитом bash-скриптам выставляйте право на исполнение: `chmod +x script.sh`.

## Быстрый старт

```bash
# Linux: скопировать скрипт на сервер и сделать исполняемым
chmod +x system_update.sh
sudo ./system_update.sh
```

```powershell
# Windows: разрешить выполнение локальных скриптов (один раз, от администратора)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\Get-SystemInfo.ps1
```
