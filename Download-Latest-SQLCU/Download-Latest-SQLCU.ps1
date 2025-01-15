<#
.SYNOPSIS
    Downloads latest MS SQL CU's from Microsoft and puts them into a destination folder.
.DESCRIPTION
    This script fetches the latest Cumulative Updates (CUs) for Microsoft SQL Server 
    from the official Microsoft support page, identifies the download links for the updates 
    for specific SQL versions (2017, 2019, 2022)
    and automatically downloads them to a user-defined folder.

.OUTPUTS
    The script will output the download progress, including any errors, and save the downloaded CU files to the specified folder.

.NOTES
    Author: Ronald Rijerkerk
    Version: 1.0
    Date: 2025-01-15
    This script uses the Invoke-WebRequest cmdlet to interact with Microsoft's official release pages and download the update files.

.TODO
    - Add logging functionality to track download successes and failures.
    - Add error handling for potential network or file system issues during the download process.
    - speed up download
    - Get-LatestSQLCUURL for SQL Server 2016 
.LINK
    https://github.com/ronaldnl76/powershell
#>

[CmdletBinding()]
param (
    [string]$destinationpath="C:\SQLServerUpdates"
)

# Base URL for Microsoft's SQL Server Cumulative Updates page
$urlbase = "https://learn.microsoft.com/en-us/troubleshoot/sql/releases/"
# Full URL for the page listing the latest SQL Server updates
$urllatestupdates = $urlbase + "download-and-install-latest-updates"


function Pause {

    param (
        [string]$message = "Press any key to continue...",
        [string]$color = 'Yellow'
    )
    # Check if running in a GUI environment (non-ISE)
    if ($host.Name -eq 'ConsoleHost') {
        Write-Host "$message" -ForegroundColor $color
        $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
    } else {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("$message")
    }
}

Function FastDownload {
    param (
        [string]$url,
        [string]$targetPath
    )
    
    # Create the WebClient object
    $webClient = New-Object System.Net.WebClient

    # Start downloading with progress tracking
    $webClient.DownloadFile($url, $targetPath)
    
}

# Function to get the URL of the latest cumulative update (CU) for a specified SQL Server version
Function Get-LatestSQLCUURL {
    param
    (
        # URL of the page containing update details
        [string]$url,
        # SQL Server version for which the latest CU is needed, defaulting to 2022
        [int]$sqlversion = 2022
    )

    try {
        # Fetch the web page using Invoke-WebRequest
        $Response = Invoke-WebRequest -Uri $url

        # Filter and process the links on the page to find CUs for the specified SQL version
        $AllCULinks = $Response.Links | Where-Object {
            $_.href -match "sqlserver-$sqlversion/cumulativeupdate(\d+)$"
        } | ForEach-Object {
            [PSCustomObject]@{
                Href = $_.href
                CU   = [int]($_.href -replace '.*cumulativeupdate(\d+)$', '$1')
            }
        } | Sort-Object -Property CU -Descending | Select-Object -Unique -Property Href, CU

    } catch {
        # Catch and display any errors encountered during the web request
        Write-Host "Error fetching CU details: $_"
    }

    # Return the URL of the latest CU
    return $AllCULinks.Href
}

# Function to download the latest cumulative update for SQL Server
function Get-LatestSQLCU {
    param
    (
        # URL from which to download the CU
        [string]$Url,
        # Path to save the downloaded CU file
        [string]$OutputPath
    )

    Write-Host "Fetching the latest CU details for SQL Server..."
    
    try {
        # Fetch the web page with CU download details
        Write-Host "Fetch the web page with CU download details Uri: " -ForegroundColor Cyan
        write-host "$Url" -ForegroundColor Cyan
        $Response = Invoke-WebRequest -Uri $Url

        # Parse the HTML to find the download link for the CU
        $LatestCULink = ($Response.Links | Where-Object { $_.href -like "*/download/*" } | Select-Object -First 1).href

        if ($LatestCULink) {
            Write-Host "Latest CU found: $LatestCULink"
            # Fetch the CU download page
            $ResponseDownload = Invoke-WebRequest -Uri $LatestCuLink
            
            # Find the actual executable download link for the CU
            $LatestCUDownloadLink = ($ResponseDownload.Links | Where-Object { $_.href -like "*download.microsoft.com*" -and $_.href -like "*.exe*" } | Select-Object -First 1).href
            if ($LatestCUDownloadLink) {
                # Check if the output directory exists, if not, create it
                if (-not (Test-Path -Path $OutputPath)) {
                    New-Item -ItemType Directory -Path $OutputPath    
                }
                
                # Construct the full file path for the downloaded CU
                $FileName = [System.IO.Path]::GetFileName($LatestCUDownloadLink)
                $FilePath = Join-Path -Path $OutputPath -ChildPath $FileName

                Write-Host "Downloading the latest CU..."
                # Download the CU file to the specified output path
                #Invoke-WebRequest -Uri $LatestCUDownloadLink -OutFile $FilePath 
                FastDownload -url $LatestCUDownloadLink -targetPath $FilePath
                
                Write-Host "Download completed. File saved to: $FilePath"
            } else {
                # Display a message if no executable download link is found
                Write-Host "No CU download link found. Please check the URL or update the script."
            }

        } else {
            # Display a message if no CU link is found on the page
            Write-Host "No CU link found. Please check the URL or update the script." -ForegroundColor Yellow
        }
    } catch {
        # Catch and display any errors encountered during the download process
        Write-Host "Error fetching CU details: $_" -ForegroundColor Red
    }
}

# Download the latest CU for SQL Server 2017 and save it to the specified path
$latestCUURL = $urlbase + (Get-LatestSQLCUURL -url $urllatestupdates -sqlversion 2017 | select-object -first 1)
Get-LatestSQLCU -Url $latestCUURL -OutputPath $destinationpath

# Download the latest CU for SQL Server 2019 and save it to the specified path
$latestCUURL = $urlbase + (Get-LatestSQLCUURL -url $urllatestupdates -sqlversion 2019 | select-object -first 1)
Get-LatestSQLCU -Url $latestCUURL -OutputPath $destinationpath

# Download the latest CU for SQL Server 2022 and save it to the specified path
$latestCUURL = $urlbase + (Get-LatestSQLCUURL -url $urllatestupdates -sqlversion 2022 | select-object -first 1)
Get-LatestSQLCU -Url $latestCUURL -OutputPath $destinationpath

Pause