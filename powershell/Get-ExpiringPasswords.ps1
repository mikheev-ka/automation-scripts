<#
.SYNOPSIS
    Get-ExpiringPasswords.ps1 — пользователи с истекающими паролями.
.DESCRIPTION
    Показывает включённые учётные записи, у которых пароль истекает
    в ближайшие N дней, согласно доменной политике паролей.
    Удобно запускать заранее, чтобы предупредить пользователей.
.PARAMETER DaysAhead
    Горизонт проверки в днях (по умолчанию 14).
.EXAMPLE
    .\Get-ExpiringPasswords.ps1
    .\Get-ExpiringPasswords.ps1 -DaysAhead 7
#>
[CmdletBinding()]
param(
    [int]$DaysAhead = 14
)

Import-Module ActiveDirectory -ErrorAction Stop

$maxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge
if ($maxPasswordAge.TotalDays -eq 0) {
    Write-Host "=== В домене пароли не истекают (MaxPasswordAge = 0) ===" -ForegroundColor Green
    exit 0
}

$now = Get-Date

$expiringUsers = Get-ADUser -Filter "Enabled -eq `$true -and PasswordNeverExpires -eq `$false" `
    -Properties DisplayName, PasswordLastSet, msDS-UserPasswordExpiryTimeComputed |
    ForEach-Object {
        $expiryDate = $_.PasswordLastSet + $maxPasswordAge
        $daysLeft = ($expiryDate - $now).Days
        if ($daysLeft -le $DaysAhead) {
            [PSCustomObject]@{
                SamAccountName  = $_.SamAccountName
                DisplayName     = $_.DisplayName
                'Пароль истекает' = $expiryDate.ToString('yyyy-MM-dd')
                'Осталось дней'   = $daysLeft
            }
        }
    } | Sort-Object 'Осталось дней'

if (-not $expiringUsers) {
    Write-Host "=== Паролей, истекающих в ближайшие $DaysAhead дн., нет ===" -ForegroundColor Green
    exit 0
}

Write-Host "=== Пароли, истекающие в ближайшие $DaysAhead дн. ($($expiringUsers.Count)) ===" -ForegroundColor Yellow
$expiringUsers | Format-Table -AutoSize
