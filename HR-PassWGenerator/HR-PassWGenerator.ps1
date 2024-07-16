<##########################################################################
# SCRIPT METADATA
#
# Human Readable Password Generator
#
# Version: 1.3
# Date   : 16-07-2024
# By     :
#         |~) _  _  _ | _|  |~).. _  _|  _  _| 
#         |~\(_)| |(_||(_|  |~\||(/_| |<(/_| |<
#                              L|  
##########################################################################>
# Wordbank from: https://www.opentaal.org/ (deleted some swear words) 
# Version 1.2 - Added # amount of words which should be concatenated
# Version 1.3 - Added sort list on length + index search

Param(
    [int]$passwords = 25,
	[int]$usedwords = 3,
    [int]$passwordLength = 30,
	[string]$wordlist = "wordlist(edited).txt",
    [string]$wordlistsort = "wordlist(sorted).txt",
    [string]$indexfile = "index.txt"
)

if ($psISE)
{
    $curpath = Split-Path -Path $psISE.CurrentFile.FullPath        
}
else
{
    $curpath = $global:PSScriptRoot
}

$version = "1.3"
$specialchars = [char[]]'''-!"#$%&()*,./:;?@[]^_`{|}~+<=>'
$pathwordlist = "$curpath\$wordlist"
$pathwordlistsort = "$curpath\$wordlistsort"
$pathindexfile = "$curpath\$indexfile"

Write-Host "--------------------------------------------------------------------------" -ForegroundColor Green
Write-Host "--- Human Readable Password Generator superfast version $version" -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------" -ForegroundColor Green
write-host "--- Loading: $wordlist ..." -ForegroundColor Yellow

function CreateIndex {
    param (
        [Parameter(Mandatory=$true)]
        [string[]] $array
    )
    [string[]] $ind = @()
    $length = 1
    $first = 1
    for ($i = 1; $i -lt $array.Count; $i++)
    { 
        $curl = $array[$i].Length

        if ($curl -eq $length) {
            continue
        } else {
            $ind += "$length,$first,$i"
                        
            $first = $i + 1
            $length = $curl
        }  
    }
   
    write-output -NoEnumerate $ind    
}



if(!$bank) {
    if (!(Test-Path $pathwordlistsort)) {
        write-host "Sort wordlist on length so next time creating passwords will be much faster" -ForegroundColor Cyan
        $stopwatch3 = [System.Diagnostics.Stopwatch]::StartNew()
        $Bank = Get-Content $pathwordlist
        [System.Array]::Sort($bank, [System.Collections.Generic.Comparer[Object]]::Create(
            { param ($x, $y)
                $x.Length.CompareTo($y.Length)
            }
        ))
        
        $stopwatch3.stop()
        
        $bank | Add-Content -Path $pathwordlistsort

        write-host "Sorted wordlist in $($stopwatch3.Elapsed.TotalSeconds) seconds..." -ForegroundColor Cyan
    } else {
        $bank = Get-Content $pathwordlistsort
    }
    
}
Write-host "--- Total # words: $($bank.count)" -ForegroundColor Yellow
write-host "--- Using this special chars: $specialchars`n" -ForegroundColor Yellow

[string[]] $index = @()

if (!$index) {
    if(!(Test-Path $pathindexfile)) {
        $index = CreateIndex $bank
        $index | Add-Content $pathwordlistsort
    } else {
        $index = Get-Content $pathindexfile
    }
}

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



function LookupIndex {
    param (
        [int]$length = 6
    )

    foreach ($i in $script:index) {
        
        $s = $i.split(",")

        if ($s[0] -eq $length) {
           $value = New-Object PsObject -Property @{ 
                low = $s[1];
                high = $s[2];
           }
           write-output $value;
           break
        }
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


function Get-RandomWordEx {
    param (
        [int]$length = 6,
        [int]$seconds = 120
    )
    
    [string]$rndword = ""
    $count = 0
    [System.TimeSpan]$timeout = New-TimeSpan -Seconds $seconds
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    $tup = lookupindex $length
    $low = $tup.low -1
    $high = $tup.high-1
    $searchbank = $bank[$low..$high]
    do {
        $rndword = Get-Random -InputObject $searchbank
        $count ++
    } until (($rndword.length -eq $length -and $rndword -match '^[a-z\s]+$') -or ($stopwatch.elapsed -ge $timeout))
    
    $stopwatch.stop()
    
    #write-host "DEBUG - Generated word of length $length in $count attempts in $($stopwatch.Elapsed.TotalSeconds)..." -ForegroundColor Cyan

    $rndword = $rndword.Substring(0,1).toupper() + $rndword.Substring(1,$rndword.Length-1).ToLower() 
    return $rndword
}


function Get-RandomPassEx {
    param (
        [int]$totallength = 20,
        [int]$totalwords = 3
    )
    
    [string]$Password
    
    $words = New-Object System.Collections.ArrayList

    $Lengthleft = $totallength-3
    #[int]$max = $Lengthleft - ($totalwords * 3)
    [int]$avglen = [math]::Round($Lengthleft / $totalwords)

    for ($j = 1; $j -le $totalwords; $j++)
    { 
        if ($avglen -ne 3) {    
            if($j -eq $totalwords) {                                       #last word
                $length = $Lengthleft
            } elseif ($j -eq $totalwords -1)  {                            #one last word
                if ($lengthleft -eq 6) { 
                    $length = 3
                } else {
                    $length = get-random -Minimum 3 -Maximum $avglen
                }
            } else {
                $length = get-random -Minimum 3 -Maximum $avglen
            }
        } else { $Length = $avglen }
        
        $word = Get-RandomWordEx -length $length
        $words.Add($word) | Out-Null

        $Lengthleft -= $length
        
        write-host "Length: $length - Lengthleft: $Lengthleft"

    }
    
    $Number = "{0:d2}" -f (Get-Random -Minimum 1 -Maximum 99)
    $special = $script:Specialchars | Get-Random
    foreach ($word in $words) {
        $password += $word
    }
    $Password += $Number + $Special
    return $Password
}


$inputpasswords = Read-Host "Please enter amount of passwords which should be generated (DEFAULT: $passwords)..."
if($inputpasswords) { 
    $passwords = $inputpasswords 
}

$inputwords = Read-Host "Please enter amount of words the passwords should contain (DEFAULT: $usedwords)..."
if($inputwords) { 
    $usedwords = $inputwords 
}

$minlength = 3 * ($usedwords+1)
do {
    $inputpasswordlength = Read-Host "Please enter length of the passwords which should be generated (minimal: 3x$usedwords=$minlength))(DEFAULT: $passwordLength)..."
    if($inputpasswordlength) { 
        $passwordLength = $inputpasswordlength 
    } 
} until ($passwordlength -ge $minlength)


Write-Host "CRUNCHING... Generate $passwords Random Human Readable passwords of $passwordLength chars..." -ForegroundColor Green 
$stopwatch2 = [System.Diagnostics.Stopwatch]::StartNew()

for ($i = 0; $i -lt $passwords; $i++)
{ 
    Get-RandomPassEx -totallength $passwordLength -totalwords $usedwords
}
$stopwatch2.stop()
write-host "`nGenerated $i passwords of length $passwordLength in $($stopwatch2.Elapsed.TotalSeconds) seconds..." -ForegroundColor Cyan
pause "Press Any Key to continue..."
