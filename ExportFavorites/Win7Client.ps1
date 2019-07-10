#function area
Function Get-IEFavourites
{
    <#
    .SYNOPSIS
    Gets Favourites from Internet Explorer in a parsable format

    .EXAMPLE
    Get-IEFavourites -path 'C:\Users\<UserName>\Favorites'

    .PARAMETER path
    Path to your Internet Explorer Favourites

    .NOTES
    Created by INIT James Levell
    #>

    param(
        [string]$path
    )

    $favorites = @() #stores the favorites
    $urlNames = Get-ChildItem -Path $path -Filter *.url -name -Recurse
    
    #loop through the files found
    foreach($urlName in $urlNames)
    {
        $url = ""
        $iconFile = ""

        $urlContents = Get-Content "$path\$urlName"

        #loop through each content and parse the url and icon location
        foreach($urlContent in $urlContents)
        {
            if($urlContent -like "URL*")
            {
                $url = $urlContent.SubString($urlContent.IndexOf("\") + 1)
                $url = $url.split("=")[1]
            }

            if($urlContent -like "IconFile*")
            {
                $iconFile = $urlContent.SubString($urlContent.IndexOf("\") + 1)
                $iconFile = $iconFile.split("=")[1]
            }
        }

        $favorite = New-Object -TypeName psobject -Property @{
                name = $urlName.split(".")[0]
                url = $url
                icon = $iconFile
            }

        $favorites += $favorite
    }

    return $favorites
}


Function Get-DateStamp
{
    <#
    .SYNOPSIS
    Gets the datestamp in a beatiful format
    #>

    return "$(Get-Date -UFormat %Y-%m-%d-%H:%M:%S):"
}

Function Write-Entry
{
    <#
    .SYNOPSIS
    Writes an logoutput with the datestamp
    #>

    param(
    [string]$LogData
    )

    Write-Host "$(Get-DateStamp) $LogData"
}

Function Get-FavoritesPath
{
    <#
    .SYNOPSIS
    Gets the current favorits path for the logged in user
    #>

    return [Environment]::GetFolderPath('Favorites')
}

#configuration section
$fileserver = "fileserver"

#variable section
$username = (whoami).split("\")[1]
$share = "\\" + $fileserver + "\Roaming-UserSettings"
$favoritesFolder = Get-FavoritesPath

#verify if file server is reachable
if(Test-Connection -Count 1 -ComputerName $fileserver)
{
    #create personal directory when not already existing
    if((Test-Path $share\$username) -ne $true)
    {
        New-Item -ItemType Directory -Name $username -Path $share
    }

    #only export when no export already exists
    if((Get-Childitem "$share\$username" | Where-Object { $_.Name -like "IE_favorites_*" }) -eq $null -and (Test-Path $favoritesFolder) -eq $true)
    {
        #export and safe favorites
        ConvertTo-Json (Get-IEFavourites -path $favoritesFolder) | Out-File -FilePath "$share\$username\IE_favorites_.json" -Force
    }
    else
    {
        Write-Entry -LogData "Info: for $username already an export exists"
    }
}
else 
{
    Write-Entry -LogData "Info: $fileserver could not be contacted"    
}