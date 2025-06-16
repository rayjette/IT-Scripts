#Requires -PSEdition Desktop
#Requires -Modules GroupPolicy

Function Get-ADUnlinkedGPO
{
    <#
    .SYNOPSIS
        Used to find GPO's which are not linked to an OU.

    .DESCRIPTION
        Used to find GPO's which are not linked to an OU.

    .EXAMPLE
        Get-ADUnlinkedGPO 
        Find all group policy objects not linked to an OU.

    .INPUTS
        None.  Get-ADUnlinkedGPO does not accept objects from the pipeline.

    .OUTPUTS
        Microsoft.GroupPolicy.Gpo
    #>
    [CmdletBinding()]
    param ()

    # Get all group policy objects from Active Directory
    $groupPolicyObjects = (Get-GPO -ALL)

    # Parameters for Get-GPOReport cmdlet.
    $GetGpoReportSplatting = @{
        ReportType = 'xml'
        Name = $null
    }

    # Initialize a counter to 0 to be used for the progress bar
    $counter = 0

    foreach ($gpo in $groupPolicyObjects) {
        # Output a progress bar
        $WriteProgressSplatting = @{
            Activity = 'Searching for unlinked group policy objects.'
            Status   = "{0} of {1}" -f $counter, $groupPolicyObjects.count
            PercentComplete = ($counter / $groupPolicyObjects.count) * 100
        }
        $counter++
        Write-Progress @WriteProgressSplatting

        # Add the display name of the current gpo to the parameters for Get-GPOReport
        $GetGpoReportSplatting.name = $gpo.displayname

        # Get an xml report of the GPO and output it if it does not contain a link.
        [xml]$report = Get-GPOReport @GetGpoReportSplatting
        if ($report.gpo.psobject.properties.name -notcontains 'LinksTo') {
            $gpo
        }
    }
} # Get-ADUnlinkedGPO