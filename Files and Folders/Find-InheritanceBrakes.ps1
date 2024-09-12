Function Find-InheritanceBrakes {
    <#
    .SYNOPSIS
        Permissions are inherited from parent to child objects in the filesystem.
        Find-InheritanceBrakes reports on locations were inheritance is blocked.

    .PARAMETER Path
        We will recurisvely look for inheritance brakes from this location.

    .EXAMPLE
        Find-InheritanceBrakes -Path C:\
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Path
    )

    if ($path.endsWith(':')) {
        $path = $path += '\'
    }

    $gciParams = @{
        Path      = $Path
        Directory = $true
        Recurse   = $true
        Force     = $true
    }

    Get-ChildItem @gciParams | ForEach-Object {
        $ACL = $_ | Get-Acl
        if ($ACL.AreAccessRulesProtected) {
            $_.FullName
        }
    }
}