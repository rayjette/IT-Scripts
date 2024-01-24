#Requires -RunAsAdministrator

Function Get-VSSStorageInfo
{
    <#
    .SYNOPSIS
        Gets shadowcopy storage information.

    .EXAMPLE
        Get-VSSStorageInfo
        Hostname         : myhost
        Volume           : C:
        StorageOn        : C:
        UsedStorage      : 0 bytes (0%)
        AllocatedStorage : 0 bytes (0%)
        MaxStorage       : 4.47 GB (5%)
    #>
    [CmdletBinding()]
    param()

    $shadowStorageInfo = vssadmin list shadowstorage

    foreach ($item in $shadowStorageInfo) {
        # We have a new Shadow Copy Storage Associaion.
        if ($item -match 'Shadow Copy Storage association') {
            $object = [ordered]@{
                Hostname         = $env:COMPUTERNAME
                Volume           = $null
                StorageOn        = $null
                UsedStorage      = $null
                AllocatedStorage = $null
                MaxStorage       = $null
            }
        }
        elseif ($item -match 'For volume: \((.:)\)') {
            $object.Volume = $matches[1]
        }
        elseif ($item -match 'Shadow Copy Storage volume: \((.:)\)') {
            $object.StorageOn = $matches[1]
        }
        elseif ($item -match 'Used Shadow Copy Storage space: (.*)') {
            $object.UsedStorage = $matches[1]
        }
        elseif ($item -match 'Allocated Shadow Copy Storage space: (.*)') {
            $object.AllocatedStorage = $matches[1]
        }
        elseif ($item -match 'Maximum Shadow Copy Storage space: (.*)') {
            $object.MaxStorage = $matches[1]
            [PSCustomObject] $object
        }
    }
}