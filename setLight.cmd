@echo off

if "%~1"=="" (
    echo Usage: setLight ^<True^|False^> [^<True^|False^>]
    echo   - 1st parameter indicates light ^(True^) or dark ^(False^) theme to use
    echo   - 2nd parameter indicates whether to restart Explorer ^(defaults to False^)
) else (
    cscript RunPowerShellWithArgs.vbs SetThemeLight.ps1 %*
) 

