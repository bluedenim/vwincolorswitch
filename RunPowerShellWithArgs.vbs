' VBScript: RunPowerShellWithArgs.vbs
Option Explicit

Dim shell, args, currentFolder, psScript, psArgs, i, windowMode

Set shell = CreateObject("WScript.Shell")
Set args = WScript.Arguments

If args.Count < 1 Then
    WScript.Echo "Usage: cscript RunPowerShellWithArgs.vbs <PowerShellScriptPath> [arg1 arg2 ...]"
    WScript.Quit 1
End If

currentFolder = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
' First argument is the PowerShell script
psScript = currentFolder & "\" & args(0)

' Build the remaining arguments string
psArgs = ""
For i = 1 To args.Count - 1
    psArgs = psArgs & " """ & args(i) & """"
Next

' Run PowerShell with passed arguments
windowMode = 0   ' use 1 to show console window when running (e.g. for debugging)
shell.Run "powershell.exe -ExecutionPolicy Bypass -File """ & psScript & """" & psArgs, windowMode, True
