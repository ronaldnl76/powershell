<##########################################################################
#
# Name: Netstat-Connections
#
# Desc: Get netstat connections with processname sorted on processID
#
# Date: 24-07-2023
#
# By:
#         |~) _  _  _ | _|  |~).. _  _|  _  _| 
#         |~\(_)| |(_||(_|  |~\||(/_| |<(/_| |<
#                              L|  
#
# CHANGE LOG
# Versie 0.1             - Intial version
###########################################################################>

# Run Netstat and 
$netstatoutput = netstat -aon #| Select-String -pattern "(TCP|UDP)"
$netstattcp = $netstatoutput[4..$netstatoutput.count] | select-string -pattern "TCP" | convertfrom-string | select p2,p3,p4,p5,p6
$netstatudp = $netstatoutput[4..$netstatoutput.count] | select-string -pattern "UDP" | convertfrom-string | select p2,p3,p4,p5
$processList = Get-Process

$connections = @()

# Extract all TCP connections
foreach ($result in $netstattcp) {

   if (-not ($result.p3.StartsWith("["))) {

      $procID = $result.p6
      $processName = $processList | Where-Object {$_.id -eq $procID} | select processname
      $prot = $result.p2
      $localip = ($result.p3 -split ':')[0]
      $localport = ($result.p3 -split ':')[1]
      $remoteip = ($result.p4 -split ':')[0]
      $remoteport = ($result.p4 -split ':')[1]
      $state = $result.p5

      $connection = [pscustomobject] @{
         procID = $procID
         procName = $processName.ProcessName
         prot = $prot
         localip = $localip
         localport = $localport
         remoteip = $remoteip 
         remoteport = $remoteport
         state = $state
      }

      $connections += $connection
   }
}

# Extract all UDP connections (no connection State because it is UDP)
foreach ($result in $netstatudp) {

   if (-not ($result.p3.StartsWith("["))) {

      $procID = $result.p5
      $processName = $processList | Where-Object {$_.id -eq $procID} | select processname
      $prot = $result.p2
      $localip = ($result.p3 -split ':')[0]
      $localport = ($result.p3 -split ':')[1]
      $remoteip = ($result.p4 -split ':')[0]
      $remoteport = ($result.p4 -split ':')[1]
   
      $connection = [pscustomobject] @{
         procID = $procID
         procName = $processName.ProcessName
         prot = $prot
         localip = $localip
         localport = $localport
         remoteip = $remoteip 
         remoteport = $remoteport
         state = ""
      }

      $connections += $connection  
   }
}

# Output all connections to gridview, sorted on state and then on prodID
$connections | Sort-Object state,procID | out-gridview
