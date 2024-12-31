#Requires -PSEdition Desktop
#Requires -Modules GroupPolicy

Function Get-ADEmptyGPO
{
    <#
    .SYNOPSIS
        Retrieves unused Group Policy Objects (GPOs) in Active Directory.

    .DESCRIPTION
        This function identifies and returns Group Policy Objects (GPOs) that have never had their settings modified since creation.
        It checks the dsversion value of the GPO to determine if any settings have been changed.
        If settings were modified and then revered, the GPO will not be considered empty and will no be returned.

    .PARAMETER OnlyLinked
        If specified, only GPOs that are linked to an Active Directory container will be returned.
        Unlinked GPOs will be excluded from the output.

    .EXAMPLE
        Get-ADEmptyGPO

        Retrieves all GPOs that have never been altered since their creation.
 
    .EXAMPLE
        Get-ADEmptyGPO -OnlyLinked

        Retrieves all GPOs that have never been altered since their creation and are linked to an Active Directory container.
   
    .INPUTS
        None.  Get-ADEmptyGPO does not except input via the pipeline.

    .OUTPUTS
        Microsoft.GroupPolicy.Gpo

    .NOTES
        Author: Raymond Jette
    #>
    [CmdletBinding()]
    param (
        [switch] $OnlyLinked
    )

    Function Get-UnmodifiedGPOs {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [Microsoft.GroupPolicy.GPO[]] $GPOs
        )

        $unmodifiedGPOs = @()
        foreach ($gpo in $GPOs) {
            if ($gpo.User.DSVersion -eq 0 -and $gpo.Computer.DSVersion -eq 0) {
                $unmodifiedGPOs += $gpo
            }
        }
        $unmodifiedGPOs
    }


    Function Test-IsGPOLinked {
        param (
            [Parameter(Mandatory = $true)]
            [Microsoft.GroupPolicy.GPO] $GPO
        )
        [xml] $report = Get-GPOReport -ReportType 'xml' -Name $gpo.DisplayName
        $report.GPO.PSObject.Properties.Name -contains 'LinksTo'
    }

    try {
        $GPOs = Get-GPO -All
        $unModifiedGPOs = Get-UnmodifiedGPOs -GPOs $GPOs

        if ($OnlyLinked) {
            $linkedGPOs = @()
            foreach ($gpo in $unmodifiedGPOs) {
                if (Test-IsGPOLinked -GPO $gpo) {
                    $linkedGPOs += $gpo
                }
            }
            $linkedGPOs
        } else {
            $unModifiedGPOs
        }
    } catch {
        Write-Error -Message "An error occurred: $_"
    }
}