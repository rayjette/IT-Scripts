Function Get-FilesChangedAfter
{
    <#
    .SYNOPSIS

    Returns files which have changed since a specified time.

    .DESCRIPTION

    Returns files which have changed since a specified time.
    If a time is not specified it will get files which have changed in the
    last day.

    .PARAMETER Path

    The path of the directory to look for changed files in.  If you specify
    the path of just the drive letter make sure a trailing '\' is added or it
    will not work.  Ex. C:\ not C:.

    .PARAMETER Date

    The date to consider when looking for changed files.

    .PARAMETER Recurse

    Looks at files in the path provided as well as in any subdirectories.

    .EXAMPLE

    Get-FilesChanged -Path C:\ -Recurse
    Get's the files that have changed in the last day on the C: drive.
    Subdirectories in path will also be looked at.

    .EXAMPLE

    Get-FilesChanged -Path C:\ -Date (Get-Date).AddDays(-7) -Recurse
    Get's the files that have changed in the last 7 days on the C: drive.

    .INPUTS

    None.  Get-FilesChangedAfter does not accept input from the pipeline.

    .OUTPUTS

    [System.IO.DirectoryInfo]

    .NOTES

    Raymond Jette
    
    .LINK

    https://github.com/rayjette
    
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [datetime] $Date = (Get-Date).AddDays(-1),

        [switch] $Recurse
    )
    $params = @{
        Path   = $Path
        File   = $true
        Recurse = $recurse
    }
    Get-ChildItem @params |
        Where-Object {$_.LastWriteTime -ge $Date}
} # Get-FilesChangedAfter