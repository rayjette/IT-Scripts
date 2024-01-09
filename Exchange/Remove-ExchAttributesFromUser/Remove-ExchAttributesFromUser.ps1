Function Remove-ExchAttributesFromUser
{
    <#
    .SYNOPSIS
        Can be run against an Active Directory user account to remove
        any Exchange related attributes.

    .DESCRIPTION
        Can be run against an Active Directory user account to remove
        any Exchange related attributes.

        Removing the Exchange attributes from  an Active Directory user
        account has the effect of deleting the mailbox.

    .PARAMETER samAccountName
        The SAM name for the account.

    .EXAMPLE
        Remove-ExchAttributesFromUser -samAccountName account_1
        Removes the Exchange attributes from the Active Directory user account_1.

    .INPUTS
        None.  Remove-ExchAttributesFromUser does not accept input from the pipeline.

    .OUTPUTS
        None.

    .NOTES
        Author: Raymond Jette
        Version: 1.0
        https://github.com/rayjette
    #>
    [CmdletBinding(
        SupportsShouldProcess, 
        ConfirmImpact = 'High'
    )]
    param (
        [Parameter(
            Mandatory,
            HelpMessage = 'Enter the samAccountName'
        )]
        [alias('id', 'user')]
        [string]$samAccountName
    )
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
    if ($PSCmdlet.ShouldProcess($samAccountName)) {
        try {
            Set-AdUser -Identity $samAccountName -Clear $attributes
        } catch {
            Write-Error -Message $_.Exception.Message
        }
    }
} # Remove-ExchAttributesFromUser
