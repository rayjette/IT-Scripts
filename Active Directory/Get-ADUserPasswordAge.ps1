#Requires -Modules ActiveDirectory
Set-StrictMode -Version Latest

Function Get-ADUserPasswordAge 
{
    <#
    .SYNOPSIS
        Outputs an object containing password age information for users in Active Directory.

    .DESCRIPTION
        This function retrieves the password age (in days) for specified Active Directory users. 
        If no usernames are provided, the function will return the password age for all users in the Active Directory.

    .PARAMETER UserName
        The name(s) of one or more Active Directory users for whom the password age will be retrieved.
        This parameter can accept a list of usernames or be piped from another command.

    .PARAMETER Credential
        Allows you to provide additional credentials for connecting to an alternate domain. 
        This is used in conjunction with the Server parameter to specify an alternate domain controller.

    .PARAMETER Server
        Allows you to specify an alternate domain controller to connect to. 
        This is used together with the Credential parameter when accessing an alternate domain.

    .EXAMPLE
        Get-ADUserPasswordAge
        Returns the password age of all accounts in Active Directory.

        UserName      PasswordAge(Days)
        --------      -----------------
        John Smith    67
        ...

    .EXAMPLE
        Get-ADUserPasswordAge -UserName jsmith
        Returns the password age for the user 'jsmith'.

        UserName     PasswordAge(Days)
        --------     -----------------
        jsmith       45

    .EXAMPLE
        Get-ADUserPasswordAge -Server dc01.company.com -Credential (Get-Credential) -UserName jsmith
        Returns the password age for the user 'jsmith' from an alternate domain controller, 
        using the provided credentials.

        UserName     PasswordAge(Days)
        --------     -----------------
        jsmith       45

    .INPUTS
        System.String[]. The UserName parameter accepts one or more usernames, either through pipeline input or direct specification.

    .OUTPUTS
        System.Management.Automation.PSCustomObject
        Returns a PSCustomObject with the username and the password age in days for each user.

    .NOTES
        Author: Raymond Jette
        https://github.com/rayjette
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding(DefaultParameterSetName='All')]
    param (
        # The name of the AD user(s) whose password age will be retrieved.
        # Accepts multiple usernames and allows pipeline input.
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Alias('SamAccountName')]
        [String[]]$UserName,

        # Credential for alternate domain access. Mandatory if using an alternate domain controller.
        [Parameter(ParameterSetName='AlternateDomain', Mandatory)]
        [Alias('RunAs')]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        # Domain controller to connect to (if using an alternate domain).
        [Parameter(ParameterSetName = 'AlternateDomain', Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]$Server
    )

    BEGIN {
        $now = Get-Date

        # Create a hash table to hold parameters for the Get-ADUser cmdlet.
        $GetADUserParams = @{Properties = 'PasswordLastSet'}

        # Add the Server and Credential to the parameters only if they are provided 
        if ($PSCmdlet.ParameterSetName -eq 'AlternateDomain') {
            $GetADUserParams['Credential'] = $Credential
            $GetADUserParams['Server'] = $Server
        }

        # If no UserName is provided, fetch all users.
        if (-not $UserName) {
            $UserName = Get-ADUser -Filter * @GetADUserParams
        }
    }

    PROCESS {
        # Loop through each user to calculate and display password age.    
        foreach ($user in $UserName) {
            try {
                # Retrieve user details including password last set timestamp.
                $userDetails = Get-ADUser -Identity $user @GetADUserParams

                # Calculate the password age in days if PasswordLastSet is available.
                $PasswordAge = if ($userDetails.PasswordLastSet) {
                    ($now - $userDetails.PasswordLastSet).Days
                } else {
                    $null
                }
                
                # Return a custom object containing the username and password age in days.
                [PSCustomObject]@{
                    UserName = $userDetails.SamAccountName 
                    'PasswordAge(Days)' = $PasswordAge
                }
            } catch {
                # Catch and report any errors.
                write-error "Error processing user '$user': $($_.Exception.Message)"
            }
        }
    }
} # Get-ADUserPasswordAge