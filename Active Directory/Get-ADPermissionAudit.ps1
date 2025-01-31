Function Get-ADPermissionAudit {
    <#
    .SYNOPSIS
        Retrieves and audits Active Directory permissions for all objects in the domain.

    .DESCRIPTION
        This function collects the security descriptors and Access Control Lists (ACLs) for all Active Directory objects in the domain.
        It outputs detailed information about the permissions, including:
        - The identity reference (user/group)
        - The type of access (allowed/denied)
        - The permission action (e.g., Traverse, Read)
        - Whether the permission is inherited or not

    .OUTPUTS
        Custom objects representing the AD object and its permissions. Each object includes the following properties:
        - DistinguishedName: The DN (Distinguished Name) of the AD object.
        - Owner: The owner of the AD object.
        - IdentityReference: The user or group associated with the permission.
        - Permission: The specific permission granted (e.g., Traverse, Read).
        - AccessType: Whether the permission is allowed or denied.
        - IsInherited: Whether the permission is inherited.

    .EXAMPLE
        Get-ADPermissionAudit
        Retrieves and audits the permissions for all AD objects and outputs the results to the console.

    .NOTES
        Author: Raymond Jette
        Created: 01/31/2025
        https://github.com/rayjette
    #>

    [CmdletBinding()]
    param (

    )

    # Dynamically get the domain name and build the Distinguished Name (DN) for domain and configuration partitions
    $domainName = (Get-ADDomain).DNSRoot
    $domainParts = $domainName -split '\.'
    $domainSearchBase = ($domainParts | ForEach-Object { "DC=$($_)" }) -join ','
    $configurationSearchBase = "CN=Configuration,$domainSearchBase"

    # Get all Active Directory site objects in the domain
    $allSites = Get-ADObject -Filter {ObjectClass -eq "site"} -SearchBase $configurationSearchBase

    # Get all Active Directory objects in the domain
    $allADObjects = Get-ADObject -Filter * -Properties DistinguishedName, objectClass

    # Combine the Distinguished Names of AD objects and site objects
    $allObjectDN = @($allADObjects.DistinguishedName) + $allSites.DistinguishedName

    # Loop through each Distinguished Name and retrieve ACLs
    foreach($dn in $allObjectDN) {
        # Construct the AD path with the correct format
        $adPath = "AD:$dn"

        try {
            # Retrieve the ACL for the AD object
            $acl = Get-ACL -Path $adPath

        } catch {
            Write-Warning "Error retrieving ACL for $adPath`: $($_.Exception.Message)"
            continue
        }

        # Get the security descriptor form the ACL
        $aclSddl = $acl.GetSecurityDescriptorSddlForm("All")
        $securityDescriptors = $aclSddl | ConvertFrom-SddlString

        # Loop through each security descriptor's discretionary ACL
        foreach ($sd in $securityDescriptors) {
            $owner = $acl.Owner

            foreach ($ace in $sd.DiscretionaryAcl) {
                $aceParts = $ace -split ':'
                $identityReference = $aceParts[0]
                $permission = $aceParts[1]
                
                # Split the permission field to extract Access Type and Inherited status
                $accessType = if ($permission -match "AccessDenied") { "Denied" } elseif ($permission -match "AccessAllowed") { "Allowed" } else { "Unknown"}
                $isInherited = if ($permission -match "inherited") { $true } else { $false }

                # Extract the permission action (e.g., Traverse, Read, etc.) from the parenthesis
                $permissionAction = if ($permission -match '\((.*?)\)') { $matches[1] } else { "Unknown" }

                # Output relevant data as a custom object
                [PSCustomObject]@{
                    DistinguishedName = $dn
                    Owner             = $owner
                    IdentityReference = $identityReference
                    Permission        = $permissionAction
                    AccessType        = $accessType
                    IsInherited       = $isInherited
                }
            }
        }
    }
}