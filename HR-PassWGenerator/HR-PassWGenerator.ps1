
<##########################################################################
# SCRIPT METADATA
#
# Human Readable Password Generator
#
# Version: 1.1
# Date   : 19-06-2024
# By     :
#         |~) _  _  _ | _|  |~).. _  _|  _  _| 
#         |~\(_)| |(_||(_|  |~\||(/_| |<(/_| |<
#                              L|  
##########################################################################>
# Wordbank from: https://www.opentaal.org/ (deleted some swear words) 

Param(
    [int]$passwords = 5,
    [int]$passwordLength = 20,
	[string]$wordlist = "wordlist(edited).txt"
)

if ($psISE)
{
    $curpath = Split-Path -Path $psISE.CurrentFile.FullPath        
}
else
{
    $curpath = $global:PSScriptRoot
}


$specialchars = [char[]]'-!"#$%&()*,./:;?@[]^_`{|}~+<=>'
$pathwordlist = "$curpath\$wordlist"


Write-Host "--------------------------------------------------------------------------" -ForegroundColor Green
Write-Host "--- Human Readable Password Generator version 1.1" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------" -ForegroundColor Green
write-host "--- Loading: $wordlist ..." -ForegroundColor Yellow
$Bank = Get-Content $pathwordlist

Write-host "--- Total # words: $($bank.count)" -ForegroundColor Yellow
write-host "--- Using this special chars: $specialchars`n" -ForegroundColor Yellow

Function pause ($message)
{
    # Check if running Powershell ISE
    if ($psISE)
    {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("$message")
    }
    else
    {
        Write-Host "$message" -ForegroundColor Yellow
        $x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

function Get-RandomWord {
    param (
        [int]$length = 6,
        [int]$seconds = 120
    )
    
    [string]$rndword = ""
    $count = 0
    [System.TimeSpan]$timeout = New-TimeSpan -Seconds $seconds
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    do {
        $rndword = Get-Random -InputObject $script:Bank
        $count ++
    } until (($rndword.length -eq $length -and $rndword -match '^[a-z\s]+$') -or ($stopwatch.elapsed -ge $timeout))
    
    $stopwatch.stop()
    
    #write-host "DEBUG - Generated word of length $length in $count attempts in $($stopwatch.Elapsed.TotalSeconds)..." -ForegroundColor Cyan

    $rndword = $rndword.Substring(0,1).toupper() + $rndword.Substring(1,$rndword.Length-1).ToLower() 
    return $rndword
}


function Get-RandomPass {
    param (
        [int]$length = 20
    )
    
    [string]$Password
    [int]$max = [math]::Round($length * 0.66)

    $i = get-random -Minimum 4 -Maximum $max

    $word1 = Get-RandomWord -length $i
    $word2 = Get-RandomWord -length ($length - 3 -$i)
    
    $Number = "{0:d2}" -f (Get-Random -Minimum 1 -Maximum 99)
    $special = $script:Specialchars | Get-Random
    $Password = $word1 + $word2 + $Number + $Special
    return $Password
}


$inputpasswords = Read-Host "Please enter amount of passwords which should be generated (DEFAULT: $passwords)..."
if($inputpasswords) { 
    $passwords = $inputpasswords 
}
$inputpasswordlength = Read-Host "Please enter length of the passwords which should be generated (DEFAULT: $passwordLength)..."
if($inputpasswordlength) { 
    $passwordLength = $inputpasswordlength 
}

Write-Host "CRUNCHING... Generate $passwords Random Human Readable passwords of $passwordLength chars..." -ForegroundColor Green 
$stopwatch2 = [System.Diagnostics.Stopwatch]::StartNew()

for ($i = 0; $i -lt $passwords; $i++)
{ 
    Get-RandomPass -length $passwordLength
}
$stopwatch2.stop()
write-host "`nGenerated $i passwords of length $length in $($stopwatch2.Elapsed.TotalSeconds) seconds..." -ForegroundColor Cyan
pause "Press Any Key to continue..."
