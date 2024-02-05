Function Get-UacConfig
{
    <#
    .SYNOPSIS
        Returns the User Access Control configuration.

    .EXAMPLE
        Get-UacConfig
        ComputerName                : MyPC-01
        FilterAdministratorToken    : Disabled (Default)
        EnableUIADesktopToggle      : Disabled (Default)
        ConsentPromptBehaviorAdmin  : Elevate without prompting
        ConsentPromptBehaviorUser   : Prompt for credentials (Default)
        EnableInstallerDetection    : Enabled (Default for home only)
        ValidateAdminCodeSignatures : Disabled (Default)
        EnableSecureUIAPaths        : Enabled (Default)
        EnableLUA                   : Enabled (Default)
        PromptOnSecureDesktop       : Enabled (Default)
        EnableVirtualization        : Enabled (Default)

    .NOTES
        Raymond Jette
        https://github.com/rayjette
    #>

    Function Get-RegValue($path, $value) {
        (Get-ItemProperty -Path $path).${value}
    }


    Function Format-Value($Value, $ValueMap, $Default) {
        <#
        .SYNOPSIS
            Returns the formatted value for a given UAC setting.
        #>
        if ($null-eq $value) {
            $valueMap[$Default]
        } elseif(-not $valueMap.ContainsKey($value)) {
            'Unknown'
        } else {
            $valueMap[$value]
        }
    }

    Function Get-ValueOfFilterAdministratorToken {
        <#
        .SYNOPSIS
            Admin Approval Mode for built-In Administrator account
        #>
        $value = Get-RegValue -Path $regPath -Value 'FilterAdministratorToken'
        $valueToName = @{
            0 = 'Disabled (Default)'
            1 = 'Enabled'
        }
        Format-Value -Value $value -ValueMap $valueToName -Default 0
    }
    

    Function Get-ValueOfEnableUiaDesktopToggle {
        <#
        .SYNOPSIS
            Allow UIAccess applications to prompt for elevation withoug
            using the secure desktop
        #>
        $value = Get-RegValue -Path $regPath -Value 'EnableUIADesktopToggle'
        $valueToName = @{
            0 = 'Disabled (Default)'
            1 = 'Enabled'
        }
        Format-Value -Value $value -ValueMap $valueToName -Default 0
    }


    Function Get-ValueOfConsentPromptBehaviorAdmin {
        <#
        .SYNOPSIS
            Behavior of the elevation prompt for administrators in
            Admin Approval Mode
        #>
        $value = Get-RegValue -Path $regPath -Value 'ConsentPromptBehaviorAdmin'
        $valueToName = @{
            0 = 'Elevate without prompting'
            1 = 'Prompt for credentials on the secure desktop'
            2 = 'Prompt for consent on the consent on the secure desktop'
            3 = 'Prompt for credentials'
            4 = 'Prompt for consent'
            5 = 'Prompt for consent for non-Windows binaries (Default)'
        }
        Format-Value -Value $value -ValueMap $valueToName -Default 5
    }


    Function Get-ValueOfConsentPromptBehaviorUser {
        <#
        .SYNOPSIS
            Behavior of the elevation prompt for standard users
        #>
        $value = Get-RegValue -Path $regPath -Value 'ConsentPromptBehaviorUser'
        $valueToName = @{
            0 = 'Automatically deny elevation requests'
            1 = 'Prompt for credentials on the secure desktop'
            3 = 'Prompt for credentials (Default)'
        }
        Format-Value -Value $value -ValueMap $valueToName -Default 3
    }


    Function Get-ValueOfEnableInstallerDetection {
        <#
        .SYNOPSIS
            Detect application installations and prompt for elevation
        #>
        $value = Get-RegValue -Path $regPath -Value EnableInstallerDetection
        $valueToName = @{
            0 = 'Disabled (Default)'
            1 = 'Enabled (Default for home only)'
        }
        # Because home has a different value I choose to return unknown
        # if the value is not in registry
        Format-Value -Value $value -ValueMap $valueToName -Default 'Unknown'
    }


    Function Get-ValueOfValidateAdminCodeSignatures {
        <#
        .SYNOPSIS
            Only elevate executables that are signed and validated
        #>
        $value = Get-RegValue -Path $regPath -Value ValidateAdminCodeSignatures
        $valueToName = @{
            0 = 'Disabled (Default)'
            1 = 'Enabled'
        }
        Format-Value -Value $value -ValueMap $valueToName -Default 0
    }


    Function Get-ValueOfEnableSecureUIAPaths {
        <#
        .SYNOPSIS
            Only elevate UIAccess applications that are installed
            in secure locations
        #>
        $value = Get-RegValue -Path $regPath -Value EnableSecureUIAPaths
        $valueToName = @{
            0 = 'Disabled'
            1 = 'Enabled (Default)'
        }
        Format-Value $value -ValueMap $valueToName -Default 1
    }


    Function Get-ValueOfEnableLUA {
        <#
        .SYNOPSIS
            Run all administrators in Admin Approval Mode
        #>
        $value = Get-RegValue -Path $regPath -Value 'EnableLUA'
        $valueToName = @{
            0 = 'Disabled'
            1 = 'Enabled (Default)'
        }
        Format-Value $value -ValueMap $valueToName -Default 1
    }


    Function Get-ValueOfPromptOnSecureDesktop {
        <#
        .SYNOPSIS
            Switch to the secure desktop when prompting for elevation
        #>
        $value = Get-RegValue -Path $regPath -Value 'PromptOnSecureDesktop'
        $valueToName = @{
            0 = 'Disabled'
            1 = 'Enabled (Default)'
        }
        Format-Value $value -ValueMap $valueToName -Default 1
    }


    Function Get-ValueOfEnableVirtualization {
        <#
        .SYNOPSIS
            Virtualize file and registry write fialures to
            per-user locations
        #>
        $value = Get-RegValue -Path $regPath -Value 'EnableVirtualization'
        $valueToName = @{
            0 = 'Disabled'
            1 = 'Enabled (Default)'
        }
        Format-Value $value -ValueMap $valueToName -Default 1
    }


    $regPath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    
    [PSCustomObject] @{
        ComputerName = $env:COMPUTERNAME
        FilterAdministratorToken    = Get-ValueOfFilterAdministratorToken
        EnableUIADesktopToggle      = Get-ValueOfEnableUiaDesktopToggle
        ConsentPromptBehaviorAdmin  = Get-ValueOfConsentPromptBehaviorAdmin
        ConsentPromptBehaviorUser   = Get-ValueOfConsentPromptBehaviorUser
        EnableInstallerDetection    = Get-ValueOfEnableInstallerDetection
        ValidateAdminCodeSignatures = Get-ValueOfValidateAdminCodeSignatures
        EnableSecureUIAPaths        = Get-ValueOfEnableSecureUIAPaths
        EnableLUA                   = Get-ValueOfEnableLUA
        PromptOnSecureDesktop       = Get-ValueOfPromptOnSecureDesktop
        EnableVirtualization        = Get-ValueOfEnableVirtualization
    }
}