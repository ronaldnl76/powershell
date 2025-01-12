<##########################################################################
# SCRIPT METADATA
#
# Desc: MSI-Install-Wrapper
#
# Version: 1.0
# Date   : 12-1-2025
# By     :
#         |~) _  _  _ | _|  |~).. _  _|  _  _| 
#         |~\(_)| |(_||(_|  |~\||(/_| |<(/_| |<
#                              L|  
##########################################################################>
param (
    [string]$APP,
    [string]$MSI,
    [string]$ARG,
    [string]$VER,
    [int]$VERSEARCH #0 = x64, 1 = x86, 2 = all
)

$APP = $APP.ToUpper()

# Check if user has write access to an folder.

function Test-WritePermission {
    param (
        [string]$Path
    )

    try {
        # Get the DirectoryInfo object for the specified path
        $directoryInfo = New-Object System.IO.DirectoryInfo($Path)

        # Get the access control for the directory
        $acl = $directoryInfo.GetAccessControl()

        # Get the access rules (NTFS permissions) for the current user
        $rules = $acl.GetAccessRules($true, $true, [System.Security.Principal.SecurityIdentifier])

        # Get the current user's identity
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()

        foreach ($rule in $rules) {
            # Check if the rule applies to the current user or their groups
            if ($currentUser.User.Equals($rule.IdentityReference) -or $currentUser.Groups -contains $rule.IdentityReference) {
                # Check if the rule grants write permissions
                if (($rule.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Write) -and $rule.AccessControlType -eq [System.Security.AccessControl.AccessControlType]::Allow) {
                    return $true
                }
            }
        }
        
        return $false
    } catch {
        return $false
    }
}

# Get path to put log file. (First SCCM --> Windows Log Path --> Users Tempfolder )
$logpath = "C:\Windows\CCM\Logs"
if (-Not (Test-Path $logpath)) {
    if (Test-WritePermission -Path "C:\Windows\Logs") {
        $logpath = "C:\Windows\Logs"
    } else {
        $logpath = [System.IO.Path]::GetTempPath()
    }
} 
$Logfile = "$logpath\GDH-$APP.log"

Function Log {  
   Param ([string]$logstring)
   $DateTime = (Get-Date).ToString("g")
   $DTlogstring = $DateTime + ": $logstring"
   Add-content $Logfile -value $DTlogstring
   Write-host $DTlogstring
}

# SPECIFIC FUNCTIONS

# Get Installed App Version - Only Return 1!
function GetInstalledVersionEx() {
        Param (
            [string]$appname,
            [int]$bits = 2 #0 = x64, 1 = x86, 2 = all
        )
        
        $Apps = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
        $Apps32 = Get-ChildItem 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'

        switch ($bits){
            0 { $allapps = $apps }
            1 { $allapps = $apps32 }
            2 { $allapps = $apps + $apps32 }
        }

        $installedversion = $null
        $foundAppName = $null

        foreach ($App in $AllApps) {
            $disp = (Get-ItemProperty $App.pspath).displayname
            $curdisplayversion = (Get-ItemProperty $App.pspath).displayversion
            
            if ($disp -like "*$appname*") {
                $installedversion = $curdisplayversion
                $foundAppName = $disp
                return @{ AppName = $foundAppName; Version = $installedversion }
            }
        }

        return $null
}

#region Check if Install Needed
$needstoinstall = $true
$appfound = GetInstalledVersionEx -appname $APP -bits $VERSEARCH
if ($appfound) {
    if ([version]$appfound.Version -ge [version]$VER) {
        Log "[INFO] $APP has allready been installed, skip installation."
        $needstoinstall = $false
    } else {
        Log "[INFO] $APP has allready been installed, but needs to be upgraded..."
    }      
}

try {
    if ($needstoinstall) {
        $srcMSI = "$psscriptroot\$MSI"
        Log "[INFO] - Start installing $APP to version: $VER"
        
        $argss = "/I $srcMSI $ARG"
        Log "[INFO] - Starting commandline: MSIEXEC.EXE $argss"
        [microsoft.win32.registry]::SetValue("HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Installer", "Logging", "voicewarmupx")
        $exitcode = (Start-Process -Filepath "msiexec.exe" -ArgumentList $argss -Wait -PassThru).ExitCode
        Log "[INFO] - Finished installing $APP to version: $VER - Exitcode: $exitcode"
        if ($exitcode -ne 0) {
            Log "[WARNING] - Check MSI log in $($ENV:Temp)"    
        }
    }
}
catch {
    Log "[ERROR] - Something went wrong $_"
    Log "[ERROR] - Check MSI log in $($ENV:Temp)"
}
finally {
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer" -Name "Logging" -ea 0 
}