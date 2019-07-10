<#
.SYNOPSIS
Writes the current BitLocker Recovery password information to the AD.

.DESCRIPTION
Writes the current BitLocker Recovery password information to the AD. The information is get from the BitLocker CMDLet.
No requirements to use this Function.

.EXAMPLE
Write the current BitLocker Revocery password to AD
Update-SRGBitLockerKey

.NOTES
Created by INIT James Levell. Based on the cmdlets provided from microsoft.
https://technet.microsoft.com/en-us/library/jj649839(v=wps.630).aspx
#>
Function Update-SRGBitLockerKey
{
    $drive = Get-BitLockerVolume | Where-Object {$_.KeyProtector | Where-Object{$_.KeyProtectorType -eq 'RecoveryPassword'}} | select-Object -f 1
    $key = $drive | select-Object -exp KeyProtector | Where-Object {$_.KeyProtectorType -eq 'RecoveryPassword'} | Select-Object -f 1
    Backup-BitLockerKeyProtector $drive $key.KeyProtectorId
    Write-Host "Backing up drive $drive, key $($key.KeyProtectorId), password $($key.RecoveryPassword)"
}

<#
.SYNOPSIS
Sets a new BitLocker Recovery Password

.DESCRIPTION
Sets a new BitLocker Recovery password, triggered by an Event, when the key was used

.EXAMPLE
Reset the BitLocker Recovery Passsword of the Device, where the Script is executed
Reset-SRGBitLockerKey

.NOTES
Created by INIT James Levell. Based on the cmdlets provided from microsoft.
https://technet.microsoft.com/de-de/library/jj649835(v=wps.630).aspx
#>
Function Reset-SRGBitLockerKey
{
    #Get the Key Protector from the SystemDrive where the protector is set RecoveryPassword
    $BitLockerKeyProtector = (Get-BitLockerVolume -MountPoint $env:SystemDrive).KeyProtector | Where-Object { $_.KeyProtectorType -eq "RecoveryPassword" }

    #Remove the current KeyProtector
    Remove-BitLockerKeyProtector -MountPoint $env:SystemDrive -KeyProtectorId $BitLockerKeyProtector.KeyProtectorId

    #Set a new KeyProtector, which will write it automatically to AD
    Add-BitLockerKeyProtector -MountPoint $env:SystemDrive -RecoveryPasswordProtector -WarningAction SilentlyContinue

    #backup the key
    Update-SRGBitLockerKey
}

<#
.SYNOPSIS
Reads the System Event log for BitLocker Recovery Key Usage

.DESCRIPTION
Reads the System Event log for BitLocker Recovery Key Usage, if a event ID was found, that is relativ to the BitLocker Key Recovery, the Key will be renewed.

.EXAMPLE
Check if a Recovery Key was used wihtin last hour, and if so reset the BitLocker Recovery Passsword of the Device, where the Script is executed
Check-RecoveryKeyUsed

.NOTES
Created by INIT James Levell. Based on the cmdlets provided from microsoft.

#>
Function Check-RecoveryKeyUsed 
{
    #configuration
    $domain = "contoso.local"
    
    if ((Test-Connection -Computername $domain -count 1 -quiet) -eq $true)
    {
        #events which indicate that the key has been used to unlock a BitLocker encrypted disk
        $Events = Get-EventLog -LogName System -After (Get-Date).AddHours(-1) -InstanceId 24585,24587,24589,24590,24591,24596,24597,24598,24599,24600,24601,24602,24603,24604,24605,24606,24607,24608,24609,24620,24625,24652 -ErrorAction SilentlyContinue

        if ($Events.Count -gt 0 -and (Test-Connection $domain -Count 1)) 
        {
			Write-Host "Key has been used, must be replaced"
            Reset-SRGBitLockerKey
        }
		else
		{
			Write-Host "Key must not be changed, it was not recently used"
		}
    }
    else 
    {
        Write-Host "Key can not be changed because $domain not available."
    }
}

