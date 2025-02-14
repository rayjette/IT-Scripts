Function Get-FilesChangedAfter
{
    <#
    .SYNOPSIS
        Retrieves files that have changed since a specified date.

    .DESCRIPTION
        This function returns a list of files that have been modified since a given date.
        If no date is provided, it defaults to returning files modified in the last 24 hours.
        Additionally, the function allows for recursion into subdirectories within the provided path.

    .PARAMETER Path
        The path to the directory where the search will being.

    .PARAMETER Date
        The cutoff date for considering file modifications.  If not provided, defaults to the last 24 hours.

    .PARAMETER Recurse
        A flag indicating whether to search in subdirectories.
        If specified, the function will recursively search for files in the directory and its subdirectories.
    
    .EXAMPLE
        Get-FilesChangedAfter -Path "C:\" -Recurse
        Retrieves files that have been modified within the last 24 hours on the C: drive, including subdirectories.

    .EXAMPLE
        Get-FilesChangedAfter -Path "C:\" -Date (Get-Date).AddDays(-7) -Recurse
        Retrieves files modified in the last 7 days on the C: drive, including subdirectories.

    .EXAMPLE
        Get-FilesChangedAfter -Path "D:\Documents" -Date (Get-Date).AddMonths(-1)
        Retrieves files modified within the last month in the D:\Documents directory, without recursion.

    .INPUTS
        This function does not accept pipeline input.

    .OUTPUTS
        A list of `FileInfo` objects representing files that match the modification date criteria.

    .NOTES
        Creator: Raymond Jette
        Last Modified: 02/14/2025
        https://github.com/rayjette
    
    #>
    [OutputType([System.IO.FileInfo])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [datetime] $Date = (Get-Date).AddDays(-1),

        [switch] $Recurse
    )

    # Ensure the path ends with a backslash
    if ($Path[-1] -ne '\') {
        $Path = $Path + '\'
    }

    # Verify the path exists
    if (-not (Test-Path -Path $Path -PathType Container )) {
        throw "The specified path '$Path' does not exist or is not a directory."
    }

    # Parameters for Get-ChildItem
    $params = @{
        LiteralPath = $Path
        File        = $true
        Force       = $true
        Recurse     = $Recurse
    }

    try {
        # Returns files which have changed since LastWriteTime
        Get-ChildItem @params | Where-Object { $_.LastWriteTime -ge $Date }
    } catch {
        Write-Error "An error occurred while retrieving files from the specified path: $_"
    }
} # Get-FilesChangedAfter