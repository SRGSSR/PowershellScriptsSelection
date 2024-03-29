param (
	$scriptPath = ""
) #the script path has to be given form the mainscript because the function script cannot evaluate where it is
# -------------------------------------------------------------------------
# Author: SRG SSR - INIT - Workplace Service - James Levell
# Date: 2018-10-25
# Version: 2.0
# Comment: Generates Forms for user, because CLI isn't for all people
# History:	R1	2015-02-18	Levell James	Initial Build
#           R2  2018-10-25  Levell James    Adapted for Windows 10
# --------------------------------------------------------------------------

#Global Functions
Function LoadFormPreRequisits
{
	#Load Assemblies for form creation
	[void][reflection.assembly]::Load("mscorlib, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.Data, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
	[void][reflection.assembly]::Load("System.Xml, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.DirectoryServices, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
	[void][reflection.assembly]::Load("System.Core, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.ServiceProcess, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
}

Function GetOutputForm
{
	#get output for forms
	$File = $env:TEMP + "\OutputFile-AnalyseTool.txt"
	Get-Content $File
}

Function CreateForm
{
	param (
		$LabelText = "",
		$FormTitel = "",
		$TypeOfForm = ""
	
	)
	
	#Creates a form based on parameter given
	#FormTitel is the name of the Windows and is shown at the menüleiste
	#LabelText will be shown first on the form. The text has to be short. 
	#The second text will be taken dynamical from GetOutputForm
	
	#load form Prerequisites
	LoadFormPreRequisits
	
	#Generate Form Objects
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$OutputForm = New-Object 'System.Windows.Forms.Form'
	$OutputFormLabelFirst = New-Object 'System.Windows.Forms.Label'
	$OutputFormLabel = New-Object 'System.Windows.Forms.Label'
	$OutputFormTimer = New-Object 'System.Windows.Forms.Timer'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	$OKButton = New-Object System.Windows.Forms.Button
	$CancelButton = New-Object System.Windows.Forms.Button
	$objTextBox = New-Object System.Windows.Forms.TextBox 

	#Configure Tick
	$OutputFormTimer_Label={
		#Output of File
		$FileContent = (GetOutputForm)
		
		#Check if Output empty. If empty clear form
		if($FileContent -ne $null)
		{
			#get color of text. way to data stored in file (Red: Text)
			#split Output
			$FilteredFileContent = $FileContent.Split(":")
			
			#check if array. If no array no color was specified
			if ($FilteredFileContent[1] -ne $NULL)
			{	
				#if array the color was specified
				$Color = $FilteredFileContent[0]
				$Output = $FilteredFileContent[1].substring(1) 
			}
			else
			{
				#otherwise no color was specified
				$Color = ""
				$Output = $FilteredFileContent
			}
			
			#do switch do configure right color
			switch ($Color)
			{
				green {
					$OutputFormLabel.ForeColor = "green"
				}
				
				red {
					$OutputFormLabel.ForeColor = "red"
				}
				
				blue {
					$OutputFormLabel.ForeColor = "blue"
				}
				
				default {
					$OutputFormLabel.ForeColor = "black"
				}
			}
		}
		else
		{
			#reset view
			$Output = ""
		}
		
		#save Output, trigger will then reload
		$OutputFormLabel.text = $Output
	}
	
	#Create Form
	$OutputForm.Text = "$FormTitel"
	$OutputForm.Size = New-Object System.Drawing.Size(300,200) 
	$OutputForm.MinimizeBox = $False
	$OutputForm.MaximizeBox = $False
	$OutputForm.WindowState = "Normal"    # Maximized, Minimized, Normal
	$OutputForm.SizeGripStyle = "Hide"    # Auto, Hide, Show | Versteckt das grösser machen Zeichen
	$OutputForm.ShowInTaskbar = $True	
	$OutputForm.StartPosition = "CenterScreen"    # CenterScreen, Manual, WindowsDefaultLocation, WindowsDefaultBounds, CenterParent
	$OutputForm.ShowIcon = $True
	$OutputForm.Icon = $scriptPath + "\include\PerfCenterCpl.ico"
	$OutputForm.TopMost = $True
	
	#Add Stuff to Form text box and such things
	$OutputForm.Controls.Add($OutputFormLabelFirst)
	$OutputForm.Controls.Add($OutputFormLabel)
	
	#if the TypeOfForm is StartForm add Textbox an Buttons
	if($TypeOfForm -eq "StartForm")
	{
		#Load Stuff to form
		$OutputForm.Controls.Add($OKButton)
		$OutputForm.Controls.Add($CancelButton)
		$OutputForm.Controls.Add($objTextBox) 	
	
		#handle enter action
		$OutputForm.KeyPreview = $True
		$OutputForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
			{$global:UserInput=$objTextBox.Text;$OutputForm.Close()}})
	
		#Button OK configuration. If OK is pressed the $UserInput is equel the Textbox Input
		$OKButton.Location = '75,120'
		$OKButton.Size = '75,23'
		$OKButton.Text = "OK"
		$OKButton.Add_Click({$global:UserInput=$objTextBox.Text;$OutputForm.Close()})

		#Button Cancel Configuration. If Cancel is pressed Form will be closed
		$CancelButton.Location = '150,120'
		$CancelButton.Size = '75,23'
		$CancelButton.Text = "Cancel"
		$CancelButton.Add_Click({$global:UserInput="exit";$OutputForm.Close()})
		
		#Text Box Configuration
		$objTextBox.Location = '15,80'
		$objTextBox.Size = '250,20'
		
		#Output Form size smaller when with textbox
		$OutputFormLabel.Size = '265, 40'
	}
	else
	{
		#Output Form size bigger when without textbox
		$OutputFormLabel.Size = '265, 80'
	}
	
	#Generate Label First (top)
	$OutputFormLabelFirst.Location = '15, 9'
	$OutputFormLabelFirst.Size = '265, 20'
	$OutputFormLabelFirst.Name = "OutputFormLabelFirst"
	$OutputFormLabelFirst.TabIndex = 0
	$OutputFormLabelFirst.Text = "$LabelText"

	#Generate Label
	$OutputFormLabel.Location = '15, 30'
	$OutputFormLabel.Name = "OutputFormLabel"
	$OutputFormLabel.Text = "Label"
	$OutputFormLabel.TabIndex = 0
	
	#Timer for reload
	$OutputFormTimer.Enabled = $True
	$OutputFormTimer.Interval = 1
	$OutputFormTimer.add_Tick($OutputFormTimer_Label)

	#Save the initial state of the form
	$InitialFormWindowState = $OutputForm.WindowState

	#if startform is launched show form and return value, otherwise only show form
	if($TypeOfForm -eq "StartForm")
	{
		#Show the Form
		$OutputForm.ShowDialog()
		
		#return Textbox Input
		return $global:UserInput
	}
	else
	{
		#Show the Form
		$OutputForm.ShowDialog()
	}
}
