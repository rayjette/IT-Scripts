Function Get-OrphanedPermisions
{
    <#
        .SYNOPSIS
            Finds folder permissions for orphaned user.

        .DESCRIPTION
            Finds folder permissions for orphaned user.  These are the permissions that applear as a SID because
            the user object no longer exists.

        .PARAMETER Path
            The path to search folders for orphaned permissions.  If recurse is not used only this folder is
            searched.

        .PARAMETER Recurse
            Only search child folders when looking for orphaned user permissions.

        .PARAMETER OnlyExplicit
            Do not report on orphaned user permissions if the permission was inherited.  This option only returns
            orphaned permissions set explicitly.  This option can be used to find where the orphaned permissions
            should be removed.

        .EXAMPLE
            Get-OrphanedPermissions -Path E:\

        .EXAMPLE
            Get-OrphanedPermissions -Path E:\ -Recurse

        .EXAMPLE
            Get-OrphanedPermissions -Path E:\ -OnlyExplicit -Recurse

        .INPUTS
            Get-OrphanedPermissions does not accept input from the pipline.

        .OUTPUTS
            System.Management.Automation.PSCustomObject.

        .NOTES
            Raymond Jette

            WARNING: Please verify the results before removing any SIDS.
            This script appears to be returning the SID's for built in accounts
            such as Builtin\RDS Remote Access Servers.  These are not orphaned
            permissions.  I will be looking for ways to identify these and
            make sure they are removed from the output of this script.
    #>
    [OutputType([System.IO.DirectoryInfo])]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        [switch] $Recurse,

        [switch] $OnlyExplicit
    )


    Function GetOrphanedPermissions
    {
        param (
            [Parameter(ValueFromPipeline)]
            $InputObject
        )

        Begin {
            # if path ends with a ':' appends a \ to the end.
            # This prevents issus with Get-ChildItem.
            if ($path.endsWith(':')) {
                $path = $path += '\'
            }

        }
        
        Process {
            $acl = ($InputObject | Get-Acl).access

            foreach ($ace in $acl) {

                if ($OnlyExplicit -and $ace.IsInherited) {
                    continue
                }
                # capability SID's start with S-1-15-3-
                if (($ace.identityReference.gettype().name -eq 'SecurityIdentifier') -and
                        ($ace.IdentityReference -notmatch '^S\-1\-15\-3\-.*$')) {

                    [PSCustomObject]@{
                        Directory = $InputObject.FullName
                        SID = $ace.identityReference.Value
                    }
                }
            }
        }
    }

    if (Test-path -LiteralPath $Path -PathType Container) {
        
        Get-Item -Force -Path $Path  | GetOrphanedPermissions

        if ($Recurse) {
            foreach ($folder in (Get-ChildItem -Path $Path -Recurse -Directory -ErrorAction 'Continue')) {
                $folder | GetOrphanedPermissions
            }
        }
    } else {
        Write-Error -Message "Path does not exist or is not a directory."
    }

}