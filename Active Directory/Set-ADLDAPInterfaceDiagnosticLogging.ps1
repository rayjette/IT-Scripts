#Requires -RunAsAdministrator

Function Set-ADLDAPInterfaceDiagnosticLogging {
    <#
    .SYNOPSIS
        Enables or disables LDAP interface diagnostic logging on a domain controller.

    .DESCRIPTION
        This function modifies the registry:
        HKLM\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics\16 LDAP Interface Events
        to enable or disable LDAP interface diagnostic logging on a domain controller.

    .PARAMETER Enable
        Enables LDAP interface diagnostic logging.

    .PARAMETER Disable
        Disables LDAP interface diagnostic logging.

    .EXAMPLE
        Set-ADLDAPInterfaceDiagnosticLogging -Enable
        Enables LDAP interface diagnostic logging.

    .EXAMPLE
        Set-ADLDAPInterfaceDiagnosticLogging -Disable
        Disables LDAP interface diagnostic logging.

    .NOTES
        Author: Raymond Jette
        Date: 01/20/2025
        https://github.com/rayjette
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    param (

        [Parameter(Mandatory, ParameterSetName='Enable')]
        [switch] $Enable,

        [Parameter(Mandatory, ParameterSetName='Disable')]
        [switch] $Disable
    )

    $regKeyPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\Diagnostics"
    $regValueName = "16 LDAP Interface Events"
    $newValue = $null
    $action = $null

    switch ($PSCmdlet.ParameterSetName) {
        "Enable" {
            $newValue = 2
            $action = 'enabling'
        }
        "Disable" {
            $newValue = 0
            $action = 'disabling'
        }
    }

    # Prompt for confirmation and proceed with action
    if ($PSCmdlet.ShouldProcess("LDAP Interface Events diagnostic logging", "$action diagnostic logging")) {
        # Check current value and make the appropriate change
        $currentValue = (Get-ItemProperty -Path $regKeyPath -Name $regValueName).$regValueName

        if ($PSCmdlet.ParameterSetName -eq 'Enable' -and $currentValue -ne 2) {
                Write-Verbose "Changing registry value '$regValueName' to 2 to enable LDAP diagnostic logging."
                Set-ItemProperty -Path $regKeyPath -Name $regValueName -Value $newValue
                Write-Verbose "LDAP Interface Events diagnostic logging has been enabled."

        } elseif ($PSCmdlet.ParameterSetName -eq 'Disable' -and $currentValue -ne 0) {
            Write-Verbose "Changing registry value '$regValueName' to 0 to disable LDAP diagnostic logging."
            Set-ItemProperty -Path $regKeyPath -Name $regValueName -Value $newValue
            Write-Verbose "LDAP Interface Events diagnostic logging has been disabled."

        } else {
            # If the desired value is already set, give a warning
            if ($currentValue -eq 2) {
                Write-Warning "LDAP Interface Events diagnostic logging is already enabled."

            } elseif ($currentValue -eq 0) {
                Write-Warning "LDAP Interface Events diagnostic logging is already disabled."
            }
        }  
    }
}