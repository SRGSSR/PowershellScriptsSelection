#function section
Function Get-ChromeFavorites
{
    <#
    .SYNOPSIS
    Gets the chrome favorites in a parsable way. If no bookmarks file is existing will return 0

    .EXAMPLE
    Get-ChromeFavorites -path 'C:\Users\<UserName>\AppData\local\Google\Chrome\User Data\Default\Bookmarks'

    .PARAMETER path
    Path to your local app data google chrome folder

    .NOTES
    Created by INIT James Levell
    #>

    param(
        [string]$file
    )

    $favorites = @() #stores the favorites
    $roots = @("bookmark_bar", "other", "synced") #roots of the bookmark json object

    if(Test-Path $file)
    {
        #bookmark already existing
        $bookmarks = Get-content $file | Out-String | ConvertFrom-Json

        #foreach root get all the favorits
        foreach ($root in $roots)
        {
            $favorites += Get-ChromeFavoritesNode -children $bookmarks.roots.($root).children -parent $root
        }
    }
    else
    {
        #no existing bookmarks
        $favorites = $null
    }

    return $favorites
}

Function Get-ChromeFavoritesNode
{
    <#
    .SYNOPSIS
    Gets recursivly the favorites of one node

    .PARAMETER children
    child tree of the json bookmark object

    .PARAMETER parent
    name of the parent which is calling the function, used to create the path to the link
    #>

    param (
        $children,
        [string]$parent
    )

    $favorites = @() #stores the favorites

    foreach($child in $children)
    {
        #if a url store it on the array
        if($child.type -eq "url")
        {
            $favorite = New-Object -TypeName psobject -Property @{
                name = $parent + "\" + $child.name
                url = $child.url
                id = $child.id
            }

            $favorites += $favorite
        }
        #if a folder call self as new parent
        elseif($child.type -eq "folder")
        {
            $parent = $parent + "\" + $child.name

            $favorites += Get-ChromeFavoritesNode -children $child.children -parent $parent
        }
    }

    return $favorites
}

Function Add-UrlsToChrome
{
    <#
    .SYNOPSIS
    Adds urls to the chrome bookmark

    .PARAMETER path
    path to the bookmark json of google chrome

    .PARAMETER id
    current highest id

    .PARAMETER urlsToAdd
    List of urls which have to be added
    #>

    param(
        [string]$file,
        [int]$id,
        $urlsToAdd
    )

    $bookmarks = Get-content $file | Out-String | ConvertFrom-Json

    #if no current bookmark exist it is not possible to extract the id, so we set a value
    if($id -eq $null)
    {
        $id = 3
    }

    #loop through the new urls and add them in the json object one by one
    foreach($urlToAdd in $urlsToAdd)
    {
        $bookmarks.roots.bookmark_bar.children = Add-FavoritNodeChrome -url $urlToAdd -node $bookmarks.roots.bookmark_bar.children -id $id
    }

    #export the json back again
    ConvertTo-Json $bookmarks -Depth 10 | Out-File -FilePath $file -Encoding utf8 -Force
}

Function Add-FavoritNodeChrome
{
    <#
    .SYNOPSIS
    Adds recursivly a url tp a node

    .PARAMETER url
    Url which would liked to be added to the node

    .PARAMETER node
    child tree of the json bookmark object

    .PARAMETER id
    id which is used in the object itself
    #>
    param(
        $url,
        $node,
        $id
    )

    #before we add an item we have to increment the id
    $id++

    #get the parent folder
    $parent = $url.name.split("\")

    #if no parent we can add this url in the current node
    if($parent.length -eq 1)
    {
        $favorite = New-Object -TypeName psobject -Property @{
            name = $url.name
            url = $url.url
            id = $id
            type = "url"
            date_added = (Get-Date).ToFileTime()
            meta_info = @{}
        }

        $node += $favorite
    }
    else
    #otherwise add a new folder to the node and jump in to that node
    {
        $found = $false

        #verify if a folder with this name not already exists
        for($i = 0; $i -lt $node.count; $i++)
        {
            if($node[$i].name -eq $parent[0])
            {
                $found = $true
            }
        }

        #folder does not exists, create a new one
        if($found -eq $false)
        {
            $folder = New-Object -TypeName psobject -Property @{
                name = $parent[0]
                id = $id
                type = "folder"
                date_added = (Get-Date).ToFileTime()
                children = @(@{})
            }

            #some bug fixing because powershell not always good
            if($node.length -eq 0)
            {
                $node = @()
            }
            else
            {
                $newNodes = @()
                $newNodes += $node
                $node = $newNodes

            }

            $node += $folder
        }

        #cut of the parent folder of the url name and use it further
        $url.name = $url.name.SubString($url.name.IndexOf("\") + 1)

        $index = 0
        #get the index again in the nodes of the folder
        for($i = 0; $i -lt $node.count; $i++)
        {
            if($node[$i].name -eq $parent[0])
            {
                $index = $i
            }
        }

        #jump into the folder and add the children elementes
        $node[$index].children = Add-FavoritNodeChrome -url $url -node $node[$index].children -id $id
    }

    return $node
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

    .PARAMETER LogData
    data which should be logged
    #>

    param(
    [string]$LogData
    )

    Write-Host "$(Get-DateStamp) $LogData"
}

Function Get-IfHostServer
{
    <#
    .SYNOPSIS
    Returns true if the script is executed on a server
    #>

    (Get-CimInstance Win32_OperatingSystem).Caption -notlike "*Windows 10*"
}

Function Get-ShouldRunOnMachine
{
    param(
        [string]$file
    )

    <#
    .SYNOPSIS
    Verifies if this script should be executed on this client/server

    .PARAMETER file
    path to the export file
    #>

    $server = Get-IfHostserver

    try
    {
        $alreadyExecute = $file.split("\")[-1].split("_")[2].split(".")[0]

        if($server -eq $true)
        {
            if($alreadyExecute -like "*s*")
            {
                $execute = $false
            }
            else
            {
                $execute = $true
            }
        }
        else
        {
            if($alreadyExecute -like "*c*")
            {
                $execute = $false
            }
            else
            {
                $execute = $true
            }
        }
    }

    catch
    {
        $execute = $true
    }

    return $execute
}

#configuration section
$fileserver = "fileserver"

#variable section
$username = (whoami).split("\")[1]
$share = "\\" + $fileserver + "\Roaming-UserSettings"
$filename = $share + "\" + $username
$chromePath = "c:\Users\" + $username + "\AppData\local\Google\Chrome\User Data\Default"
$chromeFile = $chromePath + "\Bookmarks"

$chromeFavorites = Get-ChromeFavorites -file $chromeFile
$id = $chromeFavorites | Sort-Object id -Descending | Select-Object id -First 1
$favoritesToAdd = @()

#Get export only if one exists and server online
if((Test-Connection -Count 1 -ComputerName $fileserver -Quiet -ErrorAction SilentlyContinue) -eq $true)
{
    $filename = (Get-ChildItem $filename | Where-Object { $_.Name -like "IE_favorites*" } | Sort-Object | Select-Object -Last 1).Fullname
    
    if(Get-IfHostServer)
    {
        $newFilename = $filename.Insert($filename.Length -5, "s")
    }
    else
    {
        $newFilename = $filename.Insert($filename.Length -5, "c")
    }

    $shouldRunOnMachine = Get-ShouldRunOnMachine -File $filename

    if($filename -ne $null -and $shouldRunOnMachine -eq $true)
    {
        #get the origin ie favorites
        $originFavorites = ConvertFrom-Json -InputObject (Get-Content $filename | Out-String)

        #verify if not already imported in google
        foreach($originFavorite in $originFavorites)
        {
            $alreadyExisting = $false

            #only add favorites when not already in google chrome
            foreach($chromeFavorite in $chromeFavorites)
            {
                if($originFavorite.url -eq $chromeFavorite.url)
                {
                    $alreadyExisting = $true
                }
            }

            if($alreadyExisting -eq $false)
            {
                #import the missing favorites
                $favoritesToAdd += $originFavorite
            }
        }

        #verify if bookmarks file is existing
        if(Test-Path $chromeFile)
        {
            #make a backup of the bookmarks
            $backupName = ".bck_" + (Get-DateStamp).substring(0, (Get-DateStamp).length -1).replace(":", "_")
            Copy-Item -Path $chromeFile -Destination $chromeFile$backupName -Force
        }
        else
        {
            #create a default bookmarks file
            New-Item -Path $chromePath -Type Directory -ErrorAction SilentlyContinue
            '{
   "checksum": "fb6b75739c42f572afd1e0703b34fd81",
   "roots": {
      "bookmark_bar": {
         "children": [  ],
         "date_added": "13176998230955081",
         "date_modified": "0",
         "id": "1",
         "name": "Lesezeichenleiste",
         "type": "folder"
      },
      "other": {
         "children": [  ],
         "date_added": "13176998230955085",
         "date_modified": "0",
         "id": "2",
         "name": "Weitere Lesezeichen",
         "type": "folder"
      },
      "synced": {
         "children": [  ],
         "date_added": "13176998230955088",
         "date_modified": "0",
         "id": "3",
         "name": "Mobile Lesezeichen",
         "type": "folder"
      }
   },
   "version": 1
}' |  Out-File -FilePath $chromeFile -Encoding utf8 -Force
        }

        #add urls to chrome
        Add-UrlsToChrome -file $chromeFile -urlsToAdd $favoritesToAdd -id $id.id

        #rename the origin file 
        Rename-Item -Path $filename -NewName $newFilename
    }
    else
    {
        Write-Entry -LogData "Info: for $username no export exists"
    }
}
else 
{
    Write-Entry -LogData "Info: file server is not available"
}