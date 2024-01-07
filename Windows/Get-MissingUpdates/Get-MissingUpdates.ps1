Function Get-MissingUpdates
{
    <#
    .SYNOPSIS
        Returns infroamtion about available updates that have not yet been installed.

    .DESCRIPTION
        Returns infroamtion about available updates that have not yet been installed.

    .PARAMETER ShowHidden
        Include updates marked as hidden in our output of needed updates.

    .INPUTS
        None.  Get-MissingUpdates does not have any parameters that accept input from the pipeline.

    .OUTPUTS
        System.Management.Automation.PSCustomObject.

    .NOTES  
        Raymond Jette
        Version 1.0
        https://github.com/rayjette

    #>
    [CmdletBinding()]
    param (
        [switch]$ShowHidden = $false
    )
    Write-Verbose 'Creating an instance of Microsoft.Update.Session COM object'
    $session = New-Object -ComObject Microsoft.Update.Session

    Write-Verbose 'Creating update searcher'
    $updateSearcher = $session.CreateUpdateSearcher()

    Write-Verbose 'Searching for missing updates'
    if ($PSBoundParameters.ContainsKey('ShowHidden')) {
        Write-Verbose 'Hidden updates will be included.'
        $searchResults = $updateSearcher.search('IsHidden = 1 or IsHidden = 0 and IsInstalled = 0')
    } else {
        Write-Verbose 'Hidden updates will not be included.'
        Write-Warning 'Hidden updates are not include.  Re-run the script with the ShowHidden parameter to change this behavior.'
        $searchResults = $updateSearcher.search('IsInstalled = 0 and IsHidden = 0')
    }

    $updates = $searchResults.updates

    Write-Verbose 'Displaying missing updates'
    $updates | ForEach-Object {
        [PSCustomObject]@{
            Title = $_.title
            Description = $_.Description
            IsDownloaded = $_.IsDownloaded
            IsHidden = $_.IsHidden
            MaxDownloadSize = $_.MaxDownloadSize
        }
    }
} # Get-MissingUpdates