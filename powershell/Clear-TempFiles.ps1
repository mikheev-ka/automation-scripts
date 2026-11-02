<#
.SYNOPSIS
    Clear-TempFiles.ps1 — очистка временных файлов Windows.
.DESCRIPTION
    Удаляет содержимое каталогов %TEMP% пользователя и C:\Windows\Temp
    старше заданного числа дней. Файлы, занятые процессами, пропускаются.
.PARAMETER OlderThanDays
    Удалять файлы старше указанного числа дней (по умолчанию 7).
.PARAMETER WhatIf
    Пробный запуск: показывает, что было бы удалено, без фактического удаления.
.EXAMPLE
    .\Clear-TempFiles.ps1 -WhatIf
    .\Clear-TempFiles.ps1 -OlderThanDays 14
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [int]$OlderThanDays = 7
)

$tempPaths = @($env:TEMP, "$env:SystemRoot\Temp")
$cutoffDate = (Get-Date).AddDays(-$OlderThanDays)
$totalFreedMB = 0

foreach ($path in $tempPaths) {
    if (-not (Test-Path $path)) {
        Write-Warning "Каталог '$path' не найден — пропущен."
        continue
    }

    Write-Host "=== Очистка: $path (файлы старше $OlderThanDays дн.) ===" -ForegroundColor Cyan

    $oldItems = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoffDate }

    foreach ($item in $oldItems) {
        if ($PSCmdlet.ShouldProcess($item.FullName, "Удалить")) {
            try {
                $sizeMB = if (-not $item.PSIsContainer) { $item.Length / 1MB } else { 0 }
                Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction Stop
                $totalFreedMB += $sizeMB
            }
            catch {
                # Файл занят процессом или нет прав — пропускаем
                Write-Verbose "Пропущен (занят или нет доступа): $($item.FullName)"
            }
        }
    }
}

Write-Host ""
Write-Host ("=== Готово! Освобождено примерно: {0:N1} МБ ===" -f $totalFreedMB) -ForegroundColor Green
