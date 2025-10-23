@echo off

:: Usage: light <True|False>
::        use True to restart Explorer if theme is changed

cscript RunPowerShellWithArgs.vbs SetThemeLight.ps1 True %* 
