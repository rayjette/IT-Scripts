#Requires -Modules ActiveDirectory

Function Get-ADFsmoRoleHolder
{
    <#
    .SYNOPSIS
        Find what DC(s) the FSMO roles are running on.

    .DESCRIPTION
        This function retrieves and displays the Domain Controllers (DCs) that hold the Flexible Single Master Operations (FSMO) roles in an Active Directory environment.

    .EXAMPLE
        Get-ADFsmoRoleHolder
        Find what DC(s) the FSMO roles are running on.

    .INPUTS
        None.  Get-ADFsmoRoleHolder does not accept input from the pipeline.

    .OUTPUTS
        System.Management.Automation.PSCustomObject.

    .NOTES
        Author: Raymond Jette
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()] 
    param()

    try {
        # Get forest wide Active Directory FSMO roles
        Write-Verbose -Message 'Getting forest roles...'
        $ForestRoles = Get-ADForest -ErrorAction 'Stop'

        # Get domain wide Active Directory FSMO roles
        Write-Verbose -Message 'Getting domain roles...'
        $DomainRoles = Get-ADDomain -ErrorAction 'Stop'

        # Create and return a PSCustomObject containing all of the FSMO role holders
        [PSCustomObject]@{
            SchemaMaster         = $ForestRoles.SchemaMaster
            DomainNamingMaster   = $ForestRoles.DomainNamingMaster
            InfrastructureMaster = $DomainRoles.InfrastructureMaster
            RIDMaster            = $DomainRoles.RIDMaster
            PDCEmulator          = $DomainRoles.PDCEmulator
        }
    } catch {
        Write-Error -Message "An error occurred while retrieving FSMO role holders: $_"
    }
}