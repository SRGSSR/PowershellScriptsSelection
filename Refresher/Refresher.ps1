<#
.SYNOPSIS
Updates all important client managing systems on the local client.
Script has to be executed with user permission

Affacted systems: 
- Defender
- GPO
- App-V
- SCCM

.NOTES
Created by Init Workplace Services James Levell
#>

#Function
Function Update-SCCM
{
    <#
    .SYNOPSIS
    Triggers the sccm refresh cycles and base line. This script has to be executed with user permissions. 

    .EXAMPLE
    Trigger sccm cycle
    Update-SCCM

    .NOTES
    Created by Init Workplace Services James Levell. Based on: https://blogs.technet.microsoft.com/charlesa_us/2015/03/07/triggering-configmgr-client-actions-with-wmic-without-pesky-right-click-tools/
    #>

    #Trigger refresh cycles
    #based on: https://itfordummies.net/2015/07/27/trigger-sccm-client-action-with-powershell/
    $SCCMClient = New-Object -COM 'CPApplet.CPAppletMgr'
	
	if($SCCMClient -ne $null)
	{
		$actions = $SCCMClient.GetClientActions()
		foreach($action in $actions)
		{
			try 
			{
				$action.PerformAction()	
			}

			catch 
			{
				Write-Host -BackgroundColor red "The sccm client could not be reached. Please reinstall the client"
			}
		}
	}
	else
	{
		Write-Error "the connection to the SCCM client could not be established. Please restart the client and wait several minutes."
	}

    #trigger baselines is not possible because admin permissions are needed
    #but the refresh cycles are handled in the deployment baseline
}

Function Trigger-AvailableSoftware
{
	<#
    .SYNOPSIS
	Triggers the software installation of the sccm client

    .EXAMPLE
    Trigger sccm software installation
    Trigger-AvailableSoftware

    .NOTES
    Created by Init Workplace Services James Levell. Based on: https://timmyit.com/2016/08/01/sccm-and-powershell-force-install-of-software-updates-thats-available-on-client-through-wmi/ 
	#>
	
	Start-Job -ScriptBlock { 
		Start-Sleep -Seconds (5*60); 
		$AppEvalState0 = "0"
		$AppEvalState1 = "1"
		$ApplicationClass = [WmiClass]"root\ccm\clientSDK:CCM_SoftwareUpdatesManager"
	 

		$Application = (Get-WmiObject -Namespace "root\ccm\clientSDK" -Class CCM_SoftwareUpdate | Where-Object { 
			$_.EvaluationState -like "*$($AppEvalState0)*" -or $_.EvaluationState -like "*$($AppEvalState1)*"
		})

		Invoke-WmiMethod -Class CCM_SoftwareUpdatesManager -Name InstallUpdates -ArgumentList (,$Application) -Namespace root\ccm\clientsdk | Out-Null
	}
 }

 Function Invoke-BLEvaluation
{
    <#
    .SYNOPSIS
	execute all baselines.

    .EXAMPLE
    Execute all baselines
    Invoke-BLEvaluation

    .NOTES
    Created by Init Workplace Services James Levell
	#>
    Start-Job -ScriptBlock { 
		Start-Sleep -Seconds (5*60); 
        $baselines = Get-WmiObject -Namespace root\ccm\dcm -Class SMS_DesiredConfiguration
     
        $baselines | ForEach-Object {
            ([wmiclass]"\\localhost\root\ccm\dcm:SMS_DesiredConfiguration").TriggerEvaluation($_.Name, $_.Version) 
        }
    }
}

#configuration section
$domain = "contoso.local"

#Main
if((Test-Connection -Computername $domain -count 1 -quiet) -eq $true)
{
	$steps = 4
	Write-Host "Please wait while your client is being refreshed. This can take some time..."
	Write-Host "Connection to company network, full refresh will be executed"
	
	#App-V Sync
	Write-Progress -Activity "Refreshing your client" -Status "Refreshing AppV packages..." -percentComplete (1/$steps*100)
	Get-AppvPublishingServer | Sync-AppvPublishingServer  | Out-Null

	#SCCM complete refresh
	Write-Progress -Activity "Refreshing your client" -Status "Refreshing SCCM..." -percentComplete (2/$steps*100)
	Update-SCCM | Out-Null
	Trigger-AvailableSoftware
    Invoke-BLEvaluation
	
	#Update Microsoft Defender
	Write-Progress -Activity "Refreshing your client" -Status "Refreshing Defender..." -percentComplete (3/$steps*100)
	&{Update-MpSignature -ErrorAction SilentlyContinue }

	#Execute GpUpdate
	Write-Progress -Activity "Refreshing your client" -Status "Refreshing policies..." -percentComplete (4/$steps*100)
	&{gpupdate}

	Write-Host "Update successfully finished"
	Start-Sleep -Seconds 5
}
else 
{
	$steps = 2
	Write-Host "Please wait while your client is being refreshed. This can take some time..."
	Write-Host "No connection to company network, only reduced refresh will be executed"
	
	#SCCM complete refresh
	Write-Progress -Activity "Refreshing your client" -Status "Refreshing SCCM..." -percentComplete (1/$steps*100)
	Update-SCCM | Out-Null
	Trigger-AvailableSoftware
	
	#Update Microsoft Defender
	Write-Progress -Activity "Refreshing your client" -Status "Refreshing Defender..." -percentComplete (2/$steps*100)
	&{Update-MpSignature -ErrorAction SilentlyContinue }

	Write-Host "Update successfully finished"
	Start-Sleep -Seconds 5
}