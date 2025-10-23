param (
  [string]$restartExplorer = "False"
)
$shouldRestartExplorer = ($restartExplorer -eq "True")

$appName = "vwincolorswitch"

$here = $PSScriptRoot
. "$here\Shared.ps1"

$logFile = Set-LogFile "SetThemeNow.txt" -appName $appName

$cachedTimes = Get-SunTimesFromCache -maxAgeDays 7 -logFile $logFile -appName $appName

if ($cachedTimes) {
    $sunrise = [DateTime]::Parse($cachedTimes.sunrise)
    $sunset  = [DateTime]::Parse($cachedTimes.sunset)

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
} else {
    Write-Log "No times cached. Run install.cmd first" -logFile $logFile 
}
