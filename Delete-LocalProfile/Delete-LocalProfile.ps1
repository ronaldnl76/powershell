
<#################################################################################

Script name: Delete-LocalProfile.ps1
Usage      : Delete Local Profile (optional roaming profile)
Author     : R. Rijerkerk
Date       : 24-05-2019
Version    : 0.1
##################################################################################>

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")  

$Form = New-Object System.Windows.Forms.Form    
$Form.Size = New-Object System.Drawing.Size(600,500)  
$Form.Text = "DeleteProfile"

$DomainName = (Get-ADDomain -Current LocalComputer).Name
$key = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'

############################################## Start functions
function GetProfiles
{

   $profiles = (Get-Item $key).GetSubKeyNames()
   foreach ($prof in $profiles)
   {
      $userdir = (Get-ItemProperty -Path "$key\$prof" -Name ProfileImagePath).ProfileImagePath
      


      $lb1.Items.Add($userdir + " :: " + $prof)
   }
}

function dellocprof()
{
   for($i = $lb1.SelectedItems.Count -1; $i -ge 0; $i--)
   {
        
        $split = $lb1.SelectedItems[$i] -split " :: "
        $userdir = $split[0]
        $sid = $split[1]

        try 
        { 
            
            takeown /f "$userdir" /r /d y
            Remove-Item  path $userdir  recurse
            $lb1.items.Remove($lb1.SelectedItems[$i])
            Remove-ItemProperty -Path $key -Name $sid -Force
            $lb2.Items.Add("Deleted profile: " + $userdir + " succesfully!")

        }
        catch 
        {
            write-host "An error occurred: " + $_
            $lb2.Items.Add("An error occurred: " + $_)
        }


        
   }
   $lb1.Update()
}

############################################## end functions

############################################## Start Label fields

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Size(20,30) 
$label.Size = New-Object System.Drawing.Size(180,20) 
$label.Text = "Select Profile to delete:"
$Form.Controls.Add($label) 

############################################## end label fields


############################################## Start Listbox fields

$lb1 = New-Object System.Windows.Forms.Listbox
$lb1.Location = New-Object System.Drawing.Size(10,50) 
$lb1.Size = New-Object System.Drawing.Size(565,200) 
$lb1.Height = 200
$lb1.Sorted = $true
$lb1.SelectionMode = 'MultiExtended'
$Form.Controls.Add($lb1) 


$lb2 = New-Object System.Windows.Forms.Listbox
$lb2.Location = New-Object System.Drawing.Size(10,320) 
$lb2.Size = New-Object System.Drawing.Size(565,140) 

$Form.Controls.Add($lb2) 

############################################## end Listbox fields

############################################## Start buttons

$Button1 = New-Object System.Windows.Forms.Button 
$Button1.Location = New-Object System.Drawing.Size(10,260) 
$Button1.Size = New-Object System.Drawing.Size(100,50) 
$Button1.Text = "Delete Local Profile" 
$Button1.Add_Click({dellocprof}) 
$Form.Controls.Add($Button1) 

$Button2 = New-Object System.Windows.Forms.Button 
$Button2.Location = New-Object System.Drawing.Size(475,260) 
$Button2.Size = New-Object System.Drawing.Size(100,50) 
$Button2.Text = "Delete Roaming Profile" 
$Button2.Add_Click({delroamprof}) 
$Form.Controls.Add($Button2) 

############################################## end buttons
GetProfiles
$Form.Add_Shown({$Form.Activate()})
[void] $Form.ShowDialog()