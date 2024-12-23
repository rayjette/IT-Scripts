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
        If specified, only GPOs that are linked to an Active Directory container (such as a site, domain, or organizational unit) will be returned.
        Unlinked GPOs will be excluded from the output.

    .EXAMPLE
        Get-ADEmptyGPO

        Retrieves all GPOs that have never been altered since their creation.

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