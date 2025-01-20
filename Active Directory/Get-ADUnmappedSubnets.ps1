#Requires -RunAsAdministrator
#Requires -Modules ActiveDirectory

Function Get-ADUnmappedSubnets {
    <#
    .SYNOPSIS
        Searches for unmapped IP addresses in Active Directory domain controllers.

    .DESCRIPTION
        This function searches for unmapped IP addresses across all domain controllers.
        It reads the netlogon.log file to identify IP addresses that are not mapped to any subnet in Active Directory.

    .PARAMETER DomainController
        Specifies the domain controller(s) to search for unmapped IP addresses.
        Accepts multiple domain controller names as an array.
        If not specified, the script searches all domain controllers in the domain.

    .PARAMETER NetLogonLogLocation
        Specifies the path to the netlogon.log file.
        Defaults to 'c$\windows\debug\netlogon.log'.
        Useful if the default location of the netlogon.log file has changed.

    .EXAMPLE
        Get-ADUnmappedSubnets
        Searches all domain controllers for unmapped IP addresses.

    .EXAMPLE
        Get-ADUnmappedSubnets -DomainController dc00
        Searches dc00 for unmapped IP addresses.

    .Example
        Get-Content DCNames.txt | Get-ADUnmappedSubnets
        Searches all domain controllers listed in DCNames.txt for unmapped IP addresses.

    .Example
        Get-ADUnmappedSubnets -NetLogonLogLocation c:\logs\netlogon.log
        Searches all domaon controllers for unmapped IP addresses.  An alternate log file can be specified.
        Usefull if the default location of the netlogon.log file has changed.

    .INPUTS
        System.String.  The DomainController parameter accepts input from the pipeline.

    .OUTPUTS
        System.Management.Automation.PSCustomObject
    #>
    [OutputType([System.Management.Automation.PSCustomObject])]
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Alias('DC', 'ComputerName', 'HostName')]
        [String[]]$DomainController,

        [Parameter(DontShow)]
        [ValidateNotNullOrEmpty()]
        [system.Io.FileInfo]$NetLogonLogLocation = 'c$\windows\debug\netlogon.log'
    )

    BEGIN {
        Function ConvertFrom-NetLogonLogLine {
            Param (
                [Parameter(ValueFromPipeline)]
                [string]$InputObject
            )
            PROCESS {
                if ($_ -Match '^(\d{2}\/\d{2}) (\d{2}:\d{2}:\d{2}) \[\d+\] (\S+): NO_CLIENT_SITE: (\S+) ((\d{1,3})(\.\d{1,3}){3})$') {
                    [PSCustomObject]@{
                        Date       = $matches[1]
                        Time       = $matches[2]
                        Domain     = $matches[3]
                        Host       = $matches[4]
                        DomainController = $DC
                        IP         = $matches[5]
                    }
                }
            }
        } # ConvertFrom-NetLogonLog


        # Parameters for the Test-Connection cmdlet
        $TestConnectionSplatting = @{
            Count = 1
            Quiet = $true
            InformationAction = 'Ignore'
        }

        # Set $DomainControllers variable to be the name of all domain 
        # controllers if the $DomainController parameter is not specified.
        if (-not $DomainController) {
            $DomainController = (Get-ADDomainController -Filter *).Name
        }
    }

    PROCESS {
        foreach ($DC in $DomainController) {
            Write-Verbose "Checking connectivity to domain controller: $DC"
            if (Test-Connection -ComputerName $DC @TestConnectionSplatting) {
                # Create a UNC path to the log file on the current DC
                $logFileUNCPath = "\\$DC\$NetLogonLogLocation"
                Write-Verbose "Checking if log file exists at: $logFileUNCPath"
                if (Test-Path -Path $logFileUNCPath) {
                    try {
                        Get-Content -Path $logFileUNCPath | foreach-object {
                            $_ | ConvertFrom-NetLogonLogLine
                        }
                    } catch {
                        Write-Error "Error reading log file on DC: $_"
                    }
                } else { 
                    Write-Warning "Log file does not exist on $DC"
                }
            } else {
                Write-Warning "$DC does not appear to be up. This DC will be skipped."
            }
        }
    }
} # Get-ADUnmappedSubnets