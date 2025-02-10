#Requires -RunAsAdministrator

Function Set-WebProxyAutoDiscovery {
    <#
    .SYNOPSIS
        Enables or disables Web Proxy Auto-Discovery (WPAD).

    .DESCRIPTION
        This function modifies the registry to enable or disable Web Proxy Auto-Discovery (WPAD).

    .PARAMETER Enable
        A boolean value indicating whether to enable (true) or disable (false) WPAD.

    .EXAMPLE
        Set-WebProxyAutoDiscovery -Enable $false

    .EXAMPLE
        Set-WebProxyAutoDiscovery -Enable $true

    .INPUTS
        None.  Set-WebProxyAutoDiscovery does not accept pipeline input.

    .OUTPUTS
        None.

    .NOTES
        Author: Raymond Jette
        Created: 2/10/2025
        https://github.com/rayjette
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory)]
        [bool]$Enable
    )


    # Function to remove registry keys if they exist
    Function Remove-RegistryValueIfExist {
        param (
            [string]$path,
            [string]$key
        )
        try {
            # Check if the registry key exists using Get-ItemProperty
            Get-ItemProperty -Path $path -Name $key -ErrorAction Stop | Out-Null
            
            # If the registry key exists, remove it
            Remove-ItemProperty -Path $path -Name $key -ErrorAction Stop
        } catch {
            # If the registry key doesn't exist, write a warning
        }
    }


    # Function to get current registry value or return null
    Function Get-RegistryValue {
        param (
            [string]$path,
            [string]$key
        )
        try {
            Get-ItemProperty -path $path -Name $key -ErrorAction Stop | Select-Object -ExpandProperty $key
        } catch {
            $null
        }
    }

    # Registry Paths and Keys
    $regPathMachine = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\WinHTTP"
    $regPathUser = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings"
    $regNameDisableWpad = "DisableWpad"
    $regNameAutoDetect = "AutoDetect"

    try {
        if ($Enable) {
            # Enabling WPAD
            if ($PSCmdlet.ShouldProcess("Enabling Web Proxy Auto-Discovery (WPAD)")) {
                # Remote registry keys if they exist
                Remove-RegistryValueIfExist $regPathMachine $regNameDisableWpad
                Remove-RegistryValueIfExist $regPathUser $regNameAutoDetect  
            }
        } else {
            # Disabling WPAD
            $disableWpadValue = Get-RegistryValue $regPathMachine $regNameDisableWpad
            $autoDetectValue = Get-RegistryValue $regPathUser $regNameAutoDetect

            # Set DisableWpad if not already set
            if ($disableWpadValue -ne 1) {
                if ($PSCmdlet.ShouldProcess("Disabling Web Proxy Auto-Discovery (WPAD)")) {
                    if (-not (Test-Path $regPathMachine)) {
                        New-Item -Path $regPathMachine -Force | Out-Null
                    }
                    Set-ItemProperty -Path $regPathMachine -Name $regNameDisableWpad -Value 1 -Force
                }
            }

            # Set AutoDetect if it's not already set
            if ($autoDetectValue -ne 0) {
                if (-not (Test-Path $regPathUser)) {
                    New-Item -Path $regPathUser -Force | Out-Null
                }
                Set-ItemProperty -Path $regPathUser -Name $regNameAutoDetect -Value 0 -Force
            }
        }
    } catch {
        Write-Error "Failed to set Web Proxy Auto-Discovery (WPAD): $_"
    }
}