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
    $cached = Get-CachedData -logFile $logFile -appname $appname
    if ($cached) {
        $cachedDateTime = [DateTime]::Parse($cached.timestamp)
        $age = (Get-Date) - $cachedDateTime
        if ($age.TotalDays -lt $maxAgeDays) {
            Write-Log "Using cached sunrise/sunset data from $cachedDateTime" -logFile $logFile
            return $cached
        } else {
            Write-Log "Cached data is older than $maxAgeDays day(s). Ignoring." -logFile $logFile
        }
    }
    return $null
}

function Get-CachedData {
    param (
        [string]$logFile,
        [string]$appname = $defaultAppName
    )
    $appDataDir = Get-AppDataDir $appname
    $cacheFile = Join-Path $appDataDir $cacheFileName
    if (Test-Path $cacheFile) {
        try {
            $cached = Get-Content $cacheFile | ConvertFrom-Json
            return $cached
        } catch {
            Write-Log "Error reading cache file: $_" -logFile $logFile
        }
    } else {
        Write-Log "Cache file not found: $cacheFile" -logFile $logFile
    }
    return $null        
}

function Get-SunTimes {
    param (
        [string]$latitude,
        [string]$longitude,
        [string]$logFile,
        [string]$appname = $defaultAppName
    )
    $sunTimesUrl = "https://api.sunrise-sunset.org/json?lat=$latitude&lng=$longitude&formatted=0&tzid=utc"
    Write-Log "Fetching sunrise/sunset times from $sunTimesUrl..." -logFile $logFile
    $response = Invoke-RestMethod -Uri $sunTimesUrl
    $sunrise = [DateTime]::Parse($response.results.sunrise)
    $sunset  = [DateTime]::Parse($response.results.sunset)

    return @{
        sunrise = $sunrise
        sunset  = $sunset
    }
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

    Write-Log "Saving sunrise/sunset times to cache $cacheFile..." -logFile $logFile

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
