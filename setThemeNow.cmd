@echo off

:: Usage: setThemeNow.cmd <True|False>
::        use True to restart Explorer if theme is changed

cscript RunPowerShellWithArgs.vbs SetThemeNow.ps1 %* 
