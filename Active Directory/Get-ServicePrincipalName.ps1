#Requires -Modules ActiveDirectory
#Requires -RunAsAdministrator

Function Get-ServicePrincipalName {
    <#
    .SYNOPSIS
        Retrieves service principal names (SPNs) for users and computers in Active Directory.

    .DESCRIPTION
        The Get-ServicePrincipalName function retrieves service principal names (SPNs) for users and computers in Active Directory.
        It supports filtering by user or computer type and optionally by object name.  The function can also retrieve all SPNs if no specific
        type is provided.

    .PARAMETER Type
        Supports the type of object to retrieve SPNs for.  Valid values are 'User' and 'Computer'.

    .PARAMETER Name
        Specifies the name of the user or computer to retrieve SPNs for.  This parameter is optional and can be used to filter the results.

    .PARAMETER All
        Switch parameter to retrieve all SPNs for all objects in Active Directory.
        If the type parameter is not specified they all will be used regardless if its specified or not.

    .EXAMPLE
        Get-ServicePrincipalName
        Retrieves all SPNs for all objects in Active Directory.

    .EXAMPLE
        Get-ServicePrincipalName -Type User
        Retrieves all SPNs for all user objects in Active Directory.

    .EXAMPLE
        Get-ServicePrincipalName -Type Computer
        Retrieves all SPNs for all computer objects in Active Directory.

    .EXAMPLE
        Get-ServicePrincipalName -Type User -Name "username"
        Retrieves SPNs for the specified user in Active Directory.

    .INPUTS
        None. You cannot pipe objects to this function.

    .OUTPUTS
        PSCustomObject. The function returns a custom object with the following properties:
        - Name: The name of the AD object.
        - SPN: The service principal name.
        - DN: The distinguished name of the AD object.
        - ObjectClass: The class of the AD object (e.g., user, computer).

    .NOTES
        Author: Raymond Jette
        Date: 01/15/2025
        https://github.com/rayjette
    #>

    [CmdletBinding()]
    param (
        # Switch parameter to get all service principal names
        [Parameter(ParameterSetName='All')]
        [Switch]$All, 

        # Parameter to specify the type (User or Computer)
        [Parameter(Mandatory, ParameterSetName='TypeName')]
        [ValidateSet('User', 'Computer')]
        [string]$Type,

        # This parameter should only work with type but should not be required
        [Parameter(ParameterSetName='TypeName')]
        [string]$Name
    )

    # Define a hashtable to store common parameters for the Get-ADObject, Get-ADUser,
    # and Get-ADComputer cmdlets.
    $commonParams = @{
        Properties = 'servicePrincipalName'
    }

    # Process based on which ParameterSet is being used
    switch ($PSCmdlet.ParameterSetName) {
        "All" {
            # If 'All' parameter is selected, retrieve all objects that have a service principal name (SPN)
            $commonParams.LDAPFilter = "(servicePrincipalName=*)"
            $adObjects = Get-ADObject @commonParams
            break
        }
        "TypeName" {
            # If 'TypeName' parameter set is selected, filter by user or computer type
            if ($Type -eq "User") {
                $commonParams.LDAPFilter = if ($Name) {
                    "(&(servicePrincipalName=*)(|(samAccountName=$Name)(userPrincipalName=*$Name*)))"
                } else {
                    "(servicePrincipalName=*)"
                }

                # Query Active Directory for user objects
                $adObjects = Get-ADUser @commonParams

            } elseif ($Type -eq "Computer") {
                $commonParams.LDAPFilter = if ($Name) {
                    "(&(servicePrincipalName=*)(|(samAccountName=$Name)(dNSHostName=*$Name*)))"
                } else {
                    "(servicePrincipalName=*)"
                }

                # Query Active Directory for computer objects
                $adObjects = Get-ADComputer @commonParams
            }
            break
        }
    }

    # Loop all objects and return a custom object for each SPN
    foreach ($adObject in $adObjects) {
        $spnSplit = $adObject.servicePrincipalName -split ','
        foreach ($spn in $spnSplit) {
            [PSCustomObject]@{
                Name = $adObject.Name
                SPN  = $spn
                DN   = $adObject.DistinguishedName
                ObjectClass = $adObject.ObjectClass
            }
        }
    }

}