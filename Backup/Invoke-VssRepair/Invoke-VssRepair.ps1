Function Invoke-VssRepair
{
    <#

    .SYNOPSIS

    Locates VSS Writers in a failed state and attempts to fix the
    issue by restarting the service responsible for the writer.

    .DESCRIPTION

    Locates VSS Writers in a failed state and attempts to fix the issue
    by restarting the service responsible for the writer.

    .PARAMETER Force

    Supress conformation before restaring services.

    .EXAMPLE

    Invoke-VssRepair

    .EXAMPLE

    Invoke-VssRepair -Force

    .INPUTS

    None.  Invoke-VssRepair does not accept input from the pipeline.

    .NOTES

    Raymond Jette

    .LINK

    https://github.com/rayjette

    #>

    [CmdletBinding()]
    param
    (
        [switch]$Force
    )

    # A helper function to convert the output from vssadmin list writers into PSCustomObjects.
    Function ConvertFrom-VssWriter
    {
        $vssWriterInfo = Invoke-Command -ScriptBlock {vssadmin.exe list writers}
        $vssWriterInfo = $vssWriterInfo | Select-String 'Writer name:.*' -Context 0, 4
        foreach ($writer in $vssWriterInfo)
        {
            [PSCustomObject]@{
                Name        = $writer.matches.value -replace 'Writer name:\s+' -replace "'"
                Id          = $writer.context.postcontext[0] -replace '\s+Writer Id:\s+'
                InstanceId  = $writer.context.postcontext[1] -replace '\s+Writer Instance Id:\s+'
                State       = $writer.context.postcontext[2] -replace '\s+State:\s+'
                LastError   = $writer.context.postcontext[3] -replace '\s+Last error:\s+'
            }
        }
    } # ConvertFrom-VssWriter


    # Mapping of VSS Writer Name to Service Name
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
        'WINS Jet Writer'                = 'WINS'           # Windows Internet Name Service (WINS)
        'WMI Writer'                     = 'Winmgmt'        # Windows Management Instrumentation
    }

    # These vss writers have failed.
    $failedVssWriters = ConvertFrom-VssWriter | Where-Object {$_.State -notlike "*Stable*"}
    if ($failedVssWriters)
    {
        # For each failed vss writer look up the service to restart and restart it.
        foreach ($writer in $failedVssWriters)
        {
            $writerName = $writer.name
            if ($VssWriterToServiceName.ContainsKey($writerName))
            {
                $service = $VssWriterToServiceName.$writerName
                if ($Force -or $PSCmdlet.ShouldContinue($writer.name, 'Restart vss writer'))
                {
                    Write-Warning -Message "The $($writer.name) is in a failed state.  Restarting the $service service..."
                    Restart-Service -Name $service -Force
                }
            }
            else
            {
                Write-Warning -Message "The $($writer.name) is in a failed state.  Unknown service."
            }
        }
    }
} # Invoke-VssRepair