'Wrapper to fully hide a powershell window. 
Dim shell,command,scriptString
scriptString = Replace(Wscript.ScriptFullName, Wscript.ScriptName, "Win7Client.ps1")
command = "powershell.exe -windowstyle hidden -file " & scriptString
Set shell = CreateObject("WScript.Shell")
shell.Run command,0
