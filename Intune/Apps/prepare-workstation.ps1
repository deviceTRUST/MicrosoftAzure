### If not already installed, install the required PowerShell Modules
# IntuneWin32App https://github.com/MSEndpointMgr/IntuneWin32App
if(-not (Get-Module 'IntuneWin32App')){Install-Module 'IntuneWin32App' -Force}

# AzureAD
if(-not (Get-Module 'AzureAD')){Install-Module 'AzureAD' -Force}

# Microsoft.Graph.Intune
if(-not (Get-Module 'Microsoft.Graph.Intune')){Install-Module 'Microsoft.Graph.Intune' -Force}

### Connect to MSGraph and generate Enterprise Application
Connect-MSGraph -AdminConsent

### Restart your administrative PoerShel Ssession and you're good to go!