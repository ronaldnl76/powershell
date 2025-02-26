<##########################################################################
# SCRIPT METADATA
#
# Human Readable Password Generator
#
# Version: 1.4
# Date   : 17-02-2025
# By     :
#         |~) _  _  _ | _|  |~).. _  _|  _  _| 
#         |~\(_)| |(_||(_|  |~\||(/_| |<(/_| |<
#                              L|  
##########################################################################>
# Wordbank from: https://www.opentaal.org/ (deleted some swear words) 
# Version 1.2 - Added # amount of words which should be concatenated
# Version 1.3 - Added sort list on length + index search
# Version 1.4 - Fixed Index and added number and special char

Param(
    [int]$passwords = 10,
	[int]$usedwords = 3,
    [int]$passwordLength = 30,
	[string]$wordlist = "words(english).txt",
    [string]$wordlistsort = "words(englishsorted).txt",
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

clear-host
$version = "1.4"
$specialchars = [char[]]'''-!"#$%&()*,./:;?@[]^_`{|}~+<=>'
$pathwordlist = "$curpath\$wordlist"
$pathwordlistsort = "$curpath\$wordlistsort"
$pathindexfile = "$curpath\$indexfile"

Write-Host "--------------------------------------------------------------------------" -ForegroundColor Green
Write-Host "--- Human Readable Password Generator superfast version $version"           -ForegroundColor Green
Write-Host "--------------------------------------------------------------------------" -ForegroundColor Green


function CreateIndex {
    param (
        [Parameter(Mandatory=$true)]
        [string[]] $array
    )

    [string[]] $ind = @() | Out-Null
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
   
    return $ind    
}



if(!$bank) {
    if (!(Test-Path $pathwordlistsort)) {
        write-host "Sort wordlist on length so next time creating passwords will be much faster" -ForegroundColor Cyan
        $stopwatch3 = [System.Diagnostics.Stopwatch]::StartNew()
        $Bank = Get-Content $pathwordlist

        $Bank = $Bank | Sort-Object { $_.Length }
        



        #[System.Array]::Sort($bank, [System.Collections.Generic.Comparer[Object]]::Create(
        #    { param ($x, $y)
        #        $x.Length.CompareTo($y.Length)
        #    }
        #))
        
        $stopwatch3.stop()
        
        $bank | Add-Content -Path $pathwordlistsort

        write-host "Sorted wordlist in $($stopwatch3.Elapsed.TotalSeconds) seconds..." -ForegroundColor Cyan
    } else {
        $bank = Get-Content $pathwordlistsort
    }
    
}

write-host "--- Loading: $wordlistsort ..." -ForegroundColor Yellow



[string[]] $index = @()

if (!$index) {
    if(!(Test-Path $pathindexfile)) {
            write-host "--- Creating Index: $indexfile ..." -ForegroundColor Yellow
        $index = CreateIndex $bank
        $index | Add-Content $pathindexfile
    } else {
        write-host "--- Loading Index: $indexfile ..." -ForegroundColor Yellow
        $index = Get-Content $pathindexfile
    }
}

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
        [int]$totalwords = 3,
        [int]$minWordLength = 3,
        [bool]$bnum = $true,
        [bool]$bchar = $true
    )

    [string]$Password

	$words = New-Object System.Collections.ArrayList

	# Controleer of het aantal woorden logisch is binnen de totale lengte
	if ($totalwords * $minWordLength -gt $totallength) {
		Write-Host "Error: Niet genoeg ruimte om elk woord minstens $minWordLength tekens te geven!"
		exit
	}

	# Stap 1: Begin met elk woord op de minimale lengte
	$lengths = @()
	for ($i = 0; $i -lt $totalwords; $i++) {
		$lengths += $minWordLength
	}

	# Stap 2: Verdeel de resterende lengte willekeurig
	$remainingLength = $totallength - ($totalwords * $minWordLength)

	while ($remainingLength -gt 0) {
		$index = Get-Random -Minimum 0 -Maximum $totalwords
		$lengths[$index]++
		$remainingLength--
	}
    
    # Stap 3: Genereer woorden met de bepaalde lengtes
    for ($j = 0; $j -lt $totalwords; $j++) { 
        $word = Get-RandomWordEx -length $lengths[$j]
        $words.Add($word) | Out-Null
    }
    
    foreach ($word in $words) {
        $password += $word
    }
    
    if ($bnum) {
        $Number = "{0:d2}" -f (Get-Random -Minimum 0 -Maximum 99)
        $Password += $Number
    }
    
    if ($bchar) {
        $special = $script:Specialchars | Get-Random
        $Password += $Special
    }
    
    
    return $Password
}


$inputpasswords = Read-Host "Please enter amount of passwords which should be generated (DEFAULT: $passwords)..."
if($inputpasswords) { 
    $passwords = $inputpasswords 
}

$inputwords = Read-Host "Please enter amount of words the passwords should contain (DEFAULT: $usedwords)..."
if($inputwords) { 
    [int]$usedwords = $inputwords 
}

$minlength = 3 * ($usedwords)
do {
    [int]$inputpasswordlength = Read-Host "Please enter length of the passwords which should be generated (minimal: 3x$usedwords=$minlength))(DEFAULT: $passwordLength)..."
    if($inputpasswordlength) { 
        $passwordLength = $inputpasswordlength
    } 
} until ($passwordLength -ge $minlength)


$bnum = $true
$inputChars = Read-Host "Do you want a number at the end of the password? (DEFAULT: yes)..."
if ($inputChars -match "^(?i)(n|no)$") {
    $bnum = $false
}

$bchar = $true
$inputChars = Read-Host "Do you want a special char at the end of the password? (DEFAULT: yes)..."
if ($inputChars -match "^(?i)(n|no)$") {
    $bchar = $false
}

Write-Host "CRUNCHING... Generate $passwords Random Human Readable passwords of $passwordLength chars..." -ForegroundColor Green 
$stopwatch2 = [System.Diagnostics.Stopwatch]::StartNew()

for ($i = 0; $i -lt $passwords; $i++)
{ 
    Get-RandomPassEx -totallength $passwordLength -totalwords $usedwords -bnum $bnum -bchar $bchar
}
$stopwatch2.stop()
write-host "`nGenerated $i passwords of length $passwordLength in $($stopwatch2.Elapsed.TotalSeconds) seconds..." -ForegroundColor Cyan
pause "Press Any Key to continue..."
