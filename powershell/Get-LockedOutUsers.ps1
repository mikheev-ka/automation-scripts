<#
.SYNOPSIS
    Get-LockedOutUsers.ps1 — список заблокированных учётных записей AD (с опцией разблокировки).
.DESCRIPTION
    Находит все заблокированные (locked out) учётные записи в домене.
    По умолчанию только показывает список. С параметром -Unlock снимает блокировку
    (поддерживается -WhatIf для пробного запуска).
.PARAMETER Unlock
    Разблокировать найденные учётные записи.
.PARAMETER WhatIf
    Пробный запуск: показывает, что было бы разблокировано, без изменений.
.EXAMPLE
    .\Get-LockedOutUsers.ps1
    .\Get-LockedOutUsers.ps1 -Unlock -WhatIf
    .\Get-LockedOutUsers.ps1 -Unlock
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Unlock
)

Import-Module ActiveDirectory -ErrorAction Stop

$lockedUsers = Search-ADAccount -LockedOut -UsersOnly |
    Get-ADUser -Properties DisplayName, LockedOut, LockoutTime

if (-not $lockedUsers) {
    Write-Host "=== Заблокированных учётных записей нет ===" -ForegroundColor Green
    exit 0
}

Write-Host "=== Заблокированные учётные записи ($($lockedUsers.Count)) ===" -ForegroundColor Yellow
$lockedUsers |
    Select-Object SamAccountName, DisplayName, LockoutTime |
    Format-Table -AutoSize

if ($Unlock) {
    foreach ($user in $lockedUsers) {
        if ($PSCmdlet.ShouldProcess($user.SamAccountName, "Разблокировать учётную запись")) {
            Unlock-ADAccount -Identity $user.SamAccountName
            Write-Host "[ OK ] Разблокирована: $($user.SamAccountName)" -ForegroundColor Green
        }
    }
}
