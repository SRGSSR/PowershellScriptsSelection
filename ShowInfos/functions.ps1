<#
.SYNOPSIS
    Gets the ou of the local client
.NOTES
    Author         : James Levell (Workplace Service Init)
    Copyright 2019 - JL - SRG SSR
.EXAMPLE
    Set-OSCComputerOU -whichOU 2
#>
Function Get-ComputerName
{
    return hostname
}

Function Get-ComputerOU
{
	param(
		[int]$whichOU
	)

    $computername = Get-ComputerName
    $ldapFilter = "(&(objectCategory=Computer)(Name=$computername))"

    $direCtorySearcher = New-Object System.DirectoryServices.direCtorySearcher
    $DirectorySearcher.Filter = $ldapFilter
    $searchPath = $DirectorySearcher.FindOne()
    $dn = $searchPath.GetDirectoryEntry().DistinguishedName

    $ouName = ($dn.Split(","))[$whichOU]
    return $ouName.SubString($ouName.IndexOf("=")+1)
}

Function Get-ComputerGroups
{
    $computername = Get-ComputerName
    $ldapFilter = "(&(objectCategory=Computer)(Name=$computername))"

    $direCtorySearcher = New-Object System.DirectoryServices.direCtorySearcher
    $DirectorySearcher.Filter = $ldapFilter
    $searchPath = $DirectorySearcher.FindOne()
    
    $adGroups = $searchPath.Properties.memberof

    $export = @()
    foreach ($adGroup in $ADGroups)
    {
        $adGroup = $adGroup.split(",")[0].split("=")[1]
        $export += $adGroup 
    }

    return $export
}

Function Get-ComputerCategory
{
    $computername = Get-ComputerName

    return Get-ComputerOU -whichOU 2
}

Function Get-ComputerUpdateRing
{
    $computername = Get-ComputerName

    $updateRing = Get-ComputerOU -whichOU 1
    return $updateRing.split("_")[1]
}

Function Get-CurrentIP
{
    return Get-NetIPAddress | Select-Object IPAddress, InterfaceAlias | Sort-Object InterfaceAlias
}

Function Get-ComputerBaselines
{
    $baseLines = @()
    foreach ($adGroup in (Get-ComputerGroups))
    {
        if($adGroup -like "SRG-G-C-SCCM-Win10*")
        {
            $baseLines += $adGroup 
        }
    }

    return $baseLines | Sort-Object
}

Function Get-ComputerAssignedApplication
{
    $assignedSoftware = @()
    foreach ($adGroup in (Get-ComputerGroups))
    {
        if($adGroup -notlike "SRG-G-C-SCCM-Win10*" -and $adGroup -like "SRG-G-C-SCCM*")
        {
            $assignedSoftware += $adGroup 
        }
    }

    return $assignedSoftware | Sort-Object
}

Function Get-ManualSoftware
{
	$manualSoftwares = Get-ChildItem HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Manuell\ -ErrorAction SilentlyContinue
	
	$manualSoftwares | Foreach-Object { $_.Name.Split("\")[-1] }
}

Function Get-DefenderStatus
{
    Get-MpComputerStatus | Select-Object AMProductVersion, NISSignatureVersion, AntispywareSignatureLastUpdated, AntispywareEnabled, RealTimeProtectionEnabled | Format-List 
}

Function Get-LastBootTime
{
	$lastBootTime = Get-CimInstance -ClassName win32_operatingsystem | Select-Object lastbootuptime
	return $lastBootTime.lastbootuptime
}

##User
Function Get-UserSamAccountName
{
    return (whoami).split("\")[1]
}

Function Get-UserOU
{
	param(
		[int]$whichOU
	)

    $username = Get-UserSamAccountName
    $ldapFilter = "(&(objectCategory=Person)(sAMAccountName=$username))"

    $direCtorySearcher = New-Object System.DirectoryServices.direCtorySearcher
    $DirectorySearcher.Filter = $ldapFilter
    $searchPath = $DirectorySearcher.FindOne()
	
	if($searchPath)
	{
		$dn = $searchPath.GetDirectoryEntry().DistinguishedName
		$ouName = ($dn.Split(","))[$whichOU]
		return $ouName.SubString($ouName.IndexOf("=")+1)
	}
}

Function Get-UserGroups
{
	$export = @()
    $username = Get-UserSamAccountName
    $ldapFilter = "(&(objectCategory=Person)(sAMAccountName=$username))"

    $direCtorySearcher = New-Object System.DirectoryServices.direCtorySearcher
    $DirectorySearcher.Filter = $ldapFilter
    $searchPath = $DirectorySearcher.FindOne()
    
	if($searchPath)
	{
		$adGroups = $searchPath.Properties.memberof

		foreach ($adGroup in $ADGroups)
		{
			$adGroup = $adGroup.split(",")[0].split("=")[1]
			$export += $adGroup 
		}
	}
	
    return $export
}

Function Get-UserUpdateRing
{
    $username = Get-UserSamAccountName
    return Get-UserOu -whichOU 2
}

Function Get-IsUserAdmin
{
    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
    {
        return $false
    }
    else
    {
        return $true
    }
}

Function Get-UserAssignedApplication
{
    $assignedSoftware = @()
    foreach ($adGroup in (Get-UserGroups))
    {
        if($adGroup -like "SRG-G-U-APPV*")
        {
            $assignedSoftware += $adGroup 
        }
    }

    return $assignedSoftware | Sort-Object
}

Function Get-AppVPackages
{
	$appVPackages = Get-AppvClientPackage -all | Select-Object Name, PackageId
	return $appVPackages
}

#static variables
$greenCheck = @{
    Object = [Char]8730
    ForegroundColor = 'Green'
    NoNewLine = $true
}

$redCheck = @{
    Object = 'x'
    ForegroundColor = 'Red'
    NoNewLine = $true
}