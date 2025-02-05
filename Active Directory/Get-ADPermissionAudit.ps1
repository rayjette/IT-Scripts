Function Get-ADPermissionAudit {
    <#
    .SYNOPSIS
        Retrieves and audits Active Directory permissions.

    .DESCRIPTION
        This function collects the security descriptors and Access Control Lists (ACLs) for most Active Directory objects in the domain.
        It outputs detailed information about the permissions, including:
        - The identity reference (user/group)
        - The type of access (allowed/denied)
        - The permission action (e.g., Traverse, Read)
        - Whether the permission is inherited or not

    .PARAMETER Identity
        An optional parameter to specify the exact AD object (Distinguished Name or Object GUID) to audit. If not specified, all objects in the domain are audited.

    .EXAMPLE
        Get-ADPermissionAudit
        Retrieves and audits the permissions for all AD objects and outputs the results to the console.

    .EXAMPLE
        Get-ADPermissionAudit -Identity "CN=Mike Jones,OU=Users,DC=example,DC=com"
        Retrieves the permissions for the specific object "Mike Jones".

    .OUTPUTS
        Custom objects representing the AD object and its permissions. Each object includes the following properties:
        - DistinguishedName: The DN (Distinguished Name) of the AD object.
        - Owner: The owner of the AD object.
        - IdentityReference: The user or group associated with the permission.
        - Permission: The specific permission granted (e.g., Traverse, Read).
        - AccessType: Whether the permission is allowed or denied.
        - IsInherited: Whether the permission is inherited.

    .NOTES
        Author: Raymond Jette
        Created: 01/31/2025
        https://github.com/rayjette
    #>

    [CmdletBinding()]
    param (
        # Optional parameter to specify the identity of the AD object to audit (Distinguished Name or Object GUID)
        [string]$Identity
    )

    # Dynamically get the domain name and build the Distinguished Name (DN) for domain and configuration partitions
    $domainName = (Get-ADDomain).DNSRoot
    $domainParts = $domainName -split '\.'
    $domainSearchBase = ($domainParts | ForEach-Object { "DC=$($_)" }) -join ','
    $configurationSearchBase = "CN=Configuration,$domainSearchBase"

    # Define the object types to include in the audit
    $allowedObjectClasses = @("computer", "contact", "container", "domainDNS", "group", "organizationalUnit", "site", "user")

    # If an identity is specified, only retrieve the ACL for that specific object
    if ($Identity) {
        # Directly get the ACL for the specified object (no need to fetch all objects)
        $allObjectDN = @($Identity)
    } else {
        # If no Identity specified, retrieve all Active Directory objects

        # Create a dynamic filter for ObjectClass based on the allowed object classes
        $objectClassFilter = $allowedObjectClasses | ForEach-Object { "ObjectClass -eq '$_'"}

        # Join the filter conditional using ' -or '
        $objectClassFilterString = $objectClassFilter -join ' -or '

        # Get all Active Directory objects in the domain (DistinguishedName and objectClass)
        $allADObjects = Get-ADObject -Filter $objectClassFilterString -Properties DistinguishedName, objectClass

        # Get all Active Directory site objects in the domain
        $allSites = Get-ADObject -Filter {ObjectClass -eq "site"} -SearchBase $configurationSearchBase

        # Combine the Distinguished Names of AD objects and Sites for auditing
        $allObjectDN = $allADObjects.DistinguishedName + $allSites.DistinguishedName
    }

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