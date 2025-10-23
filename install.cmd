@echo off

if "%~1"=="" (
    echo Usage: install ^<latitude^> ^<longitude^>
    echo   - Use maps from Bing or Google to find your latitude and longitude.
    echo     For example: install 37.6945519 -122.0857432
) else (
    cscript RunPowerShellWithArgs.vbs SetScheduledTasks.ps1 %*
) 
