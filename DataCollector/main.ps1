# -------------------------------------------------------------------------
# Author: SRG SSR - INIT - Workplace Service - James Levell
# Date: 2018-10-25
# Version: 2.0
# Comment: Main PS which loads the form and the AnalyseTool
# History:	R1	2015-02-18	Levell James	Initial Build
#			R2	2015-11-09	Levell James	Fixed bug with PS 4.0 and updatet outputfile logic
#			R3	2015-12-29	Levell James	Added features, and cleanup directory
#			R4	2018-03-18	Levell James	Changed Export Path to new efs
#           R5  2018-10-25  Levell James    Adapted for Windows 10
# Based on: http://foxdeploy.com/2015/09/08/powershell-guis-how-to-handle-events-and-create-a-tabbed-interface/
# --------------------------------------------------------------------------
cls

#Global Variable
$scriptPath = (split-path $SCRIPT:MyInvocation.MyCommand.Path)
$hostname = (Hostname)
$outputFile = $env:TEMP + "\OutputFile-AnalyseTool.txt"
$date = Get-Date -UFormat %Y-%m-%d_%H:%M:%S
$version = 2.0

#Include include script
. $scriptPath\include\functions.ps1
. $scriptPath\include\form.ps1 -scriptPath $scriptPath
. $scriptPath\include\collector.ps1

#Clear Form Output
echo "" > $outputFile

#Only End Loop if Check passed or nothing is entered
$check = 0
do 
{
	#include form and safe output in variable
	$ticketNumber = (CreateForm -FormTitel "SRG SSR Data Analysis..." -LabelText "Please provide the ticket number:" -TypeOfForm "StartForm")
	$ticketNumber = $ticketNumber[1] #because there comes an cancel command in the output
	
	#Check Ticket Number if long enough. If so add Check + 1
	if($TicketNumber.Length -ge 5)
	{
    	echo "" > $OutputFile
		
		#execute the submain Powershellscript using the run.vbs (so no window is visible).
		$exePath = '"' + $scriptPath + '"' + "\run.vbs subMain.ps1"
		Start-Process cscript.exe $exePath -WindowStyle Hidden
		
		#Wait so seconds, so the submain has chance to init
		Start-Sleep -Seconds 2
		
		###############################################################################
		# Starting Working
		###############################################################################
		
		#create temp workfolder
		$workfolder = CreateWorkfolder $ticketNumber $hostname 
		$workfile = $workfolder + "Analysis.txt" 
		$softwareList = $workfolder + "SoftwareList.txt" 
		
		#start analysis
		echo "Collector Version $version startet at $date " >> $workfile
		echo "#####################################################################" >> $workfile
		echo "" >> $Workfile
		
		$maxTest = 9
		echo "blue: (0/$maxTest) AnalyseTool is being initialized. The collection of the data can take several seconds." > $outputFile
		Start-Sleep -Seconds 2
		echo "blue: (1/$maxTest) Collecting basic client information" > $outputFile
		GetBasicInfos >> $Workfile
		echo "blue: (2/$maxTest) Collecting hardware information" > $outputFile
		GetHardwareInfos >> $Workfile
		echo "blue: (3/$maxTest) Collecting network information" > $outputFile
		GetNetwork >> $Workfile
		echo "blue: (4/$maxTest) Collecting printer infos" > $outputFile
		GetAllPrinters >> $Workfile
		echo "blue: (5/$maxTest) Collecting network shares" > $outputFile
		GetAllDrives >> $Workfile
		echo "blue: (6/$maxTest) Collecting installed software" > $outputFile
		GetAllSoftware >> $SoftwareList
		echo "blue: (7/$maxTest) Export eventlogs security and application" > $outputFile
		ExportEventLog($Workfolder)
		echo "blue: (8/$maxTest) Get GP result report" > $outputFile
		GetGpResult($Workfolder)		
		
		#Store the files locally and zip them
		echo "blue: (9/$maxTest) Zipping the report files" > $outputFile
		$errorMessage = (CopyWorkData $ticketNumber $hostname)
		
		#if error message print output, otherwise tell that stuff is finished
		If($errorMessage -eq $null)
		{
			echo "green: Data could be collected successfully. Programm can be closed" > $outputFile
		}
		else
		{
			echo "red: $errorMessage" > $outputFile
				
			#popup for more information http://msdn.microsoft.com/en-us/library/x83z1d9f(v=vs.84).aspx
			$wshell = New-Object -ComObject Wscript.Shell
			$wshell.Popup("The collection of the data was not succesful. Please verify the client.",0,"Operation failed!",0x0 + 0x10)
		}
		
		$check++
	}
	elseif ($ticketNumber -like "exit")
	{
		$check++
		
		#remove item
		Remove-Item -Force $outputFile
	}
	else
	{
		#user wasn't able to provide a valid ticket number
		echo "red: Please provide a correct ticket number (at least 6 characters)" > $outputFile
	}
}
while($check -lt 1) #if all checks passed exit
