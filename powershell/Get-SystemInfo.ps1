<#
.SYNOPSIS
    Get-SystemInfo.ps1 — сводный отчёт о системе Windows / Windows Server.
.DESCRIPTION
    Выводит информацию об ОС, процессоре, памяти, дисках, сетевых адаптерах
    и времени работы системы. Прав администратора не требует.
.EXAMPLE
    .\Get-SystemInfo.ps1
#>

Write-Host "=== Операционная система ===" -ForegroundColor Cyan
Get-CimInstance Win32_OperatingSystem |
    Select-Object Caption, Version, BuildNumber, OSArchitecture |
    Format-List

Write-Host "=== Процессор ===" -ForegroundColor Cyan
Get-CimInstance Win32_Processor |
    Select-Object Name, NumberOfCores, NumberOfLogicalProcessors |
    Format-List

Write-Host "=== Оперативная память ===" -ForegroundColor Cyan
$os = Get-CimInstance Win32_OperatingSystem
[PSCustomObject]@{
    'Всего (ГБ)'     = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    'Свободно (ГБ)'  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
} | Format-List

Write-Host "=== Логические диски ===" -ForegroundColor Cyan
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID,
        @{Name = 'Размер (ГБ)'; Expression = { [math]::Round($_.Size / 1GB, 2) } },
        @{Name = 'Свободно (ГБ)'; Expression = { [math]::Round($_.FreeSpace / 1GB, 2) } },
        @{Name = 'Занято (%)'; Expression = { [math]::Round((1 - $_.FreeSpace / $_.Size) * 100, 1) } } |
    Format-Table -AutoSize

Write-Host "=== Сетевые адаптеры (активные) ===" -ForegroundColor Cyan
Get-NetAdapter | Where-Object Status -eq 'Up' |
    Select-Object Name, InterfaceDescription, LinkSpeed, MacAddress |
    Format-Table -AutoSize

Write-Host "=== IP-адреса ===" -ForegroundColor Cyan
Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -notlike '169.254.*' -and $_.IPAddress -ne '127.0.0.1' } |
    Select-Object InterfaceAlias, IPAddress, PrefixLength |
    Format-Table -AutoSize

Write-Host "=== Время работы системы ===" -ForegroundColor Cyan
$uptime = (Get-Date) - $os.LastBootUpTime
"{0} дн. {1} ч. {2} мин." -f $uptime.Days, $uptime.Hours, $uptime.Minutes
