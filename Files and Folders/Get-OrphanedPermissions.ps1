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

        Process {
            $acl = ($InputObject | Get-Acl).access

            foreach ($ace in $acl) {

                if ($OnlyExplicit -and $ace.IsInherited) {
                    continue
                }
        
                if ($ace.identityReference.gettype().name -eq 'SecurityIdentifier') {
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
            foreach ($folder in (Get-ChildItem -Path $Path -Recurse -Directory)) {
                $folder | GetOrphanedPermissions
            }
        }
    } else {
        Write-Error -Message "Path does not exist or is not a directory."
    }

}