# -------------------------------------------------------------------------
# Author: SRG SSR - INIT - Workplace Service - James Levell
# Date: 2018-10-25
# Version: 2.0
# Comment: functions which are used to collect data
# History:	R1	2015-02-18	Levell James	Initial Build
#			R2	2015-29-12	Levell James	Changed the order of the code
#           R5  2018-10-25  Levell James    Adapted for Windows 10
# --------------------------------------------------------------------------

# --------------------------------------------------------------------------
#	Base Client Queury
# --------------------------------------------------------------------------

$domain = "domain"

Function Get-AdUserDN
{
	#Gets the User DN from the Ad
	
	#check if ad is present
	if(Test-Connection $domain)
	{
		#ad is present
		#query ad
		$currentUser = (whoami).split("\")[1]
		$Searcher = New-Object DirectoryServices.DirectorySearcher
		$Searcher.Filter = '(&(objectCategory=person)(cn=' + $currentUser + '))'
		$Searcher.SearchRoot = 'LDAP://OU=Units,DC=media,DC=int'
		$User = $Searcher.FindOne()
		
		#format Output
		$Output = "UserDN: " + $User.Properties.distinguishedname
		echo $Output
	}
	else
	{
		#ad not present
		echo "User DN: The AD couldn't be contacted"
	}
}

Function Get-ADClientDN
{
	#Gets the Client DN from the Ad
	
	#check if ad is present
	if(Test-Connection $domain)
	{
		#ad is present
		#query ad
		$Searcher = New-Object DirectoryServices.DirectorySearcher
		$Hostname = (Hostname)
		$Searcher.Filter = '(&(objectCategory=computer)(cn=' + $hostname + '))'
		$Searcher.SearchRoot = 'LDAP://OU=Units,DC=media,DC=int'
		$Client = $Searcher.FindOne()
		
		#format Output
		$Output = "ClientDn: " + $Client.Properties.distinguishedname
		echo $Output
	}
	else
	{
		#ad not present
		echo "Client DN: The AD couldn't be contacted"
	}
}

Function Get-LogonServer
{
	#gets the current logon server
	#query variable: 
 	$LogonServer = $env:LOGONSERVER -replace “\\”, “”
	echo "LogonServer: $LogonServer"
	
}

Function Get-DomainSite
{
	#get domain site of the client
	
	#query registry key
	$key = "HKLM:\SYSTEM\CurrentControlSet\services\Netlogon\Parameters"
	$DomainSite = (Get-ItemProperty $key DynamicSiteName).DynamicSiteName
	
	#generate output
	echo "AD Site: $DomainSite"
}

Function Get-AdvancedAdInfo
{
	#get advanced info for the client
	Get-WmiObject -Class win32_ntdomain -Filter "DomainName = 'media'"	
}

Function Check-SidHistory
{
	#Gets the User DN from the Ad
	
	#check if ad is present
	if(Test-Connection $domain)
	{
		#ad is present
		#query ad
		$currentUser = (whoami).split("\")[1]
		$Searcher = New-Object DirectoryServices.DirectorySearcher
		$Searcher.Filter = '(&(objectCategory=person)(cn=' + $currentUser + '))'
		$Searcher.SearchRoot = 'LDAP://OU=Units,DC=media,DC=int'
		$User = $Searcher.FindOne()
		
		#check if sid history present
		if($User.Properties.sidhistory)
		{
			echo "Sid History for User: Sid History found"
		}
		else
		{
			echo "Sid History for User: NO Sid History found"
		}
	}
	else
	{
		#ad not present
		echo "Sid History: The AD couldn't be contacted"
	}
}

Function Check-CorrectShutdown
{
	#checks if the client was correctly shuted
	
	#get evemt log
	echo "Client has been forcefully shutdown at the following dates:"
	Get-EventLog -LogName System -ErrorAction SilentlyContinue | Where-Object { $_.EventID -eq "6008" } | Select-Object TimeGenerated, Message -First 5 | Format-Table
}

Function Check-AdBind
{
   	if(Test-Connection $domain)
	{
        #check if ad bind ok
        echo "Check if ad bind still ok"
        $hostname = (hostname)
        nltest.exe /server:$hostname /sc_query:media.int

        #show kerberos tickets
        echo ""
        echo ""
        echo ""
        echo "Check all kerberos tickets"
        klist

        #check time
        echo ""
        echo ""
        echo ""
        echo "Check time differents"
        w32tm /stripchart /computer:mscs-zhfer-0001 /samples:2
    }
    else
    {
        echo "No Domain controller found"
    }
}

Function Compare-UserRegPath
{
	#variable section
	New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS -ErrorAction SilentlyContinue | Out-Null
	$path = "HKU:\"

	#helper function
	Function Convert-SidToUsername
	{
		param
		(
			[parameter(Mandatory=$true)]
			[string]$Sid
		)
		
		try
		{
			$objSID = New-Object System.Security.Principal.SecurityIdentifier ($Sid)
			$objUser = $objSID.Translate( [System.Security.Principal.NTAccount])
			return $objUser.Value.Split("\")[1]
		}
		catch
		{
			return $false
		}
	}

	#get content
	$ListRegUsers= New-Object PSObject
	$ListRegUsers = Get-ChildItem $path | Select-Object Name | Sort-Object Name | Where-Object { $_.Name -notlike "*.DEFAULT" -and $_.Name -notlike "*_Classes" }
	$ListRegUsers | Add-Member NoteProperty ReadbleUsername $null
	$ListRegUsers | Add-Member NoteProperty Found $false
	
	$ListPathUsers= New-Object PSObject
	$ListPathUsers = Get-ChildItem C:\Users | Sort-Object Name | Select-Object Name
	$ListPathUsers | Add-Member NoteProperty Found $false

	#compare the two objects
	for($a=0;$a -le $ListRegUsers.Length;$a++)
	{
		#convert sid to username 
		if($ListRegUsers[$a])
		{
			$ListRegUsers[$a].ReadbleUsername = Convert-SidToUsername -sid ($ListRegUsers[$a].Name.Split("\")[1])

			for($b=0;$b -le $ListPathUsers.Length;$b++)
			{
				if($ListRegUsers[$a].ReadbleUsername -like $ListPathUsers[$b].Name)
				{
					$ListRegUsers[$a].Found = $true
					$ListPathUsers[$b].Found = $true
				}
			}
		}
	}

	#generate output
	$output = $ListRegUsers | Where-Object { $_.Found -eq $false -and $_.ReadbleUsername -notlike "SYSTEM" -and $_.ReadbleUsername -notlike "LOKALER DIENST" -and $_.ReadbleUsername -notlike "NETZWERKDIENST" } | Format-Table -AutoSize
	if($output)
	{
		echo "Warning: The following orphan registry keys were found. They do not have a path at C:\Users"
		echo $output | Format-Table -AutoSize | Out-String -Width 4096
	}
	else
	{
		Write-Host "Info: No orphan registry keys were found"
	}

	$Output = $ListPathUsers | Where-Object { $_.Found -eq $false -and $_.Name -notlike "Administrator" -and $_.Name -notlike "Public" } | Format-Table -AutoSize
	if($output)
	{
		echo "Warning: The following orphan paths were found. They do not have a registry path at HKU:\" 
		echo $output | Format-Table -AutoSize | Out-String -Width 4096
	}
	else
	{
		Write-Host "Info: No orphan path were found"
	}
}

Function GetBasicInfos
{
	#Get the Basic Infos of the Client as Hostname, Current User, all Administrots, LastLogon Times, 
	#Call Function "GetBasicInfos"
	
	#Get Hostname
	$Hostname = (Hostname)
	echo "Hostname: $Hostname"
	Get-ADClientDN
	echo "-------------------------------------------------------------------------------"
    echo ""

	#Get Current User
	$CurrentUser = (whoami)
	echo "CurrentUser: $CurrentUser"
	Get-AdUserDN
	echo "-------------------------------------------------------------------------------"
	echo ""

	#get advanced ad infos
	echo "Advanced AD Infos:"
	Get-LogonServer
	Get-DomainSite
	Check-SidHistory
	Get-AdvancedAdInfo
    Check-AdBind
	echo "-------------------------------------------------------------------------------"
	echo ""

	#get when the client has been forced switch offline
	echo "Force quite of the computer:"
	Check-CorrectShutdown
	echo "-------------------------------------------------------------------------------"
	echo ""

	#compare the user registry with the c:\users
	echo "Check the difference between user registry and c:\users:"
	Compare-UserRegPath
	echo "-------------------------------------------------------------------------------"
	echo ""
		
	#Get All Users on Client
	$Users = (Get-Childitem C:\Users)
	echo "Vorhandene Userprofile:"
	Foreach ($User in $Users)
	{
		echo "Userprofile: $User"
	}
	echo "-------------------------------------------------------------------------------"
    echo ""
    	
	#Get All Mitglieder der Administratorsgruppe
	$Admins = Get-LocalGroupMember -Name Administrators | Select-Object Name
	echo "Member der lokalen Adminstratoren: "
	echo $Admins
	echo "-------------------------------------------------------------------------------"
	echo ""

	#Get Last Login of users
	$LastLogins = Get-WmiObject -class Win32_NetworkLoginProfile | Where {($_.NumberOfLogons -gt 0) -and ($_.NumberOfLogons -lt 65535)} | Select-Object  Name,@{label='LastLogon';expression={$_.ConvertToDateTime($_.LastLogon)}}
	echo "Last Login Time:"
	Foreach ($LastLogin in $LastLogins)
	{
		$Output = "LogonTime Username: " + $LastLogin.Name + " LastLogon: " + $LastLogin.LastLogon
		echo $Output
	}
	echo "-------------------------------------------------------------------------------"
    echo ""
}

# --------------------------------------------------------------------------
#	Hardware Queury
# --------------------------------------------------------------------------

Function GetHardwareInfos
{
	#Get Hardware Infos Model and Bios
	#Based on: https://technet.microsoft.com/de-ch/library/dd315240.aspx
	#Call Function: "GetHardwareInfos"
	
	#Get Hardwaremodel
	echo "Model information:"
	$Hardwaremodel = (Get-WmiObject -Class Win32_ComputerSystem | Select-Object Manufacturer, Model | Format-List)
	echo $Hardwaremodel
	echo "-------------------------------------------------------------------------------"
	
    #Get BIOS Version
	echo "BIOS information:"
	$BIOS = (Get-WmiObject -Class Win32_BIOS | Format-List)
	echo $BIOS
	echo "-------------------------------------------------------------------------------"
    echo ""
}                
 
# --------------------------------------------------------------------------
#	Network Queury
# --------------------------------------------------------------------------
Function Check-NicConfiguration
{
    [CmdletBinding()]
    param
    (    
        [string]$computer="."
    )

    BEGIN 
    {
     $HKLM = 2147483650
     $reg = [wmiclass]"\\$computer\root\default:StdRegprov"
     $keyroot = "SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}"
    }
           
    PROCESS
    {            
        Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $computer -Filter "IPEnabled='$true'" |
            foreach {            
                $data = $_.Caption -split "]"
                $suffix = $data[0].Substring(($data[0].length-4),4)
                $key = $keyroot + "\$suffix"

                $value = "*PhysicalMediaType"
                $pmt = $reg.GetDwordValue($HKLM, $key, $value)  ## REG_DWORD
                
                # 0=Unspecified, 9=Wireless, 14=Ethernet
                if ($pmt.uValue -eq 14)
                {
                    $nic = $_.GetRelated("Win32_NetworkAdapter") | select Speed, NetConnectionId            
                    $value = "*SpeedDuplex"
                    $dup = $reg.GetStringValue($HKLM, $key, $value)  ## REG_SZ
                    
                    switch ($dup.sValue) 
                    {
                        "0" {$duplex = "Auto Detect"}
                        "1" {$duplex = "10Mbps \ Half Duplex"}
                        "2" {$duplex = "10Mbps \ Full Duplex"}
                        "3" {$duplex = "100Mbps \ Half Duplex"}
                        "4" {$duplex = "100Mbps \ Full Duplex"}
                    }

                    #genereate output
                    
                    [string]$speed = $($nic.Speed)/1000/1000
                    $speed += " MBits/s"

                    New-Object -TypeName PSObject -Property @{
                        NetworkConnector = $($nic.NetConnectionID )
                        DuplexSetting = $duplex
                        Speed = $speed
                    }
                }
            }
    } #process            
}

Function GetNetwork
{
	#Get Basic Network configuration as Ping media and proxy, tracert, ipconfig /all
	#Call Function: "GetNetwork"
	
	echo "Network penetration test:"
	#Ping media.int
	echo "Ping media.int"
	Invoke-Command -Scriptblock { & ping.exe media.int }
	echo "-------------------------------------------------------------------------------"
    echo ""
	
	#tracert proxy.media.int
	echo "tracert proxy.media.int max hops 7"
	Invoke-Command -Scriptblock { & tracert -h 5 proxy.media.int }
	echo "-------------------------------------------------------------------------------"
	echo ""

	#tracert google.com
	echo "tracert google.com max hops 7"
	Invoke-Command -Scriptblock { & tracert -h 5 google.com }
	echo "-------------------------------------------------------------------------------"
    echo ""
    	
    #Check Nic Configuration
    echo "nic configuration:"
    Check-NicConfiguration	
    echo "-------------------------------------------------------------------------------"
    echo ""

    #ipconfig /all
	echo "ipconfig /all:"
	Invoke-Command -Scriptblock { & ipconfig /all }
	echo "-------------------------------------------------------------------------------"
}

# --------------------------------------------------------------------------
#	Printer Queury
# --------------------------------------------------------------------------

Function GetAllPrinters 
{
	#Gets all connected Printers, and get default printer
	
	#used wmi query to get all printer
	echo "connected printer:"
	$AllPrinters = Get-WMIObject Win32_Printer | Select-Object Name, Location, Default
	$AllPrinters | Sort-Object Name | Select-Object Name, Location | Format-Table -AutoSize | Out-String -Width 4096
	
	#Get Default Printer
	$DefaultPrinter = $AllPrinters | where {$_.Default -eq $true}
	$DefaultPrinter = $DefaultPrinter.Name
	
	#Output
	echo "Default Printer is $DefaultPrinter"
    echo "-------------------------------------------------------------------------------"
	echo ""
}

# --------------------------------------------------------------------------
#	Networkdrives
# --------------------------------------------------------------------------

Function GetAllDrives 
{
	#Gets all drives
	
	#used wmi query to get all drives
	echo "connected network and local drives:"
	$AllDrives = Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, ProviderName, Size, FreeSpace 
	$AllDrives | Sort-Object DeviceID | Format-Table -AutoSize | Out-String -Width 4096
}

# --------------------------------------------------------------------------
#	Installed Software
# --------------------------------------------------------------------------

Function GetAllSoftware 
{
	#Gets all installed Software from the Client
	
	#used wmi query, the query has to be stored in a variable first
	$AllSoftawre = Get-WmiObject -Class Win32_Product | Select-Object -Property Name, Version
	$AllSoftawre | Sort-Object Name | Format-Table -AutoSize | Out-String -Width 4096
}

# --------------------------------------------------------------------------
#	Export Logs
# --------------------------------------------------------------------------

Function ExportEventLog($ExportPath)
{	 
	#Export the event Log to File
	#$Export has to be a path wich ends with a \
	#Call Function: "ExportEventLog ("ExportPath")"
	
	$logSections = "Application","System" # Add Name of the Logfile (System, Application, etc)
	
	#Test if path is valid. Get Last Caracter to check if \ was provided
	$LastCharacter = $ExportPath.Length -1
	$LastCharacter = $ExportPath[$LastCharacter]
	if(Test-Path $ExportPath)
	{
		if($LastCharacter -eq "\")
		{
			#create one log file for every section
			foreach ($logSection in $logSections)
			{
				#exportFileName = NameOfSection + Date
				$exportFileName = $logSection + (get-date -f yyyyMMdd) + ".evt"
				
				#If ExportFile already exists delete stuff
				if(Test-Path $exportFileName)
				{
					Remove-Item -force $exportFileName
				}
			
				#start exporting
				$explortLog = Get-WmiObject Win32_NTEventlogFile | Where-Object {$_.logfilename -eq $logSection}
				$explortLog.backupeventlog($ExportPath + $exportFileName)
			}
		}
		else
		{
			#if no \ provided
			echo "Please specify the \ at the end of the path"
		}
	}
	else
	{
		#if no path provided
		echo "Not a valid path"
	}
	
	#Export GPO Windows and Columbus Log
	Copy-Item -Force -ErrorAction SilentlyContinue -Path C:\windows\BrainWare.log -Destination $ExportPath\BrainWare.log
	Copy-Item -Force -ErrorAction SilentlyContinue -Path C:\windows\WindowsUpdate.log -Destination $ExportPath\WindowsUpdate.log
	Copy-Item -Force -ErrorAction SilentlyContinue -Path C:\windows\debug\usermode\gpsvc.log -Destination $ExportPath\gpsvc.log
}

# --------------------------------------------------------------------------
#	GpResult
# --------------------------------------------------------------------------

Function GetGpResult ($ExportPath)
{
	#Do a gp result and store the html file in the $ExportPath
	
	#execute gpresult
	gpresult /h $ExportPath/gpresult.html /f	
}