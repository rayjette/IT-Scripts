Function Find-ExplicitGrants {
    <#
    .SYNOPSIS
        Finds directories were the specified group or user is granted access.

    .DESCRIPTION
        Finds directories where the specified group or user has been explicitly
        granted access.  Inherited permissions are not considered here.  We are
        only concerned with the permissions assigned at that level.

    .PARAMETER Path
        This is the path you are checking for explicit grants

    .PARAMETER Recurse
        Recursively check path for explicit grants

    .INPUTS
        None.  Find-ExplicitGrants does not accept input from the pipeline.

    .OUTPUTS
        System.Management.Automation

    .EXAMPLE
        Find-ExplicitGrants -Path C:\ -Recurse | Out-Gridview
        Find explicit grants for any directory or subdirectory
        located on the C:\ drive.

    .NOTES
        Raymond Jette
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [switch]$Recurse
    )


    Function FindExplicitGrants {
        param (
            [Parameter(ValueFromPipeline)]
            $InputObject
        )

        Process {
            $acl = $InputObject | Get-Acl
            foreach ($ace in $acl) {
                foreach ($accessRule in $ace.Access) {
                    if ($accessRule.IsInherited -eq $false) {
                        if ($accessRule.IdentityReference.Value -match $n) {
                            [PSCustomObject]@{
                                Name        = $InputObject.FullName
                                ControlType = $accessRule.AccessControlType
                                Identity    = $accessRule.IdentityReference
                                FileSystemRights = $accessRule.FileSystemRights
                            }
                        }
                    }
                }
            }
        }
    }

    
    # if path ends with a ':' appends a \ to the end.
    # This prevents issus with Get-ChildItem.
    if ($path.endsWith(':')) {
        $path = $path += '\'
    }

    Get-Item -Force -Path $Path  | FindExplicitGrants
    Get-ChildItem -Force -Path $Path -Directory -Recurse | FindExplicitGrants
}