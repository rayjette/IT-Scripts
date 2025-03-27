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
    
    # Function to decode TicketOptions into readable flags
    function Decode-TicketOptions {
        param (
            [Parameter(Mandatory)]
            [string]$ticketOptionsHex # Hexadecimal representation of TicketOptions
        )
    
        # Convert the hexadecimal value to binary (32-bit representation) using unsigned conversion
        $binaryOptions = [Convert]::ToString([Convert]::ToUInt32($ticketOptionsHex, 16), 2).PadLeft(32, '0')
    
        # Reverse the binary string to align with MSB 0 numbering
        $binaryOptions = ($binaryOptions.ToCharArray() | ForEach-Object { $_ }) -join ''
    
        # Define the mapping of bit positions to flag names (MSB 0 numbering)
        $flags = @{
            0  = 'Reserved'
            1  = 'Forwardable'
            2  = 'Forwarded'
            3  = 'Proxiable'
            4  = 'Proxy'
            5  = 'Allow-postdate'
            6  = 'Postdated'
            7  = 'Invalid'
            8  = 'Renewable'
            9  = 'Initial'
            10 = 'Pre-authent'
            11 = 'Opt-hardware-auth'
            12 = 'Transited-policy-checked'
            13 = 'Ok-as-delegate'
            14 = 'Request-anonymous'
            15 = 'Name-canonicalize'
            27 = 'Renewable-ok'
            30 = 'Renew'
            31 = 'Validate'
        }
    
        # Decode the binary string into readable flags
        $decodedFlags = @()
        foreach ($bit in $flags.Keys) {
            # Check if the bit at position $bit is set (MSB 0 numbering)
            if ($binaryOptions[$bit] -eq '1') {
                $decodedFlags += $flags[$bit]
            }
        }
    
        # Return the decoded flags as a comma-separated string
        $decodedFlags -join ', '
    }

    # Function to decode Status into readable flags
    function Decode-Status {
        param (
            [Parameter(Mandatory)]
            [string]$statusHex # Hexadecimal representation of the Status field
        )
    
        # Define the mapping of status codes to descriptions
        $statusCodes = @{
            "0x0"  = "Success"
            "0x1"  = "Client’s entry in KDC database has expired"
            "0x2"  = "Server’s entry in KDC database has expired"
            "0x3"  = "Requested ticket is not renewable"
            "0x4"  = "Client’s credentials have been revoked"
            "0x5"  = "Client not found in Kerberos database"
            "0x6"  = "Server not found in Kerberos database"
            "0x7"  = "Requested ticket is not forwardable"
            "0x8"  = "TGT has been revoked"
            "0x9"  = "Client not yet valid – try again later"
            "0xA"  = "Server not yet valid – try again later"
            "0xB"  = "Password has expired – change password to reset"
            "0xC"  = "Pre-authentication information was invalid"
            "0xD"  = "Additional pre-authentication required"
            "0xE"  = "KDC policy rejects request"
            "0xF"  = "KDC cannot accommodate requested option"
            "0x10" = "KDC has no support for encryption type"
            "0x11" = "KDC has no support for checksum type"
            "0x12" = "KDC has no support for padata type"
            "0x13" = "More data is needed to complete request"
            "0x14" = "KDC does not support requested protocol version"
            "0x15" = "Client’s credentials have been revoked"
            "0x16" = "Ticket has expired"
            "0x17" = "Ticket not yet valid"
            "0x18" = "Request is a replay"
            "0x19" = "Request is not authentic"
            "0x1A" = "Client’s credentials have been revoked"
            "0x1B" = "Ticket has expired"
            "0x1C" = "Ticket not yet valid"
            "0x1D" = "Request is a replay"
            "0x1E" = "Request is not authentic"
            "0x1F" = "Client’s credentials have been revoked"
            "0x20" = "Ticket has expired"
            "0x21" = "Ticket not yet valid"
            "0x22" = "Request is a replay"
            "0x23" = "Request is not authentic"
            "0x24" = "Client’s credentials have been revoked"
            "0x25" = "Ticket has expired"
            "0x26" = "Ticket not yet valid"
            "0x27" = "Request is a replay"
            "0x28" = "Request is not authentic"
            "0x29" = "Client’s credentials have been revoked"
            "0x2A" = "Ticket has expired"
            "0x2B" = "Ticket not yet valid"
            "0x2C" = "Request is a replay"
            "0x2D" = "Request is not authentic"
            "0x2E" = "Client’s credentials have been revoked"
            "0x2F" = "Ticket has expired"
            "0x30" = "Ticket not yet valid"
            "0x31" = "Request is a replay"
            "0x32" = "Request is not authentic"
            "0x33" = "Client’s credentials have been revoked"
            "0x34" = "Ticket has expired"
            "0x35" = "Ticket not yet valid"
            "0x36" = "Request is a replay"
            "0x37" = "Request is not authentic"
            "0x38" = "Client’s credentials have been revoked"
            "0x39" = "Ticket has expired"
            "0x3A" = "Ticket not yet valid"
            "0x3B" = "Request is a replay"
            "0x3C" = "Request is not authentic"
            "0x3D" = "Client’s credentials have been revoked"
            "0x3E" = "Ticket has expired"
            "0x3F" = "Ticket not yet valid"
            "0x40" = "Request is a replay"
            "0x41" = "Request is not authentic"
            "0x42" = "Client’s credentials have been revoked"
            "0x43" = "Ticket has expired"
            "0x44" = "Ticket not yet valid"
            "0x45" = "Request is a replay"
            "0x46" = "Request is not authentic"
            "0x47" = "Client’s credentials have been revoked"
            "0x48" = "Ticket has expired"
            "0x49" = "Ticket not yet valid"
            "0x4A" = "Request is a replay"
            "0x4B" = "Request is not authentic"
            "0x4C" = "Client’s credentials have been revoked"
            "0x4D" = "Ticket has expired"
            "0x4E" = "Ticket not yet valid"
            "0x4F" = "Request is a replay"
            "0x50" = "Request is not authentic"
            "0x51" = "Client’s credentials have been revoked"
            "0x52" = "Ticket has expired"
            "0x53" = "Ticket not yet valid"
            "0x54" = "Request is a replay"
            "0x55" = "Request is not authentic"
            "0x56" = "Client’s credentials have been revoked"
            "0x57" = "Ticket has expired"
            "0x58" = "Ticket not yet valid"
            "0x59" = "Request is a replay"
            "0x5A" = "Request is not authentic"
        }
    
        # Return the description for the status code, or the original code if not found
        if ($statusCodes.ContainsKey($statusHex)) {
            $statusCodes[$statusHex]
        } else {
            $statusHex
        }
    }

    # Function to decode encryption types (for TicketEncryptionType, SessionKeyEncryptionType, PreAuthEncryptionType)
    function Decode-EncryptionType {
        param (
            [Parameter(Mandatory)]
            [string]$encryptionTypeHex # Hexadecimal representation of the encryption type
        )
        
        # Define the mapping of encryption type values to readable encryption algorithms
        $encryptionTypes = @{
            "0x0"  = "DES-CBC-CRC"
            "0x1"  = "DES-CBC-MD5"
            "0x12" = "AES256"
            "0x13" = "AES128"
            "0x17" = "RC4-HMAC"
            "0x18" = "3DES"
            "0x19" = "RC4-HMAC-NT"
        }
        
        # Return the corresponding encryption type or the original value if not found
        if ($encryptionTypes.ContainsKey($encryptionTypeHex)) {
            $encryptionTypes[$encryptionTypeHex]
        } else {
            $encryptionTypeHex # Return the raw value if not found
        }
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

        # Decode the TicketOptions field
        $ticketOptionsHex = Get-XMLFieldValue -fieldName 'TicketOptions' -xmlEvent $xmlEvent
        $decodedTicketOptions = Decode-TicketOptions -ticketOptionsHex $ticketOptionsHex
        
        # Decode the Status field 
        $statusHex = Get-XMLFieldValue -fieldName 'Status' -xmlEvent $xmlEvent
        $decodedStatus = Decode-Status -StatusHex $statusHex

        # Decode the TicketEncryptionType field
        $ticketEncryptionTypeHex = Get-XMLFieldValue -fieldName 'TicketEncryptionType' -xmlEvent $xmlEvent
        $decodedTicketEncryptionType = Decode-EncryptionType -encryptionTypeHex $ticketEncryptionTypeHex

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
            TicketOptions                   = $decodedTicketOptions
            Status                          = $decodedStatus
            TicketEncryptionType            = $decodedTicketEncryptionType
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