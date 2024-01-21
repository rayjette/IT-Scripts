Function Get-FilesOfInterest
{
    <#

    .SYNOPSIS

    Identifies possible fiiles of interest when looking to
    free up disk space.

    .DESCRIPTION 

    Helps identify files of interest when looking to free
    up disk space.

    Get-FilesOfInterest only considers file extensions
    and strings contained in the file name.

    Disk usage is not considered in identifying files of
    interest.

    .PARAMETER Path

    Path and all of it's subdirectories will be considered.

    .PARAMETER Extensions

    A collection of extensions to search for.

    .PARAMETER Pattern

    File names matching this pattern will be returned.

    .EXAMPLE

    Get-FilesOfInterest -Path D:\Share\Engineering

    .EXAMPLE

    Get-FilesOfInterest -Path D:\Share -Extensions @('.exe', '.zip')
    Search D:\Share for all zip and exe files.

    .EXAMPLE

    Get-FilesOfInterest -Path D:\Share -Pattern 'backup|\bold\b'
    Returns files with "backup" or "old" in the file name.

    .EXAMPLE

    Get-FilesOfInterest -Path D:\Share -Pattern 'backup' -Extensions '.exe, .zip'
    Find zip or exe files or files having backup in the file name.

    .NOTES

    Raymond Jette

    .LINK

    https://github.com/rayjette

    #>
    param (
        [Parameter(Mandatory = $true)]
        [string] $Path,

        [Parameter(Mandatory = $false)]
        [string[]] $Extensions,

        [Parameter(Mandatory = $false)]
        [string] $Pattern
    )

    $param = @{
        Recurse = $true
        File   = $true
        Path   = $Path
    }
    Get-ChildItem @param | ForEach-Object {

        # using custom extensions and pattern
        if ($PSBoundParameters.ContainsKey('Extensions') -and $PSBoundParameters.ContainsKey('Pattern'))
        {
            if (($_.Extension -in $extensions) -or ($_.Name -match $pattern))
            {
                $result = $_
            }
        }

        # using custom extensions and not file name pattern
        elseif ($PSBoundParameters.ContainsKey('Extensions'))
        {
            if ($_.Extension -in $extensions) { $result = $_ }
        }

        # using custom pattern and no extensions
        elseif ($PSBoundParameters.ContainsKey('Pattern'))
        {
            if ($_.Name -match $pattern) { $result = $_ }
        }

        # using default pattern and extensions
        else
        {
            if (-not ($PSBoundParameters.ContainsKey('Extensions')))
            {
                $Extensions = @('.iso', '.bak', '.zip', '.mp3', '.temp',
                '.tmp', '.dmp', '.rar', '.avi', '.flac',
                '.mp4', '.mov', '.tar', '.old')
            }
        
            if (-not ($PSBoundParameters.ContainsKey('Pattern')))
            {
                $pattern = 'backup|\bold\b|\btest\b'
            }
            if (($_.Extension -in $extensions) -or ($_.Name -match $pattern))
            {
                $result = $_
            }
        }
        $result | Select-Object -Property FullName, length, *Access*
    }
} # Get-FilesOfInterest