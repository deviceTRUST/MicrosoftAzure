![dt-logo-full-aot-space-w1280](https://user-images.githubusercontent.com/83282694/116271495-5219b100-a780-11eb-9e1a-f929d2e3cbdc.png)
# Intune
This section contains scripts and elements for bringing the deviceTRUST installation and config files to your Intune managed devices. It has been developed based on Nickolaj Andersens (@NickolajA) great "IntuneWin32App" PowerShell Module: https://github.com/MSEndpointMgr/IntuneWin32App. Using the module is a requirement for our config to be applied.


```PowerShell
Install-Module -Name IntuneWin32App
```

```Json
"Information": {
    "DisplayName": "AppName 1.0.0",
    "Description": "Installs AppName 1.0.0",
    "Publisher": "AppVendor",
    "Notes": "AppNote"
}
```