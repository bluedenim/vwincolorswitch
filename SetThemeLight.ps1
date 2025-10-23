param (
  [string]$light = "True",
  [string]$restartExplorer = "False"
)

# run by:
#   cd <here>
#   cscript .\RunPowerShellWithArgs.vbs SetThemeLight.ps1 [<True|False> <True|False>]
#     first parameter is whether to use light theme or not
#     second parameter is whether to restart Explorer when switching themes

$appName = "vwincolorswitch"

$useLightTheme = ($light -eq "True")
# If $shouldRestartExplorer is true, update the taskbar at the cost of restarting explorer which can be disruptive.
$shouldRestartExplorer = ($restartExplorer -eq "True")

$here = $PSScriptRoot
. "$here\Shared.ps1"

$logFile = Set-LogFile "SetThemeLight.txt" -appName $appName

Write-Log "SetThemeLight called with light: $light, restartExplorer $restartExplorer" -logFile $logfile

# Read the current Windows theme setting
$themePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"

# Check if the registry key exists
if (!(Test-Path $themePath)) {
    Write-Log "Registry key does not exist. Creating it..." -logFile $logfile 
    New-Item -Path $themePath -Force
}
# Check if the properties exist and create them if missing
$properties = @("AppsUseLightTheme", "SystemUsesLightTheme")
foreach ($property in $properties) {
    try {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
            'PSUseDeclaredVarsMoreThanAssignments', '', Scope='Function', 
            Justification='Avoid printing out of the value to console'
        )]
        $unused = Get-ItemProperty -Path $themePath -Name $property -ErrorAction Stop | Select-Object -ExpandProperty $property
    } catch {
        Write-Log "Property '$property' does not exist. Creating it..." -logFile $logfile 
        New-ItemProperty -Path $themePath -Name $property -Value 1 -PropertyType DWord -Force
    }
}

$currentMode = Get-ItemProperty -Path $themePath -Name "SystemUsesLightTheme" | Select-Object -ExpandProperty SystemUsesLightTheme

# Determine the target mode based on time
$desiredMode = if ($useLightTheme) { 1 } else { 0 }

if ($currentMode -ne $desiredMode) {
    Write-Log "Updating light theme usage settings to $desiredMode" -logFile $logfile 
    Set-ItemProperty -Path $themePath -Name "AppsUseLightTheme" -Value $desiredMode -Force
    Set-ItemProperty -Path $themePath -Name "SystemUsesLightTheme" -Value $desiredMode -Force

    if ($shouldRestartExplorer) {
        # Restart Explorer to refresh taskbar UI
        Write-Log "Restarting Explorer to force update of task bar." -logFile $logfile 
        Restart-Explorer
    }
} else {
    Write-Log "$themePath`:SystemUsesLightTheme setting already at $currentMode. No change needed." -logFile $logfile 
}
