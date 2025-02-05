Function Remove-ExchAttributesFromUser
{
    <#
    .SYNOPSIS
        Removes Exchange-related attributes from an Active Directory user account.

    .DESCRIPTION
        This function is used to remove Exchange-related attributes from an Active Directory user account.
        Removing these attributes from the user will effectively delete the associated Exchange mailbox.

    .PARAMETER samAccountName
        The samAccountName of the user account from which Exchange-related attributes will be removed.
        This parameter is required.

    .EXAMPLE
        Remove-ExchAttributesFromUser -samAccountName account_1
        Removes the Exchange attributes from the Active Directory user with the samAccountName of account_1.

    .INPUTS
        None.  Remove-ExchAttributesFromUser does not accept input from the pipeline.

    .OUTPUTS
        None.  This function will output no results.


    .NOTES
        Author: Raymond Jette
        Last Changed: 02/05/2025
        https://github.com/rayjette
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(
            Mandatory,
            HelpMessage = 'Enter the samAccountName'
        )]
        [alias('id', 'user')]
        [string]$samAccountName
    )

    # List of Exchange-related attributes to remove from the user account
    $attributes = @(
        'mail'
        'mailNickName'
        'msExchMailboxGuid'
        'msExchHomeServerName'
        'LegacyExchangeDN'
        'msexchPoliciesIncluded'
        'msexchRecipientDisplayType'
        'msexchRecipientTypeDetails'
        'msexchumdtmfmap'
        'msexchuseraccountcontrol'
        'msexchversion'
        'msExchRemoteRecipientType'
        'proxyAddresses'
    )

    # Check if the script should proceed with making changes
    if ($PSCmdlet.ShouldProcess($samAccountName)) {
        try {
            # Attempt to clear Exchange-related attributes from the specified user account
            Set-AdUser -Identity $samAccountName -Clear $attributes
            Write-Verbose "Exchange attributes removed from user account: $samAccountName"
        } catch {
            Write-Error "Error while removing attributes for user '$samAccountName': $_.Exception.Message"
        }
    }
} # Remove-ExchAttributesFromUser
