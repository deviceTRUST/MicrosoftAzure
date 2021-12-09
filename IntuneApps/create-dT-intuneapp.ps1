param(

    [Parameter(Mandatory)]$InputFolder,
    [Parameter(Mandatory)][ValidateSet("dtclient","dtagent","dtconsole","dtpol")]$SoftwareType,
    [Parameter()]$InstallGroup,
    [Parameter()]$UninstallGroup

)

# Import modules if not available
if(-NOT (Get-Module IntuneWin32App)){Import-Module IntuneWin32App}
if(-NOT (Get-Module AzureAD)){Import-Module AzureAD}

# Connect to MSIntuneGraph and use Enterprise Application
Connect-MSIntuneGraph -TenantID $YourTenantID | Out-Null

# Check if AzureAD is connected. If not, connect.
try 
    {$var = Get-AzureADTenantDetail} 

catch [Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException] 
    {Write-Host "You're not connected."; Connect-AzureAD}

# Package MSI as .intunewin file / Verbose switch is optional
$SetupFile = (Get-ChildItem $InputFolder -recurse | Where-Object{$_.name -match $SoftwareType -and ($_.Extension.Split(".")[1] -eq "msi" -or $_.Extension.Split(".")[1] -eq "exe" -or $_.Extension.Split(".")[1] -eq "cmd")})
[string]$SetupType = $SetupFile.Extension.Split(".")[1]
[string]$SetupFileName = [string]$SetupFile.Basename
[string]$SetupFileFolder = [string]$SetupFile.DirectoryName

if(-Not (Get-ChildItem $SetupFileFolder | Where-Object{$_.Extension -eq ".intunewin" -AND $_.name -match $SoftwareType})){$Win32AppPackage = New-IntuneWin32AppPackage -SourceFolder $SetupFileFolder -SetupFile $SetupFile -OutputFolder $SetupFileFolder -Verbose}

# Get meta data from .intunewin file
$IntuneWinFile = (Get-ChildItem $SetupFileFolder | Where-Object{$_.Extension -eq ".intunewin" -AND $_.name -match $SoftwareType}).FullName
$IntuneWinMetaData = Get-IntuneWin32AppMetaData -FilePath $IntuneWinFile

switch($SetupType){
    exe{

        # Create DisplayName, Publisher and Descriptioninformation
        [string]$DisplayName = "deviceTRUST Client Extension"
        [string]$Publisher = "deviceTRUST GmbH"
        [string]$Description = $DisplayName

        # Read the product version from the file name
        [string]$ProductVersion = $SetupFileName | Select-String '(?:\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})' | ForEach-Object {$_.Matches[0].Value}

        # Create detection rule
        $DetectionRule = New-IntuneWin32AppDetectionRuleFile -Existence -Path "C:\Program Files\deviceTRUST\Client\Bin" -FileOrFolder "dtclient_service.exe" -Detectiontype exists

        # Add new EXE Win32 app
        [string]$InstallCommandLine = $SetupFileName + " /quiet"
        [string]$UninstallCommandLine = $SetupFileName + " /uninstall /quiet"        
        
        # Add new MSI Win32 app / Verbose switch is optional
        if(-Not (Get-IntuneWin32App -DisplayName $DisplayName)){

            $Win32App = Add-IntuneWin32App -FilePath $IntuneWinFile -AppVersion $ProductVersion -DisplayName $DisplayName -Description $Description -Publisher $Publisher -InstallExperience "system" -RestartBehavior "suppress" -DetectionRule $DetectionRule -InstallCommandLine $InstallCommandLine -UninstallCommandLine $UninstallCommandLine -Verbose

            $AppID = $Win32App.id

        } else {

            Write-Output "### An App with this name is already available. Please review your input information and try again. ###"

        }

    }
    msi{

        # Create ProductCode, ProductVersion, FileName, DisplayName, Publisher and Description information
        [string]$ProductCode = $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductCode
        [string]$ProductVersion = $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductVersion
        [string]$DisplayName = $IntuneWinMetaData.ApplicationInfo.Name + " " + $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductVersion
        [string]$DisplayName = $DisplayName.Replace($ProductVersion,"")
        [string]$Publisher = $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiPublisher
        [string]$Description = $DisplayName        

        # Create PowerShell script detection rule
        $DetectionRule = New-IntuneWin32AppDetectionRuleMSI -ProductCode $ProductCode -ProductVersionOperator "greaterThanOrEqual" -ProductVersion $ProductVersion

        # Add new MSI Win32 app / Verbose switch is optional
        if(-Not (Get-IntuneWin32App -DisplayName $DisplayName)){

            $Win32App = Add-IntuneWin32App -FilePath $IntuneWinFile -DisplayName $DisplayName -Description $Description -AppVersion $ProductVersion -Publisher $Publisher -InstallExperience "system" -RestartBehavior "suppress" -DetectionRule $DetectionRule -Verbose

            $AppID = $Win32App.id

        } else {

            Write-Output "### An App with this name is already available. Please review your input information and try again. ###"

        }

    }
    cmd{

        # Create FileName, DisplayName, Publisher and Description information
        [string]$FileName = (Get-ChildItem $InputFolder| Where-Object{$_.Extension -eq ".dtpol"}).Name
        [string]$DisplayName = "deviceTRUST - Policy - " + $FileName.Split(".")[0]
        [string]$Publisher = "deviceTRUST Gmbh"
        [string]$Description = "Policy File $DisplayName"

        # Create detection rule
        $DetectionRule = New-IntuneWin32AppDetectionRuleFile -Existence -Path "C:\ProgramData\deviceTRUST\Policy" -FileOrFolder $FileName -Detectiontype exists

        # Create installation and uninstallation commands
        $InstallCommandLine = "manage-dtpol.cmd -install"
        $UninstallCommandLine = "manage-dtpol.cmd -Uninstall"

        # Add new MSI Win32 app / Verbose switch is optional
        if(-Not (Get-IntuneWin32App -DisplayName $DisplayName)){

            $Win32App = Add-IntuneWin32App -FilePath $IntuneWinFile -DisplayName $DisplayName -Description $Description -AppVersion $ProductVersion -Publisher $Publisher -InstallExperience "system" -RestartBehavior "suppress" -DetectionRule $DetectionRule -InstallCommandLine $InstallCommandLine -UninstallCommandLine $UninstallCommandLine #-Verbose
            
            $AppID = $Win32App.id

        } else {

            $BGColor = $host.ui.RawUI.BackgroundColor
            $host.ui.RawUI.BackgroundColor = "DarkRed"
            Write-Output "### An App with this name is already available. Please review your input information and try again. ###"
            $host.ui.RawUI.BackgroundColor = $BGColor           

        }

    }
}

# Add install assignment for selected group, if available
if($InstallGroup -ne $null -and $AppID -ne $null){

    if($InstallGroupID = (Get-AzureADGroup | Where-Object{$_.DisplayName -eq [string]$InstallGroup}).ObjectID){

        Add-IntuneWin32AppAssignmentGroup -Include -ID $AppID -GroupID $InstallGroupID -Intent required -Notification hideall | Out-Null

    }

}

# Add Uninstall assignment for selected group, if available
if($UninstallGroup -ne $null -and $AppID -ne $null){
    
    if($UninstallGroupID = (Get-AzureADGroup | Where-Object{$_.DisplayName -eq [string]$UninstallGroup}).ObjectID){

        Add-IntuneWin32AppAssignmentGroup -Include -ID $AppID -GroupID $UninstallGroupID -Intent required -Notification hideall | Out-Null

    }

}