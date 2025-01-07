Function Unprotect-AdminSDHolderObjects {
    <#
    .SYNOPSIS
        Enables inheritance and clears the adminCount attribute on specified Active Directory objects.

    .DESCRIPTION
        The Unprotect-AdminSDHolderObjects function is used to undo the protection that is applied by the AdminSDHolder process.
        It enables inheritance and clears the adminCount attribute on specified Active Directory objects. 
        This function should be run after removing an object from a protected group.

    .PARAMETER Identity
        Specifies that Active Directory object(s) to be unprotected.  This parameter accepts distinguished names, GUIDS, SIDs, or SAM account names.

    .EXAMPLE
        Unprotect-AdminSDHolderObjects -Identity "CN=John Doe,OU=Users,DC=example,DC=com"
        This command enables inheritance and clears the adminCount attribute for the user John Doe.

    .EXAMPLE
        Get-ADUser -Filter * -SearchBase "OU=Users,DC=example,DC=com" | Unprotect-AdminSDHolderObjects
        This command enables inheritance and clears the adminCount attribute for all users in the specified OU.

    .EXAMPLE
        Find-AdminSDHolderLegacyObjects | Undo-AdminSDHolderProtection
        This command enables inheritance and clears the adminCount attribute for all objects that were previously protected by the AdminSDHolder but are no longer protected.

    .NOTES
        Author: Raymond Jette
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias("DistinguishedName", "GUID", "SID", "SAMAccountName")]
        [string[]]$Identity
    )

    process {
        foreach ($id in $Identity) {
            try {
                # Get the AD object
                $adObject = Get-ADObject -LDAPFilter "sAMAccountName=$id" -Properties adminCount, ntSecurityDescriptor
            } catch {
                Write-Error "Failed to unprotect: $id.  Error: $_"
            }

            if ($adObject) {
                # Enable inheritance
                $acl = $adObject.ntSecurityDescriptor
                if ($acl.AreAccessRulesProtected) {
                    if ($PSCmdlet.ShouldProcess("$id", "Enable inheritance")) {
                        $acl.SetAccessRuleProtection($false, $true)
                        Set-ADObject -Identity $adObject.DistinguishedName -Replace @{ntSecurityDescriptor = $acl}
                    }
                }

                # Clean the adminCount attribute
                if ($null -ne $adObject.adminCount) {
                    if ($PSCmdlet.ShouldProcess("$id", "Clear adminCount")) {
                        Set-ADObject -Identity $adObject.DistinguishedName -Clear adminCount
                    }
                }
            } else {
                Write-Warning "Object not found: $id"
            }
        }
    }
}