# BitLocker management using schedulded tasks
The script contains of two main function which provide managebility of Bitlocker on Windows 10.   
The first function "Check-RecoveryKeyUsed " generates a new key when an event indicates that the key has been used.   
The second function "Update-SRGBitLockerKey" safes the recovery key to the active directory.  
These two function can be executed using a schedulded task. 

## Configuration
The domain has to be configured where the BitLocker keys are safed to. 