param (
	$scriptPath = ""
) #the script path has to be given from the run.vbs script because the subMain cannot evaulate where it is
# -------------------------------------------------------------------------
# Author: SRG SSR - INIT - Workplace Service - James Levell
# Date: 2018-10-25
# Version: 2.0
# Comment: subMains which Displays the current state of the Date collection
# History:	R1	2015-02-18	Levell James	Initial Build
#			R2	2015-12-29	Levell James	Changed the name of the Output File so mutiple Programms can be opened
#           R5  2018-10-25  Levell James    Adapted for Windows 10
# --------------------------------------------------------------------------
cls

#Global Variable
$OutputFile = $env:TEMP + "\OutputFile-AnalyseTool.txt"

#Include include script, no more includes needed
. $scriptPath\include\form.ps1 -scriptPath $scriptPath

#Clear Form Output
echo "" > $OutputFile

#Create Form Ouptut
CreateForm -FormTitel "SRG SSR Data Analyse running" -LabelText "AnalyseTool is collecting data"
	
#remove output file
Remove-Item -Force $OutputFile