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

    .EXAMPLE

    Get-FilesOfInterest -Path D:\Share\Engineering

    .NOTES

    Raymond Jette

    .LINK

    https://github.com/rayjette

    #>
    param (
        [Parameter(Mandatory = $true)]
        [string] $Path
    )
    $extensions = @('.iso', '.bak', '.zip', '.mp3', '.temp',
                    '.tmp', '.dmp', '.rar', '.avi', '.flac',
                    '.mp4', '.mov', '.tar', 'sfx', 'old')

    $param = @{
        Recurse = $true
        File   = $true
        Path   = $Path
    }
    Get-ChildItem @param | ForEach-Object {
        if (($_.Extension -in $extensions) -or ($_.Name -match "backup|OneDrive|\bold\b"))
        {
            $_ | Select-Object -Property FullName, length, *Access*
        }
    }
} # Get-FilesOfInterest