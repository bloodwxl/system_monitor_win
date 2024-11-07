# ----- Моніторинг та перевірка стану системи -----

# Вивід інформації про користувачів системи
Write-Output "----- System Users -----"
Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount='True'" | ForEach-Object {
    $userName = $_.Name
    $status = $_.Status
    # Отримання груп, до яких належить користувач
    $groups = (Get-WmiObject -Query "ASSOCIATORS OF {Win32_UserAccount.Domain='$($_.Domain)',Name='$userName'} WHERE AssocClass=Win32_GroupUser Role=PartComponent" | Select-Object -ExpandProperty Name) -join ", "

    Write-Output "User: $userName"
    Write-Output " - Status: $status"
    Write-Output " - Groups: $groups"
}

# Перевірка запущених процесів користувачів
Write-Output "`n----- Processes Running by Each User -----"
Get-Process | ForEach-Object {
    try {
        # Отримання процесу та його власника через WMI
        $processId = $_.Id
        $wmiProcess = Get-WmiObject -Query "SELECT * FROM Win32_Process WHERE ProcessId=$processId"
        
        # Отримання інформації про власника процесу
        $ownerInfo = $wmiProcess.GetOwner()
        $procOwner = if ($ownerInfo.ReturnValue -eq 0) { 
            "$($ownerInfo.Domain)\$($ownerInfo.User)" 
        } else { 
            "Unknown" 
        }
        
        # Вивід інформації про процес
        Write-Output "Process: $($_.Name), PID: $processId, User: $procOwner, CPU: $([math]::Round($_.CPU, 2))%, Memory: $([math]::Round($_.WS / 1MB, 2)) MB"
    }
    catch {
        Write-Output "Process: $($_.Name), PID: $($_.Id), User: Unknown, CPU: $([math]::Round($_.CPU, 2))%, Memory: $([math]::Round($_.WS / 1MB, 2)) MB"
    }
}

# Вивід стану системи
Write-Output "`n----- System Status -----"
# Отримання інформації про диск
Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    Write-Output "Disk $($_.DeviceID): $([math]::Round($_.FreeSpace / 1GB, 2)) GB free of $([math]::Round($_.Size / 1GB, 2)) GB"
}

# Отримання інформації про пам'ять
$memory = Get-WmiObject -Class Win32_OperatingSystem
Write-Output "Memory: $([math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1MB, 2)) GB used of $([math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)) GB"

# Отримання інформації про час роботи системи
$uptime = (Get-Date) - ([Management.ManagementDateTimeConverter]::ToDateTime($memory.LastBootUpTime))
Write-Output "System Uptime: $([math]::Round($uptime.TotalDays, 2)) days"

