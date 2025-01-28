Function Invoke-VssRepair {
    <#
    .SYNOPSIS
        Attempts to repair failed Volume Shadow Copy Service (VSS) Writers by restarting the associated service.

    .DESCRIPTION
        This function checks for VSS Writers in a failed state (i.e., not marked as "stable") and attempts to fix the issue by restarting the service responsible for each writer. 

    .PARAMETER Force
        If specified, suppresses the confirmation prompt when restarting services.

    .EXAMPLE
        Invoke-VssRepair
        This will check for failed VSS writers and attempt to restart the corresponding services, asking for confirmation before proceeding.

    .EXAMPLE
        Invoke-VssRepair -Force
        This will check for failed VSS writers and restart the corresponding services without asking for confirmation.

    .INPUTS
        None.  Invoke-VssRepair does not accept input from the pipeline.

    .NOTES
        Raymond Jette
        https://github.com/rayjette
    #>

    [CmdletBinding()]
    param
    (
        # Bypass confirmation prompt if specified
        [switch]$Force
    )

    # A helper function to parse VSS Writer information from the output of `vssadmin list writers`
    Function ConvertFrom-VssWriter {
        $vssWriterInfo = Invoke-Command -ScriptBlock {vssadmin.exe list writers}
        $vssWriterInfo = $vssWriterInfo | Select-String 'Writer name:.*' -Context 0, 4

        # Parse the output and convert it into a list of PSCustomObjects
        foreach ($writer in $vssWriterInfo) {
            [PSCustomObject]@{
                Name        = $writer.matches.value -replace 'Writer name:\s+' -replace "'"
                Id          = $writer.context.postcontext[0] -replace '\s+Writer Id:\s+'
                InstanceId  = $writer.context.postcontext[1] -replace '\s+Writer Instance Id:\s+'
                State       = $writer.context.postcontext[2] -replace '\s+State:\s+'
                LastError   = $writer.context.postcontext[3] -replace '\s+Last error:\s+'
            }
        }
    } # ConvertFrom-VssWriter


    # A hashtable mapping VSS Writer names to the corresponding service names
    $VssWriterToServiceName = @{
        'ASR Writer'                     = 'VSS'            # Volume Shadow Copy
        'BITS Writer'                    = 'BITS'           # Background Intelligent Transfer Service
        'COM+ REGDB Writer'              = 'VSS'            # Volume Shadow Copy
        'DFS Replication service writer' = 'DFSR'           # DFS Replication
        'DHCP Jet Writer'                = 'DHCPServer'     # DHCP Server
        'FRS Writer'                     = 'NtFrs'          # File Replication
        'FSRM writer'                    = 'srmsvc'         # File Server Resource Manager
        'IIS Config Writer'              = 'AppHostSvc'     # Application Host Helper Service
        'IIS Metabase Writer'            = 'IISADMIN'       # IIS Admin Service
        'Microsoft Exchange Writer'      = 'MSExchangeIS'   # Microsoft Exchange Information Store
        'Microsoft Hyper-V VSS Writer'   = 'vmms'           # Hyper-V Virtual Machine Management
        'MSSearch Service Writer'        = 'wsearch'        # Windows Search
        'NTDS'                           = 'NTDS'           # Active Directory Domain Services
        'OSearch VSS Writer'             = 'OSearch'        # Office SharePoint Server Search
        'OSearch14 VSS Writer'           = 'OSearch14'      # SharePoint Server Search 14
        'Registry Writer'                = 'VSS'            # Volume Shadow Copy
        'Shadow Copy'                    = 'VSS'            # Volume Shadow Copy
        'SPSearch VSS Writer'            = 'SPSearch'       # Windows SharePoint Service Search
        'SPSearch4 VSS Writer'           = 'SPSearch4'      # SharePoint Foundation Search V4
        'SqlServerWriter'                = 'SQLWriter'      # SQL Server VSS Writer
        'System Writer'                  = 'CryptSvc'       # Cryptographic Services
        'TermServLicensing'              = 'TermServLicensing'  # Remote Desktop Licensing
        'VMware VSS Writer'              = 'vmware-vss'     # VMware VSS Writer
        'WINS Jet Writer'                = 'WINS'           # Windows Internet Name Service (WINS)
        'WMI Writer'                     = 'Winmgmt'        # Windows Management Instrumentation
    }

    # Retrieve all failed VSS Writers that are not in a "Stable" state
    $failedVssWriters = ConvertFrom-VssWriter | Where-Object {$_.State -notlike "*Stable*"}

    if ($failedVssWriters) {
        # If there are failed writers, attempt to restart their corresponding service
        foreach ($writer in $failedVssWriters) {
            $writerName = $writer.name
            $service = $VssWriterToServiceName.$writerName

            if ($service) {
                # If Force is set or the user confirms, restart the service
                if ($Force -or $PSCmdlet.ShouldContinue($writer.name, 'Restart vss writer')) {
                    Write-Warning -Message "The $($writer.name) is in a failed state.  Restarting the $service service..."
                    Restart-Service -Name $service -Force
                }
            } else {
                Write-Warning -Message "The VSS Writer '$($writer.name)' is in a failed state, but no corresponding service was found."
            }
        }
    }
} # Invoke-VssRepair