Set oShell = CreateObject ("Wscript.Shell") 
Dim strPowershellScript
Set fso = CreateObject("Scripting.FileSystemObject") 
CurrentDirectory = fso.GetParentFolderName(wscript.ScriptFullName) 
if WScript.Arguments.Count = 0 then
    executeScript = CurrentDirectory & "\main.ps1"
	strPowershellScript = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -File """ & executeScript & """"
else
	executeScript = CurrentDirectory & "\" & WScript.Arguments(0)
	strPowershellScript = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden -File """ & executeScript & """ -scriptPath """ & CurrentDirectory & """"
end if

'execute the script
oShell.Run strPowershellScript, 0, false
