# -------------------------------------------------------------------------
# Author: SRG SSR - INIT - Workplace Service - James Levell
# Date: 2018-10-25
# Version: 2.0
# Comment: base functions used for the analyse tool to work
# History:	R1	2015-12-29	Levell James	Initial Build
#			R2	2018-03-20	Levell James	Changed output path
#           R5  2018-10-25  Levell James    Adapted for Windows 10
# --------------------------------------------------------------------------

Function CreateWorkfolder ($ticketNumber, $hostname)
{
	#Create a Workfolder in a temp Directory
	#Call Function "CreateWorkfolder TicketNumber Hostname"
	#Variable section
	$tempPath = "C:\ProgramData\SRG SSR\"
	$workingPath = $tempPath + $ticketNumber + "\"
	$workingPathDirectory = $workingPath + $hostname + "\"
	
	#Create a temporary workfolder, if not already exists
	if((Test-Path "$tempPath") -ne $TRUE)
	{
		New-Item -Type Directory -Path $tempPath | Out-Null
	}
	
	#Create subfolder in TempPath, if not already exists
	if((Test-Path "$workingPath") -ne $TRUE)
	{
		New-Item -Type Directory -Path $workingPath | Out-Null
	}	
	
	#Create sub-subfolder in TempPath, if not already exists
	if((Test-Path "$workingPathDirectory") -ne $TRUE)
	{
		New-Item -Type Directory -Path $workingPathDirectory | Out-Null
	}
	
	#Return the WorkingPathDirectory
	return $workingPathDirectory
}

Function New-Zip ($zipfilename, $sourcedir, [switch]$force)
{
	#creates as zip file, from an sourcedir
	
    $continue = $false
    #check if zipfile already exists
    if(Test-Path $zipfilename)
    {
        #file already exsists
        if($force)
        {
            #because force remove the existing file
            Remove-Item $zipfilename -Force

            #allow to continue
            $continue = $true
        }
        else
        {
            Write-Error "Zip file already exists, please remove and retry or execute using the force"
        }
    }
    else
    {
        #allow to continue
        $continue = $true
    }
    
    #if continue not allowed
    if($continue)
    {

	    #new file system object
        [Reflection.Assembly]::LoadWithPartialName( "System.IO.Compression.FileSystem" )
	
	    #compressionlevel
        $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
	
	    $Error = $false
	    try
	    {
            #create zip
		    [System.IO.Compression.ZipFile]::CreateFromDirectory( $sourcedir, $zipfilename, $compressionLevel, $false )
	    }

	    catch
	    {
		    $Error = $true
	    }

        #if creation failed catch error	
	    if($Error)
	    {
		    Write-Error "Zip couldn't be created"
	    }
    }
}

Function CopyWorkData ($ticketNumber, $hostname)
{
	#Copy Working Folder to PCCOMMON if reachable, otherwise open explorer
	#Call Function "CopyWorkData TicketNumber Hostname"
	
	#Working temp path
	$tempPath = "C:\ProgramData\SRG SSR\"
	$workingPath = $tempPath + $ticketNumber + "\"
	$workingPathDirectory = $workingPath + $hostname + "\"

		
	#copy workingfolder to remote share. Store Error Message in $ErrorMessage
	$output = New-Zip -sourcedir $workingPathDirectory -zipfilename $tempPath\$Hostname.zip -force
				
	#open explorer
	Invoke-Command -Scriptblock { param ( $tempPath ) & explorer.exe $tempPath } -ArgumentList $tempPath
		
	#delete the Files of the temp folder
	Remove-Item -Force -Recurse -path $WorkingPath
}