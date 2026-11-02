<#
.SYNOPSIS
    New-ADUsersFromCsv.ps1 — массовое создание пользователей Active Directory из CSV-файла.
.DESCRIPTION
    Требуется роль AD DS и модуль ActiveDirectory (RSAT).
    Формат CSV (см. examples/users.csv.example):
        SamAccountName,GivenName,Surname,OU,Password
        ivanov,Ivan,Ivanov,"OU=Users,DC=lab,DC=local",P@ssw0rd!
    Пароли передаются только через CSV-файл — не храните его в репозитории
    (шаблон users.csv.example не содержит реальных данных).
.PARAMETER CsvPath
    Путь к CSV-файлу с пользователями.
.PARAMETER WhatIf
    Пробный запуск: показывает, что было бы создано, без изменений в AD.
.EXAMPLE
    .\New-ADUsersFromCsv.ps1 -CsvPath .\users.csv -WhatIf
    .\New-ADUsersFromCsv.ps1 -CsvPath .\users.csv
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath
)

if (-not (Test-Path $CsvPath)) {
    Write-Error "Файл '$CsvPath' не найден."
    exit 1
}

Import-Module ActiveDirectory -ErrorAction Stop

$users = Import-Csv -Path $CsvPath
$created = 0
$skipped = 0

foreach ($user in $users) {
    if (Get-ADUser -Filter "SamAccountName -eq '$($user.SamAccountName)'" -ErrorAction SilentlyContinue) {
        Write-Warning "Пользователь '$($user.SamAccountName)' уже существует — пропущен."
        $skipped++
        continue
    }

    if ($PSCmdlet.ShouldProcess($user.SamAccountName, "Создать пользователя AD")) {
        New-ADUser `
            -SamAccountName $user.SamAccountName `
            -GivenName $user.GivenName `
            -Surname $user.Surname `
            -Name "$($user.GivenName) $($user.Surname)" `
            -Path $user.OU `
            -AccountPassword ($user.Password | ConvertTo-SecureString -AsPlainText -Force) `
            -Enabled $true `
            -ChangePasswordAtLogon $true
        Write-Host "[ OK ] Создан: $($user.SamAccountName)" -ForegroundColor Green
        $created++
    }
}

Write-Host ""
Write-Host "=== Готово! Создано: $created, пропущено (уже существуют): $skipped ===" -ForegroundColor Cyan
