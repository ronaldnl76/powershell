<#
.SYNOPSIS
    Get netstat connections with processname sorted on processID and name, then show them in GridView
.DESCRIPTION
    This script run's default Netstat on a Windows Device and converts it to an powershellobject.  
    It also adds the process per netstat connection to this object.  
    Then it adds all connection objects to an array and export it to a Gridview.

.OUTPUTS
    None
        By default, this cmdlet returns no output.

.NOTES
    Information or caveats about the function e.g. 'This function is not supported in Linux'
    Optimized code thanks to: u/ankokudaishogun
.LINK
    https://github.com/ronaldnl76/powershell
#>

# Always useful, even when the more advanced features get unused.
[CmdletBinding()]
param ()

# Run Netstat and 
$netstatoutput = netstat -aon #| Select-String -pattern "(TCP|UDP)"
$netstattcp = $netstatoutput[4..$netstatoutput.count] | select-string -pattern "TCP" | convertfrom-string | select p2,p3,p4,p5,p6
$netstatudp = $netstatoutput[4..$netstatoutput.count] | select-string -pattern "UDP" | convertfrom-string | select p2,p3,p4,p5
$processList = Get-Process

# Extract all TCP connections
$ConnectionListTCP = foreach ($result in $netstattcp) {

    if (-not ($result.p3.StartsWith('['))) {

        $procID = $result.p6
        $proc = $processList | Where-Object { $_.id -eq $procID } | Select-Object processname, path
        $prot = $result.p2
        $localip = ($result.p3 -split ':')[0]
        $localport = ($result.p3 -split ':')[1]
        $remoteip = ($result.p4 -split ':')[0]
        $remoteport = ($result.p4 -split ':')[1]
        $state = $result.p5

        [pscustomobject] @{
            procID     = $procID
            procName   = $proc.ProcessName
            prot       = $prot
            localip    = $localip
            localport  = $localport
            remoteip   = $remoteip 
            remoteport = $remoteport
            state      = $state
            path       = $proc.path
        }

    }
}

# Extract all UDP connections (no connection State because it is UDP)
$ConnectionListUPD = foreach ($result in $netstatudp) {

    if (-not ($result.p3.StartsWith('['))) {

        $procID = $result.p5
        $proc = $processList | Where-Object { $_.id -eq $procID } | Select-Object processname, path
        $prot = $result.p2
        $localip = ($result.p3 -split ':')[0]
        $localport = ($result.p3 -split ':')[1]
        $remoteip = ($result.p4 -split ':')[0]
        $remoteport = ($result.p4 -split ':')[1]

        [pscustomobject] @{
            procID     = $procID
            procName   = $proc.ProcessName
            prot       = $prot
            localip    = $localip
            localport  = $localport
            remoteip   = $remoteip 
            remoteport = $remoteport
            state      = ''
            path       = $proc.path
        }

    }
}

# Output all connections to gridview, sorted on state and then on procName
$ConnectionListTCP + $ConnectionListUPD | Sort-Object state, procName | Out-GridView -Title 'Netstat Connections'
