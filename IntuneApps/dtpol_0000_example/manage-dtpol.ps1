param(
    [Parameter(Mandatory)]
    [ValidateSet("Install","Uninstall")]
    $Mode
)

$PSScriptRoot = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition

$Destination = "C:\ProgramData\deviceTRUST\Policy\"

switch($Mode){
    Install{
        $SourceFilePath =  (Get-ChildItem $PSScriptRoot | Where-Object{$_.Extension -eq ".dtpol"}).FullName
        Copy-Item -Path $SourceFilePath -Destination $Destination -Force
    }
    Uninstall{
        $RemovePath = $Destination + (Get-ChildItem $PSScriptRoot | Where-Object{$_.Extension -eq ".dtpol"}).Name
        Remove-Item $RemovePath -Force
    }
}