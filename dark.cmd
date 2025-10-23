@echo off

:: Usage: dark <True|False>
::        use True to restart Explorer if theme is changed

cscript RunPowerShellWithArgs.vbs SetThemeLight.ps1 False %* 
