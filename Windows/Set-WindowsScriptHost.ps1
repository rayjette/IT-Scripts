Function Set-WindowsScriptHost {
    <#
    .SYNOPSIS
        Enable or disable Windows Script Host (WSH) on the local machine.

    .DESCRIPTION
        This function will enable or disable Windows Script Host (WSH) on the local machine by modifying the registry.

    .PARAMETER Enable
        Enables Windows Script Host (WSH) on the local machine.

    .PARAMETER Disable
        Disables Windows Script Host (WSH) on the local machine.

    .EXAMPLE
        Set-WindowsScriptHost -Enable

    .EXAMPLE
        Set-WindowsScriptHost -Disable
    
    .INPUTS
        None.  Set-WindowsScriptHost does not accept input from the pipeline.

    .OUTPUTS
        None.

    .NOTES
        Author: Raymond Jette
        Created: 2/11/2025
        https://github.com/rayjette
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ParameterSetName = 'EnableWSH')]
        [switch]$Enable,

        [Parameter(Mandatory, ParameterSetName = 'DisableWSH')]
        [switch]$Disable,

        [string]$RegistryPath = 'HKLM:\Software\Microsoft\Windows Script Host\Settings',
        [string]$PropertyName = 'Enabled'
    )

    $currentValue = Get-ItemProperty -Path $RegistryPath -Name $PropertyName -ErrorAction SilentlyContinue

    switch ($PSCmdlet.ParameterSetName) {
        'EnableWSH' {
            if ($currentValue.$PropertyName -ne 1) {
                Write-Verbose "Enabling Windows Script Host (WSH)..."
                Set-ItemProperty -Path $RegistryPath -Name $PropertyName -Value 1
                Write-Verbose "Windows Script Host (WSH) has been enabled."
            } else {
                Write-Warning "Windows Script Host (WSH) is already enabled."
            }
        }
        'DisableWSH' {
            if ($currentValue.$PropertyName -ne 0) {
                Write-Verbose "Disabling Windows Script Host (WSH)..."
                Set-ItemProperty -Path $RegistryPath -Name $PropertyName -Value 0
                Write-Verbose "Windows Script Host (WSH) has been disabled."
            } else {
                Write-Warning "Windows Script Host (WSH) is already disabled."
            }
        }
    }
}