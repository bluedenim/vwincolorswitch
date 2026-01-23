param (
  [string]$restartExplorer = "False"
)
$shouldRestartExplorer = ($restartExplorer -eq "True")

$appName = "vwincolorswitch"

$here = $PSScriptRoot
. "$here\Shared.ps1"

$logFile = Set-LogFile "SetThemeNow.txt" -appName $appName

$cachedTimes = Get-SunTimesFromCache -maxAgeDays 2 -logFile $logFile -appName $appName

if ($cachedTimes) {
    $sunrise = [DateTime]::Parse($cachedTimes.sunrise)
    $sunset  = [DateTime]::Parse($cachedTimes.sunset)
} else {
    Write-Log "No times cached. Fetching times..." -logFile $logFile 
    $cached = Get-CachedData -logFile $logFile -appname $appName
    if ($cached) {
        Write-Log "Refreshing cache..." -logFile $logFile 
        $lat = $cached.latitude
        $lng = $cached.longitude
        $sunTimes = Get-SunTimes -latitude $lat -longitude $lng -logFile $logFile -appName $appName
        $sunrise = $sunTimes.sunrise
        $sunset  = $sunTimes.sunset
        Save-SunTimesToCache -sunrise $sunrise -sunset $sunset -latitude $lat -longitude $lng -appName $appName

    } else {
        Write-Log "No times cached. Run install.cmd first" -logFile $logFile
        exit 1
    }
}

$now = (Get-Date).TimeOfDay
$sunriseTOD = $sunrise.TimeOfDay
$sunsetTOD = $sunset.TimeOfDay
$setThemeLight = "$here\SetThemeLight.ps1"

if (($now -lt $sunriseTOD) -or ($now -gt $sunsetTOD)) {
    # Before sunrise or after sunset
    & $setThemeLight -light False -restartExplorer $shouldRestartExplorer
} else {
    & $setThemeLight -light True -restartExplorer $shouldRestartExplorer
}

