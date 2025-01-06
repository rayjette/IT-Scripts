#Requires -Modules ActiveDirectory

Function Get-ADGroupAllMembers {
    <#
    .SYNOPSIS
        Retrieves all members of an Active Directory group, including nested group members.

    .DESCRIPTION
        This function retrieves all members of an Active Directory group, including members of any nested groups.
        It recursively traverses nested groups to gather all unique members.

    .PARAMETER GroupName
        The name of the Active Directory group whose members are to be retrieved.

    .EXAMPLE
        Get-ADGroupAllMembers -GroupName "Domain Admins"
        This command retrieves all members of the "Domain Admins" group, including members of any nested groups.

    .NOTES
        Author: Raymond Jette
        Date: 1/6/2025
        Version: 1.0
        This script requires the Active Directory module.
    #>
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $GroupName
    )

    try {
        # Get all members of the group
        $groupMembers = Get-ADGroupMember -Identity $GroupName
        
        # Initialize an array to store final members
        $allMembers = @()

        foreach ($member in $groupMembers) {
            # Check if the member is a group
            if ($member.objectClass -eq "group") {
                # Recursively get members of the nested group
                $allMembers += Get-ADGroupAllMembers -GroupName $member.SamAccountName
            } else {
                # Add user to the list if it's not a group
                $allMembers += $member.SamAccountName
            }
        }
    } catch {
        Write-Error "An error occurred while retrieving members of the group."
    }

    # Remove duplicates by selecting unique values
    $allMembers | Select-Object -Unique
}