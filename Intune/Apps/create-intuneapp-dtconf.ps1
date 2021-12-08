param(

    [Parameter(Mandatory)]$InputFolder,
    [Parameter()]$InstallGroup,
    [Parameter()]$UninstallGroup

)

if(-NOT (Get-Module IntuneWin32App)){Import-Module IntuneWin32App}
if(-NOT (Get-Module AzureAD)){Import-Module AzureAD}

Connect-MSIntuneGraph -TenantID 07c7e7f5-210d-4fc6-bd6d-929caf1e3b61

try 
{ $var = Get-AzureADTenantDetail } 

catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] 
{ Write-Host "You're not connected."; Connect-AzureAD}

# Package MSI as .intunewin file / Verbose switch is optional
$SetupFile = (Get-ChildItem $InputFolder| Where-Object{$_.Extension -eq ".cmd"}).Name
$Win32AppPackage = New-IntuneWin32AppPackage -SourceFolder $InputFolder -SetupFile $SetupFile -OutputFolder $InputFolder # -Verbose

# Get MSI meta data from .intunewin file
$IntuneWinFile = (Get-ChildItem $InputFolder| Where-Object{$_.Extension -eq ".intunewin"}).FullName
$IntuneWinMetaData = Get-IntuneWin32AppMetaData -FilePath $IntuneWinFile

# Create custom display name like 'Name' and 'Version'
$FileName = (Get-ChildItem $InputFolder| Where-Object{$_.Extension -eq ".dtpol"}).Name
$DisplayName = "deviceTRUST - Policy - " + $FileName.SPlit(".")[0]
$Publisher = "deviceTRUST Gmbh"

# Create custom description
$Description = "Policy File $DisplayName"

# Create detection rule
$DetectionRule = New-IntuneWin32AppDetectionRuleFile -Existence -Path "C:\ProgramData\deviceTRUST\Policy" -FileOrFolder $FileName -Detectiontype exists

# Create installation command
$InstallCommandLine = "manage-dtpol.cmd -install"

# Create Uninstallation command
$UninstallCommandLine = "manage-dtpol.cmd -Uninstall"

# Add new MSI Win32 app / Verbose switch is optional
if(-Not (Get-IntuneWin32App -DisplayName $DisplayName)){

    $Win32App = Add-IntuneWin32App -FilePath $IntuneWinFile -DisplayName $DisplayName -Description $Description -Publisher $Publisher -InstallExperience "system" -RestartBehavior "suppress" -DetectionRule $DetectionRule -InstallCommandLine $InstallCommandLine -UninstallCommandLine $UninstallCommandLine #-Verbose
    
    $AppID = $Win32App.id

} else {

    Write-Output "### An App with this name is already available. Please review your input information and try again. ###"

}

# Add install assignment for selected group, if available
if(($InstallGroup -ne $null) -and ($AppID -ne $null)){

    if($InstallGroupID = (Get-AzureADGroup | Where-Object{$_.DisplayName -eq [string]$InstallGroup}).ObjectID){

        Add-IntuneWin32AppAssignmentGroup -Include -ID $AppID -GroupID $InstallGroupID -Intent required -Notification hideall    

    }

}

# Add Uninstall assignment for selected group, if available
if(($UninstallGroup -ne $null) -and ($AppID -ne $null)){
    
    if($UninstallGroupID = (Get-AzureADGroup | Where-Object{$_.DisplayName -eq [string]$UninstallGroup}).ObjectID){

        Add-IntuneWin32AppAssignmentGroup -Include -ID $AppID -GroupID $UninstallGroupID -Intent uninstall -Notification hideall    

    }

}