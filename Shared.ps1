$cacheFileName = "sun_times.json"

$defaultAppName = "Shared_ps1.txt"


function Get-AppDataDir {
    param (
        [string]$appname = $defaultAppName
    )
    New-Item -Path "$env:LOCALAPPDATA" -Name $appName -ItemType "Directory" -ErrorAction Ignore
    return Join-Path "$env:LOCALAPPDATA" $appName
}

function Set-LogFile {
    param (
        [string]$logFileName,
        [string]$appname = $defaultAppName,
        [boolean]$wipe = $true        
        )
    $appDataDir = Get-AppDataDir $appname
    $logFile = Join-Path $appDataDir $logFileName
    if ($wipe) {
        Clear-Content -Path $logFile -ErrorAction SilentlyContinue
    }
    return $logFile
}

function Write-Log {
    param (
        [string]$message,
        [string]$logFile
    )

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    "$timestamp | $message" | Out-File -FilePath $logFile -Append -Encoding utf8
}

function Get-SunTimesFromCache {
    param (
        [string]$logFile,
        [int]$maxAgeDays = 1,
        [string]$appname = $defaultAppName
    )
    $appDataDir = Get-AppDataDir $appname
    $cacheFile = Join-Path $appDataDir $cacheFileName

    if (Test-Path $cacheFile) {
        try {
            $cached = Get-Content $cacheFile | ConvertFrom-Json
            $cachedDateTime = [DateTime]::Parse($cached.timestamp)
            $age = (Get-Date) - $cachedDateTime
            if ($age.TotalDays -lt $maxAgeDays) {
                Write-Log "Using cached sunrise/sunset data from $cachedDateTime" -logFile $logFile
                return $cached
            } else {
                Write-Log "Cached data is older than $maxAgeDays day(s)." -logFile $logFile
            }
        } catch {
        }
    }
    return $null
}

function Save-SunTimesToCache {
    param (
        [DateTime]$sunrise,
        [DateTime]$sunset,
        [string]$latitude,
        [string]$longitude,
        [string]$appname = $defaultAppName        
    )

    $data = @{
        sunrise   = $sunrise.ToString("o")
        sunset    = $sunset.ToString("o")
        timestamp = (Get-Date).ToString("o")
        latitude  = $latitude
        longitude = $longitude
    }
    $appDataDir = Get-AppDataDir $appname
    $cacheFile = Join-Path $appDataDir $cacheFileName
    $data | ConvertTo-Json | Set-Content $cacheFile -Force
}

function Restart-Explorer {
    Stop-Process -Name explorer -Force 
}

function Update-DateTimeToFuture {
    param (
        [DateTime]$InputDateTime,
        [DateTime]$ReferenceDateTime
    )

    $NewDateTime = $InputDateTime
    if ($InputDateTime -le $ReferenceDateTime) {
        $newDate = if ($InputDateTime.Date -le $ReferenceDateTime.Date) {
            $ReferenceDateTime.Date.AddDays(1)
        } else {
            $ReferenceDateTime.Date
        }

        $NewDateTime = [DateTime]::new(
            $newDate.Year, $newDate.Month, $newDate.Day,
            $InputDateTime.Hour, $InputDateTime.Minute, $InputDateTime.Second
        )
    }

    return $NewDateTime
}
