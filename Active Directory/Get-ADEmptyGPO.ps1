#Requires -PSEdition Desktop
#Requires -Modules GroupPolicy

Function Get-ADEmptyGPO
{
    <#
    .SYNOPSIS
        Returns unused group policy objects.

    .DESCRIPTION
        Returns unused group policy objects.

        Returns group policy objects which have never had there settings modified after creation.
        If the settings were modified and then changed back the gpo will not be returned because
        we are looking at the dsversion value on the gpo.

    .PARAMETER OnlyLinked
        Only empty group policy objects that are linked somewhere will be output.  Unlinked GPO's
        will not be shown.

    .EXAMPLE
        Get-ADEmptyGPO

        Return group policy objects that have never been altered. 

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

    Function Test-IsGPOLinked($gpo) {
        <#
        .SYNOPSIS
            Returns true if the gpo has a link to an OU.  False otherwise.
        #>
        Write-Verbose -Message "Entering $($myinvocation.mycommand)."

        Write-Verbose -Message "Getting xml report for gpo $($gpo.displayname)."
        [xml] $report = Get-GPOReport -ReportType 'xml' -Name $gpo.displayname

        Write-Verbose -Message "Checking if gpo $($gpo.displayname) is linked to an OU."
        $report.gpo.psobject.properties.name -contains 'LinksTo'

        Write-Verbose -Message "Exiting $($myinvocation.mycommand)."
    }

    Write-Verbose -Message "Entering $($myinvocation.mycommand)."

    Write-Verbose -Message "Getting group policy objects."
    $GPOs = Get-GPO -All

    $filter = {$_.user.dsversion -eq 0 -and $_.computer.dsversion -eq 0}
    Write-Verbose -Message "Filter set to '$filter'."

    Write-Verbose -Message "Looking for empty GPOs."
    $unmodifiedGpo = $GPOs | Where-Object -FilterScript $filter
    
    if ($PSBoundParameters.ContainsKey('OnlyLinked')) {
        Write-Verbose -Message "Only GPO's linked to an OU will be considered for results."
        $results = @()
        foreach ($gpo in $unmodifiedGpo) {
            Write-Verbose -Message "Checking if gpo $($gpo.displayname) is linked to an OU."
            if (Test-IsGPOLinked($gpo)) {
                Write-Verbose -Message "GPO $($gpo) is linked to an ou and will be added to results."
                $results += $gpo
            }
        }
    } else {
        Write-Verbose -Message "All GPO's will be considered for results."

        Write-Verbose -Message "Adding any found empty GPO's to results."
        $results = @($unmodifiedGPO)
    }
    Write-Verbose -Message 'Returning results.'
    $results

    Write-Verbose -Message "Exiting $($myinvocation.mycommand)"
}