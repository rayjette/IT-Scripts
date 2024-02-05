#Requires -PSEdition Desktop
#Requires -Modules Microsoft.Online.SharePoint.PowerShell

<#
.SYNOPSIS
    Some functions for working with the "allow custom scipts" site setting in SharePoint  Online.

.NOTES
    Raymond Jette
    Version 1.0

.LINK
    https://github.com/rayjette
#>


Function Enable-SPOAllowCustomScripts
{
    <#
    .SYNOPSIS
        Enables the ability to run custom scripts on one or more SharePoint Online sites.

    .DESCRIPTION
        Enables the ability to run custom scripts on one or more SharePoint Online sites.

    .PARAMETER SPOSite
        One or more SPOSite objects.  These SPOSite objects are returned from the Get-SPOSite cmdlet.

    .PARAMETER Force
        Suppresses the conformation prompts.

    .EXAMPLE
        $site = Get-SPOSite -Identity https://my-domain.sharepoint.com/sites/my-site
        PS C:\>Enable-SPOAllowCustomScrips -SPOSite $site
        Enable running custom scripts on a single site.

    .EXAMPLE
        $site = Get-SPOSite -Limit all
        PS C:\>$site | Enable-SPOAllowCustomScripts
        Enable running custom scripts on all sites.

    .INPUTS
        The SPOSite parameter accepts [Microsoft.Online.SharePoint.PowerShell.SPOSite] from the pipeline.

    .OUTPUTS
        [Microsoft.Online.SharePoint.PowerShell.SPOSite]
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [Microsoft.Online.SharePoint.PowerShell.SPOSite[]] $SPOSite,

        [switch]$Force
    )
    PROCESS
    {
        foreach ($site in $SPOSite)
        {
            # Checking if running custom scripts is currently disallowed
            Write-Verbose -Message "$($site.url)"
            Write-Verbose -Message '  Checking if custom scripts are disallowed...'
            if ($site.DenyAddAndCustomizePages -eq 'Enabled')
            {
                # Enable running custom scripts for site
                Write-Verbose '  Custom scripts are currently disabled'
                if ($Force -or $PSCmdlet.ShouldContinue($site.url, 'Allowing the running of custom scripts.'))
                {
                    Write-Verbose '  Allowing custom scirpts...'
                    Set-SPOSite -DenyAddAndCustomizePages 0 -Identity $site.url
                }
            }
            elseif ($site.DenyAddAndCustomizePages -eq 'Disabled')
            {
                # Notify that user that custom scripts are already allowed to run on site
                Write-Warning "Custom scripts are already enabled for $($site.url)"
                Write-Verbose '  Custom scirpts are currently allowed'
                Write-Verbose '  Nothing to change'
            }
            else {
                Write-Error 'Unable to determine the status of site.'
            }
        }
    }
} # Enable-SPOAllowCustomScripts


Function Disable-SPOAllowCustomScripts
{
    <#
    .SYNOPSIS
        Disables the ability to run custom scripts on one or more SharePoint Online sites.

    .DESCRIPTION
        Disables the ability to run custom scripts on one or more SharePoint Online sites.

    .PARAMETER SPOSite
        One or more SPOSite objects.  These SPOSite objects are returned from the Get-SPOSite cmdlet.

    .PARAMETER Force
        Suppresses the conformation prompts.

    .EXAMPLE
        $site = Get-SPOSite -Identity https://my-domain.sharepoint.com/sites/my-site
        PS C:\>Disable-SPOAllowCustomScrips -SPOSite $site
        Disable running custom scripts on a single site.

    .EXAMPLE
        $site = Get-SPOSite -Limit all
        PS C:\>$site | Disable-SPOAllowCustomScripts
        Disable running custom scripts on all sites.

    .EXAMPLE
        Find-SPOSiteWithCustomScriptsAllowed | Disable-SPOAllowCustomScripts -Force
        Disallow the running of custom scripts on all sites allowing it.

    .INPUTS
        The SPOSite parameter accepts [Microsoft.Online.SharePoint.PowerShell.SPOSite] from the pipeline.

    .OUTPUTS
        [Microsoft.Online.SharePoint.PowerShell.SPOSite]
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory,
            ValueFromPipeline
        )]
        [Microsoft.Online.SharePoint.PowerShell.SPOSite[]] $SPOSite,

        [switch]$Force
    )
    PROCESS
    {
        foreach ($site in $SPOSite)
        {
            # Checking if running custom scripts is currently allowed
            Write-Verbose -Message "$($site.url)"
            Write-Verbose -Message '  Checking if custom scripts are allowed...'
            if ($site.DenyAddAndCustomizePages -eq 'Disabled')
            {
                # Disallowing running custom scripts for site
                Write-Verbose '  Custom scripts are currently allowed'
                if ($Force -or $PSCmdlet.ShouldContinue($site.url, 'Disallowing the running of custom scripts.'))
                {
                    Write-Verbose '  Disallowing custom scirpts...'
                    Set-SPOSite -DenyAddAndCustomizePages 1 -Identity $site.url
                }
            }
            elseif ($site.DenyAddAndCustomizePagees -eq 'Enabled')
            {
                # Notify that user that custom scripts are already disallowed on site
                Write-Warning "Custom scripts are already disallowed for $($site.url)"
                Write-Verbose '  Custom scirpts are currently disallowed'
                Write-Verbose '  Nothing to change'
            } else {
                Write-Error 'Unable to determine the status of site.'
            }
        }
    }
} # Disable-SPOAllowCustomScripts


Function Find-SPOSiteWithCustomScriptsAllowed
{
    <#
    .SYNOPSIS
        Find's SharePoint Online sites were custom scripts are allowed to run.

    .EXAMPLE
        Find-SPOSiteWithCustomScriptsAllowed
        Find all SPO sites that currently allow the running of custom scripts.
    #>
    Get-SPOSite -Limit all | Where-Object {$_.DenyAddAndCustomizePages -eq 'disabled'}
} # Find-SPOSiteWithCustomScriptsAlloweed