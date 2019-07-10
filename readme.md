# Powershell script selection
This repository contains several scripts the SRG has created for managing Windows 10 clients.  
The tools are explained here briefly and in more depth in the corresponding folders.  
Do not hesitate to start dicussions or create pull request.  


## BitLocker Recovery Key management
Within the SRG we did not want to rely on a additional tool for managing BitLocker keys such as Microsoft Solution MBAM (Microsoft BitLocker Administration and Monitoring).  
So we replaced the most important features of MBAM by using schedulded tasks which run on the start of the computer. 

The features of the solution are the following 
- backup the recovery key to the AD
- generate a new key, if the key has been used once 

## Data Collector 
In a case of an incident it is important to have the most relevant information available. Therefore we have created a data collector which exports the most important information as a zip file.  

The data collector collects the following information:
- hardware information  
- network related information
- connected printer and network drives 
- installed software 
- export eventlogs

## Export favorites
Prior to Windows 10 the users were using Windows 7 and browsed the web using IE11. Also their favorites are stored in the IE11.  
The favorits had to be migrated from Windows 7 I11 to Windows 10 Google Chrome. This was done by this two part script
- Windows 7 part: exports the favorits to a shared network drive 
- Windows 10 part: imports the favorits from the shared network drive to Google Chrome favorits bookmark. 

## Refresher
The client management in the SRG is done by SCCM and application are deployed either via SCCM or APP-V. The cycles of these systems are sometimes to slow. Therefore this tool has been created which refreshes the following management systems directly on the client:
- SCCM
- App-V 
- GPO
- Windows Defender

## ShowInfos
On a client a technican need quickly the most relevant information. This tool displays all the information necessary to get a first impression of the client. 
The following information are being displayed: 
- assigned software
- last boot time
- hardware information
- user information