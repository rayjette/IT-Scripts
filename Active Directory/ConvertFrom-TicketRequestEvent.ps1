Function ConvertFrom-TicketRequestEvent {
    <#
    .SYNOPSIS
        Converts specific event log data from Ticket Request events (IDs 4768, 4769) into structured output.

    .DESCRIPTION
        This function retrieves event log data related to Ticket Request events (IDs 4768 and 4769) from the Security log.
        It parses the events, extracts relevant information from the XML structure of each event, and then returns
        a custom object with the extracted fields.

    .EXAMPLE
        ConvertFrom-TicketRequestEvent

        This will output a collection of custom objects with relevant fields from the specified event log entries.

    .NOTES
        Author: Raymond Jette
        Created: 3/26/2025
        https://github.com/rayjette
    #>

    # Function to extract a field value from the XML event data.
    function Get-XMLFieldValue {
        param (
            [Parameter(Mandatory)]
            [string]$fieldName, # name of the field to extract from the XML event

            [Parameter(Mandatory)]
            [xml]$xmlEvent # The XML representation of the event
        )
        # Search for the specific field in the XML and return its value
        $field = $xmlEvent.Event.EventData.Data | Where-Object { $_.Name -eq $fieldName }
        $field.'#text'
    }
    
    # Retrieve the specific event log entries for event IDs 4769 and 4768 from the Security log.
    $events = Get-WinEvent -FilterHashtable @{ logname ='Security'; id = 4769, 4768 }

    # Process each event retrieved
    $events | ForEach-Object {
        # Convert the event to XML format for easier processing
        $xmlEvent = [xml]$_.ToXml()

        # Retrieve and process the ClientAdvertizedEncryptionTypes field from the event
        $clientAdvertizedEncryptionTypes = Get-XMLFieldValue -fieldName 'ClientAdvertizedEncryptionTypes' -xmlEvent $xmlEvent
        $clientAdvertizedEncryptionTypes = ($clientAdvertizedEncryptionTypes.trim() -split 'r?\n' | ForEach-Object {$_.Trim()}) -Join ', '

        # Create a custom object with teh parsed event data
        [PSCustomObject]@{
            ComputerEventLoggedOn           = $_.MachineName
            TimeCreated                     = $_.TimeCreated
            Id                              = $_.Id
            TargetUserName                  = Get-XMLFieldValue -fieldName 'TargetUserName' -xmlEvent $xmlEvent
            TargetDomainName                = Get-XMLFieldValue -fieldName 'TargetDomainName' -xmlEvent $xmlEvent
            TargetSid                       = Get-XMLFieldValue -fieldName 'TargetSid' -xmlEvent $xmlEvent
            ServiceName                     = Get-XMLFieldValue -fieldName 'ServiceName' -xmlEvent $xmlEvent
            ServiceSid                      = Get-XMLFieldValue -fieldName 'ServiceSid' -xmlEvent $xmlEvent
            TicketOptions                   = Get-XMLFieldValue -fieldName 'TicketOptions' -xmlEvent $xmlEvent
            Status                          = Get-XMLFieldValue -fieldName 'Status' -xmlEvent $xmlEvent
            TicketEncryptionType            = Get-XMLFieldValue -fieldName 'TicketEncryptionType' -xmlEvent $xmlEvent
            PreAuthType                     = Get-XMLFieldValue -fieldName 'PreAuthType' -xmlEvent $xmlEvent
            IpAddress                       = Get-XMLFieldValue -fieldName 'IpAddress' -xmlEvent $xmlEvent
            IpPort                          = Get-XMLFieldValue -fieldName 'IpPort' -xmlEvent $xmlEvent
            CertIssuerName                  = Get-XMLFieldValue -fieldName 'CertIssuerName' -xmlEvent $xmlEvent
            CertSerialNumber                = Get-XMLFieldValue -fieldName 'CertSerialNumber' -xmlEvent $xmlEvent
            CertThumbprint                  = Get-XMLFieldValue -fieldName 'CertThumbprint' -xmlEvent $xmlEvent
            ResponseTicket                  = Get-XMLFieldValue -fieldName 'ResponseTicket' -xmlEvent $xmlEvent
            AccountSupportedEncryptionTypes = Get-XMLFieldValue -fieldName 'AccountSupportedEncryptionTypes' -xmlEvent $xmlEvent
            AccountAvailableKeys            = Get-XMLFieldValue -fieldName 'AccountAvailableKeys' -xmlEvent $xmlEvent
            ServiceSupportedEncryptionTypes = Get-XMLFieldValue -fieldName 'ServiceSupportedEncryptionTypes' -xmlEvent $xmlEvent
            ServiceAvailableKeys            = Get-XMLFieldValue -fieldName 'ServiceAvailableKeys' -xmlEvent $xmlEvent
            DCSupportedEncryptionTypes      = Get-XMLFieldValue -fieldName 'DCSupportedEncryptionTypes' -xmlEvent $xmlEvent
            DCAvailableKeys                 = Get-XMLFieldValue -fieldName 'DCAvailableKeys' -xmlEvent $xmlEvent
            ClientAdvertizedEncryptionTypes = $clientAdvertizedEncryptionTypes
            SessionKeyEncryptionType        = Get-XMLFieldValue -fieldName 'SessionKeyEncryptionType' -xmlEvent $xmlEvent
            PreAuthEncryptionType           = Get-XMLFieldValue -fieldName 'PreAuthEncryptionType' -xmlEvent $xmlEvent
        }
    }
}