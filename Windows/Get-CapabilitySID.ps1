Function Get-CapabilitySID
{
    <#
        .SYNOPSIS
            Returns all capability SID's on a system.
    #>
    (Get-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\SecurityManager\CapabilityClasses\).AllCachedCapabilities
}