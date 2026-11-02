<#
.SYNOPSIS
    Get-InactiveADUsers.ps1 — поиск неактивных («спящих») учётных записей AD.
.DESCRIPTION
    Находит включённые учётные записи, в которые не выполнялся вход
    дольше заданного числа дней (или которые никогда не использовались).
    Только отчёт — ничего не отключает.
.PARAMETER InactiveDays
    Порог неактивности в днях (по умолчанию 90).
.PARAMETER OutputPath
    Если указан — результат дополнительно сохраняется в CSV.
.EXAMPLE
    .\Get-InactiveADUsers.ps1
    .\Get-InactiveADUsers.ps1 -InactiveDays 30 -OutputPath .\inactive_users.csv
#>
[CmdletBinding()]
param(
    [int]$InactiveDays = 90,

    [string]$OutputPath
)

Import-Module ActiveDirectory -ErrorAction Stop

$cutoffDate = (Get-Date).AddDays(-$InactiveDays)

$inactiveUsers = Get-ADUser -Filter "Enabled -eq `$true" -Properties DisplayName, LastLogonDate |
    Where-Object { $null -eq $_.LastLogonDate -or $_.LastLogonDate -lt $cutoffDate } |
    Sort-Object LastLogonDate

$report = $inactiveUsers | Select-Object `
    SamAccountName,
    DisplayName,
    @{Name = 'Последний вход'; Expression = { if ($_.LastLogonDate) { $_.LastLogonDate } else { 'никогда' } } }

if (-not $report) {
    Write-Host "=== Неактивных учётных записей (>${InactiveDays} дн.) не найдено ===" -ForegroundColor Green
    exit 0
}

Write-Host "=== Учётные записи без входа более $InactiveDays дн. ($($report.Count)) ===" -ForegroundColor Yellow
$report | Format-Table -AutoSize

if ($OutputPath) {
    $report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Отчёт сохранён: $OutputPath" -ForegroundColor Cyan
}

Write-Host "Рекомендация: проверьте список и отключите (Disable-ADAccount) неиспользуемые записи." -ForegroundColor Cyan
