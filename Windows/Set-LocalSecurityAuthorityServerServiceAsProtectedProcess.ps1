#Requires -RunAsAdministrator

Function Set-LocalSecurityAuthorityServerServiceAsProtectedProcess {
    <#
    .SYNOPSIS
        Enables or disables the Local Security Authority Server services to run as a protected process.

    .DESCRIPTION
        This functions configured the Local Security Authority Server service (LSASS) to run as a protected process by modifying the registry.
        It can enable or disable this feature based on the provided parameters. The service can either be configured to use a UEFI variable or to operate without it, depending on the user's preference.

    .PARAMETER Enable
        A switch parameter that enables the Local Security Authority Server service to run as a protected process.
        By default, the service will be configured to use a UEFI variable when enabled.  To enable the service without using a UEFI variable, use the `DontUseUEFIVariable` parameter.

    .PARAMETER Disable
        A switch parameter that disables the Local Security Authority Server service from running as a protected process.

    .PARAMETER DontUseUEFIVariable
        A switch parameter that configures the featue without using a UEFI variable, which is the default when the `Enable` parameter is used.

    .EXAMPLE
        Set-LocalSecurityAuthorityServerServiceAsProtectedProcess -Enable

    .EXAMPLE
        Set-LocalSecurityAuthorityServerServiceAsProtectedProcess -Enable -DontUseUEFIVariable
        
    .EXAMPLE
        Set-LocalSecurityAuthorityServerServiceAsProtectedProcess -Disable

    .LINK
        https://learn.microsoft.com/en-us/windows-server/security/credentials-protection-and-management/configuring-additional-lsa-protection
        
    .NOTES
        Running the LSASS process as a protected process requires Windows 8.1 and later.

        Author: Raymond Jette
        Created: 02/12/2025
        https://github.com/rayjette
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Parameter for enabling the protected process feature
        [Parameter(ParameterSetName = 'Enable', Mandatory)]
        [switch]$Enable,

        # Parameter for disabling the protected process feature
        [Parameter(ParameterSetName = 'Disable', Mandatory)]
        [switch]$Disable,

        # Parameter for configuring without UEFI variable (only applies when Enable is set)
        [Parameter(ParameterSetName = 'Enable')]
        [switch]$DontUseUEFIVariable
    )

    # Registry key and property to modify
    $regKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
    $regProperty = 'RunAsPPL'

    try {
        # Attempt to retrieve the current value of the registry property
        $currentValue = Get-ItemPropertyValue -Path $regKey -Name $regProperty -ErrorAction Stop
    } catch {
        # If the property doesn't exist or an error occurs, set $currentValue to null
        $currentValue = $null
    }

    # Determine the desired registry value based on input parameters
    if ($PSCmdlet.ParameterSetName -eq 'Enable') {
        # Set the desired value for enabling the protected process
        $desiredValue = if ($DontUseUEFIVariable) { 00000002 } else { 00000001 }

    } elseif ($PSCmdletParameterSetName -eq 'Disable') {
        # Set the desired value for disabling the protected process
        $desiredValue = 00000000
    }

    # If the desired value differs from the current registry value, update it
    if ($currentValue -ne $desiredValue) {
        if ($PSCmdlet.ShouldProcess("Updating registry for LSASS protection", "Setting RunAsPPL to $desiredValue")) {
            # Update the registry to reflect the desired setting
            Set-ItemProperty -Path $regKey -Name $regProperty -Value $desiredValue

            # Indicate if a reboot is needed for the changes to take effect
            Write-Warning "The registry has been updated.  A reboot is required to complete the process."
        }
    } else {
        Write-Warning "The Local Security Authority Server service is already configured as desired."
    }
}