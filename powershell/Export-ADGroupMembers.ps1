<#
.SYNOPSIS
    Export-ADGroupMembers.ps1 — выгрузка членов группы AD с разделением на активные и отключённые учётные записи.
.DESCRIPTION
    Выгружает членов указанной группы Active Directory и формирует CSV-отчёт,
    отсортированный по статусу учётной записи: сначала активные (Enabled),
    затем отключённые/заблокированные (Disabled).
    Требуется модуль ActiveDirectory (RSAT или контроллер домена).
.PARAMETER GroupName
    Имя группы AD (например, "Domain Admins" или "VPN-Users").
.PARAMETER OutputPath
    Путь к итоговому CSV-файлу. По умолчанию — <ИмяГруппы>_members_YYYY-MM-DD.csv рядом со скриптом.
.EXAMPLE
    .\Export-ADGroupMembers.ps1 -GroupName "Domain Admins"
    .\Export-ADGroupMembers.ps1 -GroupName "VPN-Users" -OutputPath C:\Reports\vpn_users.csv
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$GroupName,

    [string]$OutputPath = ".\$($GroupName -replace '[^\w\-]', '_')_members_$(Get-Date -Format 'yyyy-MM-dd').csv"
)

Import-Module ActiveDirectory -ErrorAction Stop

if (-not (Get-ADGroup -Filter "Name -eq '$GroupName'" -ErrorAction SilentlyContinue)) {
    Write-Error "Группа '$GroupName' не найдена в домене."
    exit 1
}

Write-Host "=== Выгрузка членов группы '$GroupName' ===" -ForegroundColor Cyan

$members = Get-ADGroupMember -Identity $GroupName -Recursive |
    Where-Object { $_.objectClass -eq 'user' } |
    Get-ADUser -Properties DisplayName, Enabled, LastLogonDate, PasswordLastSet |
    Sort-Object -Property Enabled, DisplayName -Descending

$report = $members | Select-Object `
    @{Name = 'Учётная запись'; Expression = { $_.SamAccountName } },
    @{Name = 'ФИО'; Expression = { $_.DisplayName } },
    @{Name = 'Статус'; Expression = { if ($_.Enabled) { 'Активна' } else { 'Отключена' } } },
    @{Name = 'Последний вход'; Expression = { $_.LastLogonDate } },
    @{Name = 'Пароль изменён'; Expression = { $_.PasswordLastSet } }

$report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

$enabledCount  = ($members | Where-Object Enabled).Count
$disabledCount = ($members | Where-Object { -not $_.Enabled }).Count

Write-Host ""
Write-Host "=== Сводка ===" -ForegroundColor Cyan
Write-Host "Всего членов:   $($members.Count)"
Write-Host "Активных:       $enabledCount" -ForegroundColor Green
Write-Host "Отключённых:    $disabledCount" -ForegroundColor $(if ($disabledCount -gt 0) { 'Yellow' } else { 'Green' })
Write-Host ""
Write-Host "Отчёт сохранён: $OutputPath"

if ($disabledCount -gt 0) {
    Write-Host ""
    Write-Host "=== Отключённые учётные записи в группе ===" -ForegroundColor Yellow
    $report | Where-Object { $_.Статус -eq 'Отключена' } | Format-Table -AutoSize
}
