Function ConvertFrom-SPNString {
    <#
    .SYNOPSIS
        Converts a Service Principal Name (SPN) string into a structured object.

    .DESCRIPTION
        This cmdlet parses a Service Principal Name (SPN) string into its components:
        ServiceClass, Host, Port, and ServiceName.

    .PARAMETER ServicePrincipalName
        The SPN string(s) to be parsed.

    .EXAMPLE
        ConvertFrom-SPNString -ServicePrincipalName 'HTTP/myhost:8080/myservice'

    .OUTPUTS
        System.Management.Automation.PSCustomObject.

    .NOTES
        Author: Raymond Jette
        https://github.com/rayjette
    #>

    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Alias('SPN')]
        [string[]] $ServicePrincipalName
    )

    BEGIN {
        # Define a regular expression for parsing SPNs
        $pattern = '^(?<ServiceClass>[^\/]+)\/(?<Host>[^\/:]+)(?<Port>:\d+)?(?<ServiceName>.*)?$'
    }

    PROCESS {
        foreach ($name in $ServicePrincipalName) {
            # Check if the SPN matches the expected pattern
            if ($name -match $pattern) {
                try {
                    [PSCustomObject]@{
                        ServiceClass = $matches.ServiceClass
                        Host         = $matches.Host
                        Port         = if ($matches['Port']) { $matches.Port.Substring(1) } else { $null }
                        ServiceName  = if ($matches['ServiceName']) { $matches.ServiceName.Substring(1) } else { $null }
                    }
                } catch {
                    Write-Error -Message "Error processing SPN '$name': $_"
                }
            } else {
                Write-Warning -Message "$name is not a properly formatted SPN and will be skipped."
            }
        }
    }
}