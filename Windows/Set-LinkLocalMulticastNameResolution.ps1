#Requires -RunAsAdministrator

Function Set-LinkLocalMulticastNameResolution {
    <#
    .SYNOPSIS
        Enables or disables Link-Local Multicast Name Resolution (LLMNR).

    .DESCRIPTION
        This function modifies the registry to enable or disable Link-Local Multicast Name Resolution (LLMNR).

    .PARAMETER Enable
        A boolean value indicating whether to enable (true) or disable (false) LLMNR.

    .EXAMPLE
        Set-LinkLocalMulticastNameResolution -Enable $false

    .EXAMPLE
        Set-LinkLocalMulticastNameResolution -Enable $true

    .INPUTS
        None.  Set-LinkLocalMulticastNameResolution does not accept pipeline input.

    .OUTPUTS
        None.

    .NOTES
        Author: Raymond Jette
        Created: 2/10/2025
        https://github.com/rayjette

    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true)]
        [bool]$Enable
    )

    $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
    $regName = "EnableMulticast"

    try {
        # Check if the registry key exists
        if (-not (Test-Path $regPath)) {
            # Create the registry key if it doesn't exist
            New-Item -Path $regPath -Force | Out-Null
        }

        # Get the current value of EnableMulticast
        $currentValue = $null

        # Try to get the current value of EnableMulticast
        try {
            $currentValue = Get-ItemProperty -Path $regPath -Name $regName -ErrorAction Stop | Select-Object -ExpandProperty $regName
        } catch {
            # If the property does not exist, set currentValue to null
            $currentValue = $null
        }

        # Set the EnableMulticast value only if it is different from the desired value
        $desiredValue = if ($Enable) { 1 } else { 0 }
        if ($currentValue -ne $desiredValue) {
            if ($PSCmdlet.ShouldProcess("Setting Link-Local Multicast Name Resolution", "Value: $desiredValue")) {
                if ($desiredValue -eq 1) {
                    Write-Verbose "Enabling Link-Local Multicast Name Resolution"
                } else {
                    Write-Verbose "Disabling Link-Local Multicast Name Resolution"
                }
                Set-ItemProperty -Path $regPath -Name $regName -Value $desiredValue -Force
            }
        } else {
            $status = if ($Enable) { 'enabled' } else { 'disabled' }
            Write-Warning "Link-Local Multicast Name Resolution is already $status.  No changes made."
        }
    } catch {
        Write-Error "Failed to set Link-Local Multicast Name Resolution: $_"
    }
}