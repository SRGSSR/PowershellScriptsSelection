<#
.SYNOPSIS
    Gets the ou of the local client
.NOTES
    Author         : James Levell (Workplace Service Init)
    Copyright 2017 - JL - SRG SSR
.EXAMPLE
    Set-OSCComputerOU -whichOU 2
#>

#function
$scriptDir = Split-Path -parent $MyInvocation.MyCommand.Path
. $ScriptDir\functions.ps1

#configuration section
$domain = "contoso.local"

#main
if((Test-Connection -Computername $domain -count 1 -quiet) -eq $true)
{
	Write-Host "Company network reachable, showing full report"
	Write-Host "collecting computer information..."
	$computerOutput = New-Object -TypeName psobject -Property @{
		hostname = Get-ComputerName
		lastBootTime = Get-LastBootTime
		category = Get-ComputerCategory
		updateRing = Get-ComputerUpdateRing
		currentIP = Get-CurrentIP
		baseLines = Get-ComputerBaselines
		assignedApplication = Get-ComputerAssignedApplication
		installedAppVPackages = Get-AppVPackages
		manualSoftware = Get-ManualSoftware
		defenderStatus = Get-DefenderStatus
	}

	cls
	Write-Host "collecting user information..."
	$userOutput = New-Object -TypeName psobject -Property @{
		username = Get-UserSamAccountName
		updateRing = Get-UserUpdateRing
		isUserAdmin = Get-IsUserAdmin
		assignedApplication = Get-UserAssignedApplication
	}
}
else
{
	Write-Host "Company network NOT reachable, showing reduced report"
	Write-Host "collecting computer information..."
	$computerOutput = New-Object -TypeName psobject -Property @{
		hostname = Get-ComputerName
		lastBootTime = Get-LastBootTime
		category = ""
		updateRing = ""
		currentIP = Get-CurrentIP
		baseLines = ""
		assignedApplication = ""
		installedAppVPackages = Get-AppVPackages
		manualSoftware = Get-ManualSoftware
		defenderStatus = Get-DefenderStatus
	}

	cls
	Write-Host "collecting user information..."
	$userOutput = New-Object -TypeName psobject -Property @{
		username = Get-UserSamAccountName
		updateRing = ""
		isUserAdmin = Get-IsUserAdmin
		assignedApplication = ""
	}
}

cls
#Display
echo "##############################################"
echo "# Computer Information:" 
echo "##############################################"
$computerOutput | Select-Object hostname, lastBootTime, updateRing, Category | Format-List
echo "Computer assigned Software:"
$computerOutput | Select-Object -ExpandProperty assignedApplication | ForEach-Object { echo -$_ }
echo ""
echo "Installed Appv packages:"
$computerOutput | Select-Object -ExpandProperty installedAppVPackages
echo ""
echo "Computer manuel Software:"
$computerOutput | Select-Object -ExpandProperty manualSoftware | ForEach-Object { echo -$_ }
echo ""
echo "Assigned baselines:"
$computerOutput | Select-Object -ExpandProperty baseLines | ForEach-Object { echo -$_ }
echo ""
echo "Defender Status:"
$computerOutput | Select-Object -ExpandProperty defenderStatus
echo "Network configuration:"
$computerOutput | Select-Object -ExpandProperty currentIP | FT


echo "##############################################"
echo "# User Information:" 
echo "##############################################"
$userOutput | Select-Object username, updateRing, isUserAdmin | Format-List
echo "User assigned Software:"
$userOutput | Select-Object -ExpandProperty assignedApplication | ForEach-Object { echo -$_ }

pause