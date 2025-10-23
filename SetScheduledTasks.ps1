# run by:
#   cd <here>
#   cscript .\RunPowerShellWithArgs.vbs SetScheduledTasks.ps1 [<latitude> <longitude>]

param (
  [string]$lat = "37.6945519",
  [string]$lng = "-122.0857432"
)

$appName = "vwincolorswitch"
$sunTimesUrl = "https://api.sunrise-sunset.org/json?lat=$lat&lng=$lng&formatted=0&tzid=utc"

$here = $PSScriptRoot

# Import shared functions
. "$here\Shared.ps1"

$logFile = Set-LogFile "SetScheduledTasks.txt" -appname $appName


function Set-ScheduledTaskWithTrigger {
    param (
        [string]$taskName,
        [string]$ps1ScriptName,
        [PSObject]$trigger,
        [string]$logFile,
        [string]$scriptArgs = ""
    )

    $taskPath = "\"
    $scriptPath = Join-Path -Path $here -ChildPath "RunPowerShellWithArgs.vbs"
    $fullArgs = "`"$scriptPath`" `"$ps1ScriptName`" $scriptArgs"   

    # Check if task exists
    $task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue    
    if (-not $task) {
        Write-Log "Task '$taskName' not found. Creating..." -logFile $logFile

        $action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument $fullArgs
        $principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive
        $task = New-ScheduledTask -Action $action -Trigger $trigger -Principal $principal 
    } else {
        Write-Log "Task '$taskName' already exists. Updating action..." -logFile $logFile
        $action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument $fullArgs
        $principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive

        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    # Register-ScheduledTask -TaskName $taskName -InputObject $task -Force
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal

    # This is the only way to set the Settings of a task. Attempts to use -Settings <settings> with 
    # New-ScheduledTask just fails silently.
    $task = Get-ScheduledTask -TaskName $taskName
    $task.Settings.ExecutionTimeLimit = "PT1H"  # ISO 8601 format for 1 hour
    $task.Settings.AllowHardTerminate = $true
    $task.Settings.StartWhenAvailable = $true
    $task | Set-ScheduledTask

    Write-Log "Task '$taskName' created/updated successfully." -logFile $logFile
    return $task
}

function Set-ScheduledDailyTask {
    param (
        [string]$taskName,
        [string]$ps1ScriptName,
        [DateTime]$when,
        [string]$logFile,
        [string]$scriptArgs = ""
    )
    Write-Log "Set-ScheduledDailyTask '$taskName' for script '$ps1ScriptName' at $when with args: $scriptArgs" -logFile $logFile
    $trigger = New-ScheduledTaskTrigger -Daily -At $when
    
    Set-ScheduledTaskWithTrigger -taskName $taskName -ps1ScriptName $ps1ScriptName -trigger $trigger -logFile $logFile -scriptArgs $scriptArgs
}

function Set-ScheduledHourlyTask {
    param (
        [string]$taskName,
        [string]$ps1ScriptName,
        [DateTime]$when,
        [string]$logFile,
        [string]$scriptArgs = ""
    )
    Write-Log "Set-ScheduledHourlyTask '$taskName' for script '$ps1ScriptName' at $when with args: $scriptArgs" -logFile $logFile
    $hourly = New-TimeSpan -Hours 1
    # Apparently the -Once is required 
    $trigger = New-ScheduledTaskTrigger -Once -At $when -RepetitionInterval $hourly
    
    Set-ScheduledTaskWithTrigger -taskName $taskName -ps1ScriptName $ps1ScriptName -trigger $trigger -logFile $logFile -scriptArgs $scriptArgs    
}

function Set-LogonTask {
    param (
        [string]$taskName,
        [string]$ps1ScriptName,
        [string]$logFile,
        [string]$scriptArgs = ""
    )
    Write-Log "Set-LogonTask '$taskName' for script '$ps1ScriptName' with args: $scriptArgs" -logFile $logFile

    $trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERNAME"
    Set-ScheduledTaskWithTrigger -taskName $taskName -ps1ScriptName $ps1ScriptName -trigger $trigger -logFile $logFile -scriptArgs $scriptArgs
}

# Try reading from cache
$cachedTimes = Get-SunTimesFromCache -maxAgeDays 2 -logFile $logFile -appName $appName

if ($cachedTimes) {
    $sunrise = [DateTime]::Parse($cachedTimes.sunrise)
    $sunset  = [DateTime]::Parse($cachedTimes.sunset)
} else {
    Write-Log "Fetching sunrise/sunset times from API..." -logFile $logFile 
    $response = Invoke-RestMethod -Uri $sunTimesUrl
    $sunrise = [DateTime]::Parse($response.results.sunrise)
    $sunset  = [DateTime]::Parse($response.results.sunset)
    Save-SunTimesToCache -sunrise $sunrise -sunset $sunset -latitude $lat -longitude $lng -appName $appName
}

Write-Log "Sunrise: $sunrise. Sunset: $sunset" -logFile $logFile 
$Now = Get-Date
$sunriseFuture = Update-DateTimeToFuture $sunrise $Now
$sunsetFuture = Update-DateTimeToFuture $sunset $Now
Write-Log "Adjusted for future: Sunrise: $sunriseFuture. Sunset: $sunsetFuture" -logFile $logFile

Write-Log "Scheduling tasks..." -logFile $logFile
$timeSyncAt = [DateTime]::Today.AddHours(0).AddMinutes(0)
$timeSyncAt = Update-DateTimeToFuture $timeSyncAt $Now
Set-ScheduledDailyTask "$appName Sun Times Update" "SetScheduledTasks.ps1" $timeSyncAt -logFile $logFile
Set-LogonTask "$appName Theme set on logon" "SetThemeNow.ps1" -logFile $logFile -scriptArgs "-restartExplorer True"

# Sunrise and Sunset times to switch theme to light/dark
Set-ScheduledDailyTask "$appName Light" "SetThemeLight.ps1" $sunriseFuture -logFile $logFile -scriptArgs "-light true -restartExplorer True"
Set-ScheduledDailyTask "$appName Dark" "SetThemeLight.ps1" $sunsetFuture -logFile $logFile -scriptArgs "-light false -restartExplorer True"

# Empirical tests show that the tasks scheduled at sunrise and sunset times above don't get
# run reliably. Therefore, the following hourly task is added as a backup.
# Current hour but at 0:30. If that is earlier than now, then advance to next hour
$timeSyncAt = Get-Date -Year $Now.Year -Month $Now.Month -Day $Now.Day -Hour $Now.Hour -Minute 30 -Second 0
if ($timeSyncAt -le $Now) {
    $timeSyncAt = $timeSyncAt.AddHours(1)
}
Set-ScheduledHourlyTask "$appName Hourly Theme Sync" "SetThemeNow.ps1" $timeSyncAt -logFile $logFile -scriptArgs "-restartExplorer True"

# Finally, sync the theme now instead of waiting for any scheduled tasks.
& "$here\SetThemeNow.ps1"
