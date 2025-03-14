<##########################################################################
# SCRIPT METADATA
# Name: download_firefox_chrome.ps1
# Descr: Download Latest version of Firefox and Google Chrome if newer
# Version: 1.3
# Date   : 14-03-2025
# By     :
#         |~) _  _  _ | _|  |~).. _  _|  _  _| 
#         |~\(_)| |(_||(_|  |~\||(/_| |<(/_| |<
#                              L|  
##########################################################################>

Function Get-ExeVersion {
    param (
        [string]$exePath
    )
    if (Test-Path $exePath) {
        return (Get-Item $exePath).VersionInfo.FileVersion
    }
    return $null
}

    function Get-MsiFileInfoEx {
        [OutputType([hashtable])]
        param(
            [Parameter(
                Mandatory = $true,
                ValueFromPipeLine = $true,
                ValueFromPipelineByPropertyName = $true
            )]
            [ValidateNotNullOrEmpty()]
            [IO.FileInfo] $Path,
    
            [parameter(Mandatory = $false)]
            [ValidateNotNullOrEmpty()]
            [string[]] $Properties = @('Manufacturer', 'ProductName', 'ProductVersion', 'ProductCode', 'ProductLanguage', 'FullVersion'),

            [parameter(Mandatory = $false)]
            [switch] $GetPublicProperties,

            [parameter(Mandatory = $false)]
            [switch] $DoNotIncludeFileInfo,

            [parameter(Mandatory = $false)]
            [switch] $IncludeNonMsiFileInfo
        )
        Begin {
            $alwaysGetProperties = @('Manufacturer', 'ProductName', 'ProductVersion', 'ProductCode', 'ProductLanguage', 'FullVersion')
            
            if (-not $Properties -or $Properties -eq '*' -or $GetPublicProperties.IsPresent) {
                $query = 'SELECT * FROM Property'
            }
            else {
                $queryWhere = (($Properties + $alwaysGetProperties | Select-Object -Unique) | Foreach-Object { 'Property = ''{0}''' -f $_ }) -join ' OR '
                $query = 'SELECT Property, Value FROM Property WHERE {0}' -f $queryWhere
            }
            
            #***Write-Verbose "[Get-MsiFileInfo] MSI Query: ${query}"
        }
        
        Process {
            #***Write-Verbose "[Get-MsiFileInfo] Path: ${Path}"

            if (-not $Path.Exists) {
                $resolvedPath = (Resolve-Path $Path -ErrorAction 'Ignore').ProviderPath
                #***Write-Verbose "[Get-MsiFileInfo] ResolvedPath: ${resolvedPath}"
                if ($resolvedPath) {
                    [IO.FileInfo] $Path = $resolvedPath
                }
            }

            [hashtable] $msiProperties = @{}
            if ($IncludeNonMsiFileInfo.IsPresent -or -not $DoNotIncludeFileInfo.IsPresent) {
                $msiProperties.Add('.IO.FileInfo', $Path)
            }

            if ($Path.Exists) {
                $windowsInstaller = New-Object -ComObject windowsInstaller.Installer
                try {
                    $msiDatabase = $windowsInstaller.GetType().InvokeMember('OpenDatabase', 'InvokeMethod', $null, $windowsInstaller, @($Path.FullName, 0))
                    $view = $msiDatabase.GetType().InvokeMember('OpenView', 'InvokeMethod', $null, $msiDatabase, ($query))
                    [void] $view.GetType().InvokeMember('Execute', 'InvokeMethod', $null, $view, $null)
        
                    do {
                        $record = $view.GetType().InvokeMember('Fetch', 'InvokeMethod', $null, $view, $null)
        
                        if (-not [string]::IsNullOrEmpty($record)) {
                            $addMember = $false
        
                            # Return the value
                            $name = $record.GetType().InvokeMember('StringData', 'GetProperty', $null, $record, 1)
                            #***Write-Debug " [Get-MsiFileInfo] 1 (name): ${name}"
                            $value = $record.GetType().InvokeMember('StringData', 'GetProperty', $null, $record, 2)
                            #***Write-Debug " [Get-MsiFileInfo] 2 (value): ${value}"
                            if ($GetPublicProperties.IsPresent) {
                                if ($alwaysGetProperties -contains $name) {
                                    $addMember = $true
                                }
                                elseif ($name -cnotmatch '[a-z]') {
                                    $addMember = $true
                                }
                            }
                            else {
                                $addMember = $true
                            }
                            
                            if ($addMember) {
                                #***Write-Debug " [Get-MsiFileInfo] Adding to return set."
                                [void] $msiProperties.Add($name, $value)
                            }
                        }
                    } until ([string]::IsNullOrEmpty($record))

                    # Commit database and close view
                    [void] $msiDatabase.GetType().InvokeMember('Commit', 'InvokeMethod', $null, $msiDatabase, $null)
                    [void] $view.GetType().InvokeMember('Close', 'InvokeMethod', $null, $view, $null)           
                }
                catch {
                    Write-Debug ('[Get-MsiFileInfo] Error Caught' -f $_.Exception.Message)
                    #***Write-Warning ('Unable to open MSI database; it''s either not an MSI file or the file is corrupted: {0}' -f $Path.FullName)
                }
                finally {
                    $view = $null
                    $msiDatabase = $null
                    [void] [System.Runtime.Interopservices.Marshal]::ReleaseComObject($windowsInstaller)
                    $windowsInstaller = $null
                }
            }

            #***Write-Debug ('msiProperties: {0}' -f ($msiProperties | Out-String))
            Write-Output $msiProperties
            #***Write-Output (New-Object PSObject -Property $msiProperties)
        }
        
        End {
            # Run garbage collection and release ComObject
            if ($windowsInstaller) {
                [void] [System.Runtime.Interopservices.Marshal]::ReleaseComObject($windowsInstaller)
            }
            [void] [System.GC]::Collect()
        }
    }


    function Get-MsiFileVersion {
    [OutputType([string])]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeLine = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNullOrEmpty()]
        [IO.FileInfo] $Path
    )

    Begin {
        $query = 'SELECT Property, Value FROM Property WHERE Property = ''ProductVersion'''
    }

    Process {
        if ($Path.Exists) {
            $windowsInstaller = New-Object -ComObject windowsInstaller.Installer
            try {
                $msiDatabase = $windowsInstaller.GetType().InvokeMember('OpenDatabase', 'InvokeMethod', $null, $windowsInstaller, @($Path.FullName, 0))
                $view = $msiDatabase.GetType().InvokeMember('OpenView', 'InvokeMethod', $null, $msiDatabase, ($query))
                [void] $view.GetType().InvokeMember('Execute', 'InvokeMethod', $null, $view, $null)
    
                do {
                    $record = $view.GetType().InvokeMember('Fetch', 'InvokeMethod', $null, $view, $null)
    
                    if (-not [string]::IsNullOrEmpty($record)) {
                        $name = $record.GetType().InvokeMember('StringData', 'GetProperty', $null, $record, 1)
                        $value = $record.GetType().InvokeMember('StringData', 'GetProperty', $null, $record, 2)
    
                        # Return the ProductVersion value
                        if ($name -eq 'ProductVersion') {
                            Write-Output $value
                        }
                    }
                } until ([string]::IsNullOrEmpty($record))

                # Commit database and close view
                [void] $msiDatabase.GetType().InvokeMember('Commit', 'InvokeMethod', $null, $msiDatabase, $null)
                [void] $view.GetType().InvokeMember('Close', 'InvokeMethod', $null, $view, $null)
            }
            catch {
                Write-Debug ('[Get-MsiFileInfo] Error Caught' -f $_.Exception.Message)
            }
            finally {
                $view = $null
                $msiDatabase = $null
                [void] [System.Runtime.Interopservices.Marshal]::ReleaseComObject($windowsInstaller)
                $windowsInstaller = $null
            }
        }
    }

    End {
        [void] [System.GC]::Collect()
    }
}



Function FastDownload {
    param (
        [string]$url,
        [string]$targetPath,
        [string]$proxyAddress = $null  # Optional proxy address (e.g., "http://proxy:port")
    )

    $tempPath = "$targetPath.tmp"
    
    # Create the WebClient object
    $webClient = New-Object System.Net.WebClient

    # Configure the proxy if specified
    if ($proxyAddress) {
        $proxy = New-Object System.Net.WebProxy($proxyAddress)
        $webClient.Proxy = $proxy
    } else {
        $webClient.Proxy = [System.Net.GlobalProxySelection]::GetEmptyWebProxy() # No proxy
    }

    # Download the file temporarily
    Write-Host "Downloading new version..." -ForegroundColor Cyan
    $webClient.DownloadFile($url, $tempPath)
    
    # Determine versioning method
    $newVersion = if ($targetPath -match "\.msi$") { Get-MsiFileVersion $tempPath } else { Get-ExeVersion $tempPath }
    $existingVersion = if ($targetPath -match "\.msi$") { Get-MsiFileVersion $targetPath } else { Get-ExeVersion $targetPath }

    if ($newVersion -and ($existingVersion -eq $null -or [version]$newVersion -gt [version]$existingVersion)) {
        Write-Host "Newer version found ($newVersion > $existingVersion). Updating..." -ForegroundColor Green
        Move-Item -Path $tempPath -Destination $targetPath -Force
    } else {
        Write-Host "No update needed. Current version: $existingVersion, Downloaded version: $newVersion" -ForegroundColor Yellow
        Remove-Item $tempPath -Force
    }
}

$proxy = ""

# Chrome
$chromeUrl = "https://dl.google.com/tag/s/dl/chrome/install/googlechromestandaloneenterprise64.msi"
$chromePath = "c:\temp\GoogleChromeEnterprise64.msi"

Write-Host "Checking Chrome update..." -ForegroundColor Cyan
FastDownload -url $chromeUrl -targetPath $chromePath 

# Firefox
$firefoxUrl = "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US"
$firefoxPath = "c:\temp\FirefoxSetup.exe"

Write-Host "Checking Firefox update..." -ForegroundColor Cyan
FastDownload -url $firefoxUrl -targetPath $firefoxPath 
